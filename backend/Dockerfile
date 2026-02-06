FROM python:3.11-alpine AS builder
WORKDIR /app
RUN apk add --no-cache gcc musl-dev libffi-dev
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

FROM python:3.11-alpine
WORKDIR /app
RUN addgroup -g 1001 appuser && adduser -D -u 1001 -G appuser appuser
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser main.py .
USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:8000/health || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
