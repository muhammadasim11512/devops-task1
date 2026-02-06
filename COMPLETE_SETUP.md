# 🚀 COMPLETE 100% WORKING SETUP GUIDE

## ✅ Prerequisites Checklist
- [ ] AWS CLI configured (`aws configure`)
- [ ] Terraform installed (`terraform --version`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] SSH key exists (`~/.ssh/id_rsa.pub`)
- [ ] Docker Hub account
- [ ] GitHub account

---

## 📋 STEP-BY-STEP DEPLOYMENT

### 1️⃣ Deploy Infrastructure (10 minutes)

```bash
cd terraform

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy infrastructure
terraform apply -auto-approve

# Save outputs
export MASTER_IP=$(terraform output -raw master_public_ip)
export MASTER_PRIVATE_IP=$(terraform output -raw master_private_ip)
export WORKER_PRIVATE_IP=$(terraform output -raw worker_private_ip)

echo "Master Public IP: $MASTER_IP"
echo "Master Private IP: $MASTER_PRIVATE_IP"
echo "Worker Private IP: $WORKER_PRIVATE_IP"
```

**Wait 3-5 minutes for EC2 instances to initialize.**

---

### 2️⃣ Setup Master Node (15 minutes)

```bash
# SSH to master
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP

# Verify initialization completed
sudo systemctl status containerd
sudo systemctl status kubelet

# Initialize Kubernetes cluster
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify
kubectl get nodes
# Should show: master NotReady

# Install Calico CNI
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Wait for Calico (2-3 minutes)
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

# Verify node is Ready
kubectl get nodes
# Should show: master Ready

# Generate join command for worker
kubeadm token create --print-join-command > /tmp/join-command.txt
cat /tmp/join-command.txt
```

**Copy the join command - you'll need it for worker node!**

---

### 3️⃣ Setup Worker Node (5 minutes)

```bash
# From master, SSH to worker (using private IP)
ssh ubuntu@<WORKER_PRIVATE_IP>

# Verify initialization
sudo systemctl status containerd
sudo systemctl status kubelet

# Run the join command from step 2
sudo kubeadm join <MASTER_PRIVATE_IP>:6443 --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>

# Exit back to master
exit
```

**Back on master node:**

```bash
# Verify worker joined
kubectl get nodes
# Should show: master Ready, worker Ready

# Check all system pods
kubectl get pods -A
# All pods should be Running
```

---

### 4️⃣ Install Additional Components (5 minutes)

```bash
# Still on master node

# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Wait for ingress
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s

# Install Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch for insecure TLS
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Wait for metrics server
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s

# Verify all components
kubectl get pods -A
kubectl top nodes
```

---

### 5️⃣ Deploy Application (5 minutes)

**Exit from master, return to local machine:**

```bash
exit

# Clone/navigate to project
cd /home/muhammad/devops-task1

# Copy kubeconfig from master
scp -i ~/.ssh/id_rsa ubuntu@$MASTER_IP:~/.kube/config ~/.kube/config-devops

# Set KUBECONFIG
export KUBECONFIG=~/.kube/config-devops

# Verify connection
kubectl get nodes

# Deploy application
kubectl apply -f k8s/base/

# Wait for deployments
kubectl wait --for=condition=ready pod -l app=backend -n devops-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n devops-app --timeout=300s

# Check status
kubectl get all -n devops-app
```

---

### 6️⃣ Access Application

```bash
# Get NodePort
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

echo "🎉 Application URL: http://$MASTER_IP:$NODEPORT"
echo "🎉 Health Check: http://$MASTER_IP:$NODEPORT/health"
echo "🎉 API: http://$MASTER_IP:$NODEPORT/api"
```

**Open in browser and test:**
- Register user
- Login
- View dashboard
- Update profile

---

### 7️⃣ Setup CI/CD (5 minutes)

**Add GitHub Secrets:**

1. Go to: `https://github.com/YOUR_USERNAME/devops-task1/settings/secrets/actions`

2. Add `DOCKER_TOKEN`:
   - Login to Docker Hub
   - Go to Account Settings → Security → New Access Token
   - Copy token and add as secret

3. Add `KUBECONFIG`:
   ```bash
   cat ~/.kube/config-devops | base64 -w 0
   ```
   - Copy output and add as secret

**Push to trigger pipeline:**

```bash
git push origin main
```

---

## 🔍 VERIFICATION CHECKLIST

### Infrastructure
```bash
# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s-*" --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,PrivateIpAddress]' --output table

# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=devops-task-vpc" --output table
```

### Kubernetes
```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl top nodes
kubectl top pods -n devops-app
```

### Application
```bash
# Health check
curl http://$MASTER_IP:$NODEPORT/health

# Register user
curl -X POST http://$MASTER_IP:$NODEPORT/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"test123"}'

# Login
curl -X POST http://$MASTER_IP:$NODEPORT/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123"}'
```

### Networking
```bash
# Test pod-to-pod communication
kubectl exec -it -n devops-app deployment/backend -- wget -O- http://redis:6379

# Test DNS
kubectl exec -it -n devops-app deployment/backend -- nslookup redis.devops-app.svc.cluster.local

# Check ingress
kubectl describe ingress -n devops-app
```

---

## 🐛 TROUBLESHOOTING

### Nodes Not Ready
```bash
kubectl describe node <NODE_NAME>
kubectl logs -n kube-system -l k8s-app=calico-node
```

### Pods Not Starting
```bash
kubectl describe pod <POD_NAME> -n devops-app
kubectl logs <POD_NAME> -n devops-app
```

### Worker Can't Join
```bash
# On worker node
sudo journalctl -u kubelet -f

# Check connectivity from worker to master
ping <MASTER_PRIVATE_IP>
telnet <MASTER_PRIVATE_IP> 6443
```

### Ingress Not Working
```bash
kubectl get svc -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

---

## 🧹 CLEANUP

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/base/

# Destroy infrastructure
cd terraform
terraform destroy -auto-approve
```

---

## 📊 COST ESTIMATE

**Monthly Cost: ~$55**
- 2x t3.micro EC2: $15.18
- NAT Gateway: $32.85
- EBS volumes: $3.20
- Elastic IPs: $3.65

**To reduce costs:**
- Use Spot instances (70% savings)
- Stop instances when not in use
- Use single NAT Gateway

---

## ✅ SUCCESS CRITERIA

- [ ] Both nodes show "Ready"
- [ ] All pods in "Running" state
- [ ] Application accessible via browser
- [ ] Health endpoint returns 200
- [ ] User registration works
- [ ] Login works
- [ ] CI/CD pipeline passes
- [ ] Metrics server working
- [ ] HPA scaling works

---

## 🎯 NEXT STEPS

1. **Monitoring**: Install Prometheus/Grafana
   ```bash
   bash docs/setup-monitoring.sh
   ```

2. **TLS**: Add Let's Encrypt certificates

3. **Backup**: Setup etcd backups

4. **Scaling**: Test HPA with load

5. **GitOps**: Setup ArgoCD

---

**🎉 Congratulations! Your enterprise DevOps platform is ready!**
