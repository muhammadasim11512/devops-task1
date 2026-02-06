#!/bin/bash
set -e

echo "🔍 Network Connectivity Verification"
echo "======================================"
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &>/dev/null; then
    echo "❌ kubectl not configured. Run: export KUBECONFIG=~/.kube/config-devops"
    exit 1
fi

echo "✅ kubectl configured"
echo ""

# Check nodes
echo "📊 Checking Nodes..."
kubectl get nodes -o wide
echo ""

# Check all pods
echo "📦 Checking All Pods..."
kubectl get pods -A -o wide
echo ""

# Check devops-app namespace
echo "🚀 Checking Application Pods..."
kubectl get pods -n devops-app -o wide
echo ""

# Check services
echo "🌐 Checking Services..."
kubectl get svc -n devops-app
echo ""

# Check ingress
echo "🔀 Checking Ingress..."
kubectl get ingress -n devops-app
echo ""

# Test DNS resolution
echo "🔍 Testing DNS Resolution..."
echo "Testing backend DNS..."
kubectl exec -n devops-app deployment/frontend -- nslookup backend.devops-app.svc.cluster.local || echo "⚠️  DNS test failed"

echo "Testing redis DNS..."
kubectl exec -n devops-app deployment/backend -- nslookup redis.devops-app.svc.cluster.local || echo "⚠️  DNS test failed"
echo ""

# Test pod-to-pod connectivity
echo "🔗 Testing Pod-to-Pod Connectivity..."

echo "1. Frontend → Backend (port 8000)..."
kubectl exec -n devops-app deployment/frontend -- wget -q -O- --timeout=5 http://backend:8000/health && echo "✅ Frontend can reach Backend" || echo "❌ Frontend cannot reach Backend"

echo "2. Backend → Redis (port 6379)..."
kubectl exec -n devops-app deployment/backend -- nc -zv redis 6379 && echo "✅ Backend can reach Redis" || echo "❌ Backend cannot reach Redis"
echo ""

# Test ingress connectivity
echo "🌍 Testing Ingress Connectivity..."
MASTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
if [ -z "$MASTER_IP" ]; then
    MASTER_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi

NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

echo "Testing: http://$MASTER_IP:$NODEPORT/health"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://$MASTER_IP:$NODEPORT/health || echo "❌ Ingress not accessible"
echo ""

# Check NetworkPolicies
echo "🛡️  Checking NetworkPolicies..."
kubectl get networkpolicy -n devops-app
echo ""

# Test application endpoints
echo "🧪 Testing Application Endpoints..."

echo "1. Health endpoint..."
curl -s http://$MASTER_IP:$NODEPORT/health | jq . || echo "❌ Health check failed"

echo ""
echo "2. Register user..."
REGISTER_RESPONSE=$(curl -s -X POST http://$MASTER_IP:$NODEPORT/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"test123"}')
echo "$REGISTER_RESPONSE" | jq . || echo "$REGISTER_RESPONSE"

echo ""
echo "3. Login user..."
LOGIN_RESPONSE=$(curl -s -X POST http://$MASTER_IP:$NODEPORT/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}')
echo "$LOGIN_RESPONSE" | jq . || echo "$LOGIN_RESPONSE"

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token' 2>/dev/null)

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
    echo ""
    echo "4. Get profile (authenticated)..."
    curl -s http://$MASTER_IP:$NODEPORT/api/profile \
      -H "Authorization: Bearer $TOKEN" | jq . || echo "❌ Profile fetch failed"
fi

echo ""
echo "======================================"
echo "📊 Network Connectivity Summary"
echo "======================================"
echo ""

# Summary
BACKEND_PODS=$(kubectl get pods -n devops-app -l app=backend --no-headers | wc -l)
FRONTEND_PODS=$(kubectl get pods -n devops-app -l app=frontend --no-headers | wc -l)
REDIS_PODS=$(kubectl get pods -n devops-app -l app=redis --no-headers | wc -l)

echo "✅ Backend Pods: $BACKEND_PODS/2"
echo "✅ Frontend Pods: $FRONTEND_PODS/2"
echo "✅ Redis Pods: $REDIS_PODS/1"
echo ""
echo "🌐 Application URL: http://$MASTER_IP:$NODEPORT"
echo "🔍 Health Check: http://$MASTER_IP:$NODEPORT/health"
echo "📡 API Endpoint: http://$MASTER_IP:$NODEPORT/api"
echo ""

# Network flow diagram
cat << 'EOF'
📊 Network Flow:
================

Internet → Elastic IP (Master) → NGINX Ingress (NodePort)
                                        ↓
                    ┌───────────────────┴───────────────────┐
                    │                                       │
                    ▼                                       ▼
            Frontend Service                        Backend Service
            (ClusterIP: 80)                        (ClusterIP: 8000)
                    │                                       │
                    ▼                                       ▼
            Frontend Pods (2)                       Backend Pods (2)
            (Port: 8080)                           (Port: 8000)
                    │                                       │
                    └───────────────────┬───────────────────┘
                                        ▼
                                  Redis Service
                                 (ClusterIP: 6379)
                                        │
                                        ▼
                                   Redis Pod (1)
                                   (Port: 6379)

Network Policies:
- Frontend → Backend: ✅ Allowed
- Backend → Redis: ✅ Allowed
- Frontend → Redis: ❌ Blocked (security)
- External → Ingress: ✅ Allowed
- All → DNS: ✅ Allowed

Overlay Network: Calico (192.168.0.0/16)
Pod Network: Automatic IPAM by Calico
Service Network: ClusterIP (internal)
EOF

echo ""
echo "======================================"
