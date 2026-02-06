# 🚀 Quick Deployment Guide

## ✅ Tests Passed Locally
```
4 passed in 1.37s
✅ test_health_check
✅ test_register_user  
✅ test_login_invalid
✅ test_profile_without_auth
```

## 📋 Prerequisites

1. **GitHub Secrets Required:**
   - `DOCKER_TOKEN` - Docker Hub access token
   - `KUBECONFIG` - Kubernetes cluster config (optional for deployment)

2. **Local Requirements:**
   - AWS CLI configured
   - Terraform >= 1.5
   - kubectl >= 1.28
   - Docker installed

## 🎯 Quick Start

### 1. Deploy Infrastructure (15 min)
```bash
cd terraform
terraform init
terraform apply -auto-approve
export MASTER_IP=$(terraform output -raw master_public_ip)
```

### 2. Setup Kubernetes (20 min)
```bash
ssh ubuntu@$MASTER_IP
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml
```

### 3. Push to GitHub
```bash
git push origin main
```

Pipeline will automatically:
- ✅ Run tests
- ✅ Build Docker images
- ✅ Deploy to Kubernetes (if KUBECONFIG set)

## 🌐 Access Application

```bash
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')
echo "Application: http://$MASTER_IP:$NODEPORT"
```

## 📊 Pipeline Status

- **Test**: Runs on every push/PR
- **Build**: Runs on push (requires DOCKER_TOKEN)
- **Deploy**: Runs on main branch (requires KUBECONFIG)

## 🔧 Troubleshooting

**Tests fail?**
```bash
cd backend && pytest ../tests/ -v
```

**Docker build fails?**
- Check DOCKER_TOKEN secret is set
- Verify Docker Hub credentials

**Deployment fails?**
- Check KUBECONFIG secret is valid
- Verify cluster is accessible

## 💰 Cost: ~$55/month
- 2x t3.micro EC2 instances
- NAT Gateway
- EBS volumes
- Elastic IPs
