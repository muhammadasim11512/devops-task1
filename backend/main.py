from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from passlib.context import CryptContext
import jwt
import redis
import os
import logging
from datetime import datetime, timedelta
from typing import Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DevOps Task API")

app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

try:
    redis_client = redis.Redis(
        host=os.getenv("REDIS_HOST", "redis"),
        port=int(os.getenv("REDIS_PORT", 6379)),
        db=0,
        decode_responses=True,
        socket_connect_timeout=5,
        socket_timeout=5,
        retry_on_timeout=True,
        health_check_interval=30
    )
    redis_client.ping()
    logger.info(f"Redis connected successfully at {os.getenv('REDIS_HOST', 'redis')}:{os.getenv('REDIS_PORT', 6379)}")
except Exception as e:
    logger.error(f"Redis connection failed: {e}")
    redis_client = None

class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserProfile(BaseModel):
    username: str
    email: str
    full_name: Optional[str] = None
    bio: Optional[str] = None

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return username
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

@app.get("/health")
async def health_check():
    try:
        redis_status = "connected" if redis_client and redis_client.ping() else "disconnected"
    except:
        redis_status = "disconnected"
    return {"status": "healthy", "redis": redis_status, "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/register", status_code=status.HTTP_201_CREATED)
async def register(user: UserRegister):
    try:
        if redis_client and redis_client.exists(f"user:{user.username}"):
            raise HTTPException(status_code=400, detail="Username already exists")
        hashed_pwd = hash_password(user.password)
        user_data = {"username": user.username, "email": user.email, "password": hashed_pwd}
        if redis_client:
            redis_client.hset(f"user:{user.username}", mapping=user_data)
        logger.info(f"User registered: {user.username}")
        return {"message": "User registered successfully", "username": user.username}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Registration error: {e}")
        raise HTTPException(status_code=500, detail="Registration failed")

@app.post("/api/login")
async def login(user: UserLogin):
    try:
        if not redis_client or not redis_client.exists(f"user:{user.username}"):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        user_data = redis_client.hgetall(f"user:{user.username}")
        if not verify_password(user.password, user_data["password"]):
            raise HTTPException(status_code=401, detail="Invalid credentials")
        token = create_access_token({"sub": user.username})
        if redis_client:
            redis_client.setex(f"session:{user.username}", 1800, token)
        logger.info(f"User logged in: {user.username}")
        return {"access_token": token, "token_type": "bearer"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {e}")
        raise HTTPException(status_code=500, detail="Login failed")

@app.get("/api/profile")
async def get_profile(username: str = Depends(verify_token)):
    try:
        if not redis_client or not redis_client.exists(f"user:{username}"):
            raise HTTPException(status_code=404, detail="User not found")
        user_data = redis_client.hgetall(f"user:{username}")
        return {"username": user_data["username"], "email": user_data["email"], "full_name": user_data.get("full_name", ""), "bio": user_data.get("bio", "")}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get profile error: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch profile")

@app.put("/api/profile")
async def update_profile(profile: UserProfile, username: str = Depends(verify_token)):
    try:
        if profile.username != username:
            raise HTTPException(status_code=403, detail="Cannot update other user's profile")
        if not redis_client or not redis_client.exists(f"user:{username}"):
            raise HTTPException(status_code=404, detail="User not found")
        update_data = {"email": profile.email, "full_name": profile.full_name or "", "bio": profile.bio or ""}
        redis_client.hset(f"user:{username}", mapping=update_data)
        logger.info(f"Profile updated: {username}")
        return {"message": "Profile updated successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Update profile error: {e}")
        raise HTTPException(status_code=500, detail="Failed to update profile")

@app.delete("/api/profile")
async def delete_profile(username: str = Depends(verify_token)):
    try:
        if redis_client:
            redis_client.delete(f"user:{username}")
            redis_client.delete(f"session:{username}")
        logger.info(f"Profile deleted: {username}")
        return {"message": "Profile deleted successfully"}
    except Exception as e:
        logger.error(f"Delete profile error: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete profile")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
