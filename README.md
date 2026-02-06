# 🚀 Enterprise DevOps Platform - Three-Tier Cloud Application

> A complete production-ready Kubernetes deployment on AWS featuring CI/CD automation, enterprise security, and comprehensive monitoring.

![Project Status](https://img.shields.io/badge/status-production--ready-brightgreen)
![Kubernetes](https://img.shields.io/badge/kubernetes-1.28-blue)
![AWS](https://img.shields.io/badge/AWS-EC2-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Application Demo](#application-demo)
- [Security](#security)
- [Monitoring](#monitoring)
- [Cost Analysis](#cost-analysis)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

---

## 🎯 Overview

This project demonstrates a **complete enterprise-grade DevOps implementation** featuring:

- **Cloud Infrastructure**: Fully automated AWS infrastructure provisioning using Terraform
- **Container Orchestration**: Production Kubernetes cluster with kubeadm (no managed services)
- **Modern Application**: Three-tier web application with authentication and session management
- **Security First**: Comprehensive security scanning, RBAC, network policies, and secrets management
- **CI/CD Pipeline**: Automated testing, building, scanning, and deployment
- **Observability**: Full monitoring stack with Prometheus and Grafana

**Perfect for**: DevOps engineers, Cloud architects, and teams looking to implement production-grade Kubernetes on AWS.

---

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │   Elastic IP (Static) │
              │   Master Node Entry   │
              └──────────┬───────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────┐            ┌─────────────────┐
│  NGINX Ingress  │            │  Kubernetes API │
│   Controller    │            │     Server      │
└────────┬────────┘            └─────────────────┘
         │
         ├──────────────┬──────────────┐
         │              │              │
         ▼              ▼              ▼
    ┌────────┐    ┌────────┐    ┌────────┐
    │Frontend│    │Backend │    │ Redis  │
    │  Pods  │───▶│  Pods  │───▶│  Pod   │
    │(nginx) │    │(FastAPI)│    │(Cache) │
    └────────┘    └────────┘    └────────┘
```

### AWS Infrastructure

```
┌──────────────────────────────────────────────────────────────┐
│                    AWS VPC (10.0.0.0/16)                      │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Public Subnet (10.0.1.0/24)                    │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Kubernetes Master Node (t3.micro)              │  │  │
│  │  │  • Control Plane Components                      │  │  │
│  │  │  • etcd Database                                 │  │  │
│  │  │  • API Server                                    │  │  │
│  │  │  • Scheduler & Controller Manager                │  │  │
│  │  │  • Elastic IP: XX.XX.XX.XX                       │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Internet Gateway                                │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  NAT Gateway (Elastic IP)                        │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         Private Subnet (10.0.2.0/24)                   │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Kubernetes Worker Node (t3.micro)              │  │  │
│  │  │  • Application Pods                              │  │  │
│  │  │  • Frontend (2 replicas)                         │  │  │
│  │  │  • Backend (2 replicas)                          │  │  │
│  │  │  • Redis (1 replica)                             │  │  │
│  │  │  • Internet via NAT Gateway                      │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Network Flow

```
User Request Flow:
─────────────────

1. User → https://XX.XX.XX.XX (Elastic IP)
2. Elastic IP → Master Node (Public Subnet)
3. NGINX Ingress Controller → Routes based on path
   • / → Frontend Service
   • /api → Backend Service
4. Service → Pod (via ClusterIP)
5. Backend Pod → Redis Pod (Session/Cache)
6. Response ← Back to User

Pod-to-Pod Communication:
─────────────────────────

Frontend Pod (10.244.1.5)
    ↓ (Calico Overlay Network)
Backend Pod (10.244.1.6)
    ↓ (Calico Overlay Network)
Redis Pod (10.244.1.7)
```

---

## ✨ Features

### 🔧 Infrastructure as Code
- **Terraform**: Complete AWS infrastructure automation
- **VPC Setup**: Public/Private subnets with proper routing
- **Security Groups**: Least privilege access control
- **Elastic IP**: Static IP for master node accessibility
- **NAT Gateway**: Secure internet access for private subnet

### ☸️ Kubernetes Features
- **kubeadm Cluster**: Self-managed Kubernetes (no EKS)
- **Calico CNI**: Advanced networking and network policies
- **NGINX Ingress**: HTTP/HTTPS routing and load balancing
- **Metrics Server**: Resource metrics for autoscaling
- **HPA**: Horizontal Pod Autoscaler for dynamic scaling
- **PDB**: Pod Disruption Budgets for high availability
- **RBAC**: Role-based access control
- **Network Policies**: Pod-to-pod security

### 🛡️ Security
- **JWT Authentication**: Secure token-based auth
- **Bcrypt Hashing**: Password encryption
- **Trivy Scanning**: Container and filesystem vulnerability scanning
- **SonarQube**: Static code analysis
- **Non-root Containers**: Security best practices
- **Read-only Filesystem**: Immutable containers
- **Secrets Management**: Kubernetes secrets (not in Git)
- **TLS Ready**: HTTPS support at ingress

### 🔄 CI/CD Pipeline
- **GitHub Actions**: Automated workflows
- **Automated Testing**: Pytest unit tests
- **Security Scanning**: Pre-deployment checks
- **Docker Build**: Multi-stage optimized builds
- **Auto Deployment**: Push to production
- **Rollback Support**: Safe deployments

### 📊 Monitoring & Observability
- **Prometheus**: Metrics collection
- **Grafana**: Visualization dashboards
- **Health Checks**: Liveness and readiness probes
- **Logging**: Structured application logs

---

## 🛠️ Technology Stack

### Infrastructure
- **Cloud Provider**: AWS (EC2, VPC, EBS, EIP, NAT)
- **IaC Tool**: Terraform 1.5+
- **Container Runtime**: containerd

### Kubernetes
- **Version**: 1.28
- **Installation**: kubeadm
- **CNI**: Calico 3.26
- **Ingress**: NGINX Ingress Controller
- **Package Manager**: Helm 3

### Application
- **Backend**: Python 3.11, FastAPI, JWT, Bcrypt
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Database**: Redis 7 (Session store)
- **Web Server**: Nginx (Alpine)

### DevOps Tools
- **CI/CD**: GitHub Actions
- **Security**: Trivy, SonarQube
- **Testing**: Pytest, Postman
- **Monitoring**: Prometheus, Grafana
- **Containerization**: Docker (Multi-stage builds)

---

## 📦 Prerequisites

Before you begin, ensure you have:

- ✅ **AWS Account** with admin access
- ✅ **AWS CLI** configured with credentials
- ✅ **Terraform** >= 1.5 installed
- ✅ **kubectl** >= 1.28 installed
- ✅ **Docker** installed and running
- ✅ **SSH Key Pair** generated (`~/.ssh/id_rsa`)
- ✅ **GitHub Account** (for CI/CD)
- ✅ **Docker Hub Account** (for image registry)

### Installation Commands

```bash
# Install Terraform (Linux)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS
aws configure
```

---

## 🚀 Quick Start

### 1️⃣ Clone Repository

```bash
git clone https://github.com/muhammadasim11512/devops-task1.git
cd devops-task1
```

### 2️⃣ Deploy Infrastructure (15 minutes)

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# Save master IP
export MASTER_IP=$(terraform output -raw master_public_ip)
echo "Master IP: $MASTER_IP"
```

### 3️⃣ Setup Kubernetes Cluster (20 minutes)

```bash
# SSH to master node
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP

# Initialize cluster
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Wait for Calico
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

# Get join command for worker
kubeadm token create --print-join-command
```

### 4️⃣ Join Worker Node

```bash
# From master, SSH to worker
ssh ubuntu@<WORKER_PRIVATE_IP>

# Run join command (from previous step)
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>

# Verify from master
kubectl get nodes
```

### 5️⃣ Install Additional Components

```bash
# Install NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

### 6️⃣ Build & Push Docker Images

```bash
# Exit from master, return to local machine
exit

# Build images
docker build -t YOUR_DOCKERHUB_USERNAME/devops-backend:latest backend/
docker build -t YOUR_DOCKERHUB_USERNAME/devops-frontend:latest frontend/

# Login to Docker Hub
docker login

# Push images
docker push YOUR_DOCKERHUB_USERNAME/devops-backend:latest
docker push YOUR_DOCKERHUB_USERNAME/devops-frontend:latest
```

### 7️⃣ Deploy Application

```bash
# Update image names in k8s manifests
sed -i 's/asimkhankhitran/YOUR_DOCKERHUB_USERNAME/g' k8s/base/*.yaml

# Deploy
kubectl apply -f k8s/base/

# Wait for pods
kubectl wait --for=condition=ready pod -l app=backend -n devops-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n devops-app --timeout=300s

# Check status
kubectl get all -n devops-app
```

### 8️⃣ Access Application

```bash
# Get Ingress NodePort
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

echo "🎉 Application URL: http://$MASTER_IP:$NODEPORT"
```

---

## 📱 Application Demo

### User Registration

1. Open browser: `http://<MASTER_IP>:<NODEPORT>`
2. Click "Register"
3. Enter username, email, password
4. Submit form

### User Login

1. Enter registered credentials
2. Click "Login"
3. Redirected to Dashboard

### Profile Management

1. View profile information
2. Update email, full name, bio
3. Save changes
4. Logout

### API Testing

```bash
# Health Check
curl http://$MASTER_IP:$NODEPORT/health

# Register User
curl -X POST http://$MASTER_IP:$NODEPORT/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'

# Login
TOKEN=$(curl -s -X POST http://$MASTER_IP:$NODEPORT/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}' | jq -r '.access_token')

# Get Profile
curl http://$MASTER_IP:$NODEPORT/api/profile \
  -H "Authorization: Bearer $TOKEN"

# Update Profile
curl -X PUT http://$MASTER_IP:$NODEPORT/api/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"username":"testuser","email":"newemail@example.com","full_name":"Test User","bio":"DevOps Engineer"}'
```

---

## 🔒 Security

### Security Layers

1. **Infrastructure Security**
   - VPC isolation
   - Security groups with least privilege
   - Private subnet for workers
   - NAT Gateway for controlled egress

2. **Container Security**
   - Non-root user (UID 1001)
   - Read-only root filesystem
   - Dropped Linux capabilities
   - Multi-stage builds (minimal attack surface)
   - Alpine/Distroless base images

3. **Kubernetes Security**
   - RBAC with ServiceAccounts
   - NetworkPolicy (deny-all default)
   - Pod Security Context
   - Secrets management
   - Resource limits

4. **Application Security**
   - JWT token authentication
   - Bcrypt password hashing (cost 12)
   - Input validation (Pydantic)
   - CORS configuration
   - Rate limiting (100 req/s)

5. **CI/CD Security**
   - Trivy filesystem scanning
   - Trivy image scanning
   - SonarQube code analysis
   - Automated security gates

### Security Scanning

```bash
# Scan Docker images
trivy image YOUR_DOCKERHUB_USERNAME/devops-backend:latest
trivy image YOUR_DOCKERHUB_USERNAME/devops-frontend:latest

# Scan filesystem
trivy fs .

# Run tests
pytest tests/ -v
```

---

## 📊 Monitoring

### Install Prometheus & Grafana

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s
```

### Access Grafana

```bash
# Get Grafana password
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo

# Port forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: (from above command)
```

### Key Metrics

- **Pod CPU Usage**: Real-time CPU consumption
- **Pod Memory Usage**: Memory utilization
- **Pod Restarts**: Application stability
- **HTTP Request Rate**: Traffic patterns
- **HTTP Response Time**: Application performance
- **Error Rate**: Application health

---

## 💰 Cost Analysis

### Monthly Cost Breakdown

| Resource | Type | Quantity | Rate | Monthly Cost |
|----------|------|----------|------|--------------|
| EC2 Master | t3.micro | 1 | $0.0104/hr | $7.59 |
| EC2 Worker | t3.micro | 1 | $0.0104/hr | $7.59 |
| EBS Master | gp3 20GB | 1 | $0.08/GB | $1.60 |
| EBS Worker | gp3 20GB | 1 | $0.08/GB | $1.60 |
| NAT Gateway | - | 1 | $0.045/hr | $32.85 |
| NAT Data Transfer | 1GB | - | $0.045/GB | $0.05 |
| Elastic IP (Master) | - | 1 | $0.005/hr | $3.65 |
| **TOTAL** | | | | **$54.93/month** |

### Cost Optimization Tips

1. **Use Spot Instances**: Save 70% on worker nodes
2. **Reserved Instances**: Save 40% with 1-year commitment
3. **Auto-scaling**: Scale down during off-hours
4. **Single NAT**: Share NAT Gateway across AZs
5. **gp3 Volumes**: 20% cheaper than gp2

### Cost Comparison

- **Self-managed (Current)**: $54.93/month
- **AWS EKS**: $88/month (Control plane $73 + nodes $15)
- **Savings**: 38% cheaper than EKS

---

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n devops-app

# Describe pod
kubectl describe pod <POD_NAME> -n devops-app

# Check logs
kubectl logs <POD_NAME> -n devops-app

# Check events
kubectl get events -n devops-app --sort-by='.lastTimestamp'
```

### Network Issues

```bash
# Test pod connectivity
kubectl exec -it <BACKEND_POD> -n devops-app -- wget -O- http://redis:6379

# Check NetworkPolicy
kubectl get networkpolicy -n devops-app

# Check DNS
kubectl exec -it <POD> -n devops-app -- nslookup backend.devops-app.svc.cluster.local
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Check service
kubectl get svc -n ingress-nginx

# Verify ingress
kubectl describe ingress -n devops-app
```

### HPA Not Scaling

```bash
# Check HPA status
kubectl get hpa -n devops-app

# Check metrics
kubectl top pods -n devops-app
kubectl top nodes

# Check metrics server
kubectl logs -n kube-system deployment/metrics-server
```

---

## 📚 Additional Documentation

- **[Complete Setup Guide](docs/SETUP.md)**: Step-by-step deployment instructions
- **[Architecture Deep Dive](docs/ARCHITECTURE.md)**: Detailed system design
- **[Security Guide](docs/SECURITY.md)**: Security implementation details
- **[Cost Analysis](docs/COST.md)**: Detailed cost breakdown and optimization

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Kubernetes community for excellent documentation
- AWS for reliable cloud infrastructure
- FastAPI for modern Python web framework
- Calico for advanced networking
- All open-source contributors

---

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review troubleshooting guide

---

**Made with ❤️ by DevOps Engineers, for DevOps Engineers**

⭐ Star this repo if you find it helpful!
