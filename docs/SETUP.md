# Complete Setup Guide

## Prerequisites Checklist

- [ ] AWS account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform >= 1.5 installed
- [ ] kubectl >= 1.28 installed
- [ ] Docker installed
- [ ] SSH key pair generated
- [ ] GitHub account
- [ ] Docker Hub account

## Step-by-Step Setup (60 minutes)

### Phase 1: Infrastructure (15 min)

```bash
# Clone repository
git clone https://github.com/muhammadasim11512/devops-task1.git
cd devops-task1

# Generate SSH key if needed
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# Save outputs
export MASTER_IP=$(terraform output -raw master_public_ip)
export WORKER_IP=$(terraform output -raw worker_private_ip)

echo "Master: $MASTER_IP"
echo "Worker: $WORKER_IP"
```

### Phase 2: Kubernetes Cluster (20 min)

```bash
# Wait for instances to initialize (5 min)
sleep 300

# Copy setup script to master
scp -i ~/.ssh/id_rsa docs/setup-cluster.sh ubuntu@$MASTER_IP:~/

# SSH to master
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP

# Run setup script
chmod +x setup-cluster.sh
./setup-cluster.sh $(hostname -I | awk '{print $1}')

# Copy join command
JOIN_CMD=$(sudo kubeadm token create --print-join-command)

# SSH to worker
ssh ubuntu@$WORKER_IP

# Join cluster
sudo $JOIN_CMD

# Exit back to master
exit

# Verify nodes
kubectl get nodes

# Exit master
exit

# Copy kubeconfig to local
scp -i ~/.ssh/id_rsa ubuntu@$MASTER_IP:~/.kube/config ~/.kube/config
```

### Phase 3: Application (15 min)

```bash
# Build images
docker build -t asimkhankhitran/devops-backend:latest backend/
docker build -t asimkhankhitran/devops-frontend:latest frontend/

# Login to Docker Hub
docker login -u asimkhankhitran

# Push images
docker push asimkhankhitran/devops-backend:latest
docker push asimkhankhitran/devops-frontend:latest

# Create secret
kubectl create secret generic app-secret \
  --from-literal=SECRET_KEY=$(openssl rand -hex 32) \
  -n devops-app --dry-run=client -o yaml | kubectl apply -f -

# Deploy application
kubectl apply -f k8s/base/

# Wait for pods
kubectl wait --for=condition=ready pod -l app=backend -n devops-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n devops-app --timeout=300s
```

### Phase 4: Verification (10 min)

```bash
# Get NodePort
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

echo "Application URL: http://$MASTER_IP:$NODEPORT"

# Test health
curl http://$MASTER_IP:$NODEPORT/health

# Register user
curl -X POST http://$MASTER_IP:$NODEPORT/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","email":"admin@example.com","password":"admin123"}'

# Login
TOKEN=$(curl -s -X POST http://$MASTER_IP:$NODEPORT/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | jq -r '.access_token')

# Get profile
curl http://$MASTER_IP:$NODEPORT/api/profile \
  -H "Authorization: Bearer $TOKEN"

# Open in browser
echo "Open: http://$MASTER_IP:$NODEPORT"
```

### Phase 5: CI/CD (Optional)

```bash
# Get kubeconfig base64
cat ~/.kube/config | base64 -w 0

# Add GitHub Secrets:
# 1. Go to GitHub repo settings
# 2. Secrets and variables > Actions
# 3. Add secrets:
#    - DOCKER_TOKEN: Your Docker Hub token
#    - KUBECONFIG: Base64 kubeconfig from above

# Push code
git add .
git commit -m "Initial deployment"
git push origin main

# Monitor pipeline
# Go to GitHub Actions tab
```

### Phase 6: Monitoring (Optional)

```bash
# Install Prometheus/Grafana
./docs/setup-monitoring.sh

# Port forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Open http://localhost:3000
# Username: admin
# Password: (from script output)
```

## Verification Checklist

- [ ] Both nodes show Ready: `kubectl get nodes`
- [ ] All pods running: `kubectl get pods -n devops-app`
- [ ] Health endpoint works: `curl http://$MASTER_IP:$NODEPORT/health`
- [ ] Can register user via API
- [ ] Can login via API
- [ ] Frontend loads in browser
- [ ] Can login via UI
- [ ] Dashboard shows profile

## Troubleshooting

### Nodes not ready
```bash
kubectl describe node <NODE>
journalctl -u kubelet -f
```

### Pods not starting
```bash
kubectl describe pod <POD> -n devops-app
kubectl logs <POD> -n devops-app
```

### Can't access application
```bash
# Check ingress
kubectl get svc -n ingress-nginx

# Check security group
# Ensure NodePort is open in AWS console
```

### HPA not working
```bash
# Check metrics server
kubectl top nodes
kubectl top pods -n devops-app

# If not working
kubectl logs -n kube-system deployment/metrics-server
```

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete namespace devops-app
kubectl delete namespace monitoring

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

## Next Steps

1. Configure custom domain
2. Add TLS certificates
3. Set up monitoring alerts
4. Configure log aggregation
5. Implement backup strategy
6. Add more tests
7. Configure ArgoCD for GitOps

## Support

- GitHub Issues: https://github.com/muhammadasim11512/devops-task1/issues
- Documentation: See docs/ folder
