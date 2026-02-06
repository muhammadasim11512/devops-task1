#!/bin/bash
set -e

echo "🚀 Complete Infrastructure Deployment Script"
echo "=============================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not installed"; exit 1; }

# Check AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured"; exit 1; }

# Check SSH key
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "❌ SSH key not found at ~/.ssh/id_rsa.pub"
    echo "Generate with: ssh-keygen -t rsa -b 4096"
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Deploy Terraform infrastructure
echo "🏗️  Step 1: Deploying AWS Infrastructure..."
cd terraform

terraform init
terraform apply -auto-approve

# Get outputs
MASTER_IP=$(terraform output -raw master_public_ip)
MASTER_PRIVATE_IP=$(terraform output -raw master_private_ip)
WORKER_PRIVATE_IP=$(terraform output -raw worker_private_ip)

echo ""
echo "✅ Infrastructure deployed successfully!"
echo "   Master Public IP: $MASTER_IP"
echo "   Master Private IP: $MASTER_PRIVATE_IP"
echo "   Worker Private IP: $WORKER_PRIVATE_IP"
echo ""

# Wait for instances to be ready
echo "⏳ Waiting for EC2 instances to initialize (3 minutes)..."
sleep 180

# Setup Master Node
echo ""
echo "🎯 Step 2: Setting up Master Node..."
echo "   Connecting to $MASTER_IP..."

ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$MASTER_IP << 'MASTER_SETUP'
set -e

echo "Waiting for user-data script to complete..."
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    sleep 5
done

echo "Initializing Kubernetes cluster..."
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

echo "Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

echo "Waiting for Calico to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

echo "Waiting for Ingress Controller..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s

echo "Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "Generating join command..."
kubeadm token create --print-join-command > /tmp/join-command.txt

echo "✅ Master node setup complete!"
MASTER_SETUP

echo "✅ Master node configured successfully!"
echo ""

# Get join command
echo "📝 Getting worker join command..."
JOIN_CMD=$(ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP "cat /tmp/join-command.txt")

# Setup Worker Node
echo ""
echo "🎯 Step 3: Setting up Worker Node..."
echo "   Connecting via master to $WORKER_PRIVATE_IP..."

ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP << WORKER_SETUP
set -e

echo "Connecting to worker node..."
ssh -o StrictHostKeyChecking=no ubuntu@$WORKER_PRIVATE_IP << 'WORKER_INNER'
set -e

echo "Waiting for user-data script to complete..."
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    sleep 5
done

echo "Joining cluster..."
sudo $JOIN_CMD

echo "✅ Worker node joined successfully!"
WORKER_INNER
WORKER_SETUP

echo "✅ Worker node configured successfully!"
echo ""

# Verify cluster
echo "🔍 Step 4: Verifying cluster..."
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP << 'VERIFY'
echo "Checking nodes..."
kubectl get nodes

echo ""
echo "Checking system pods..."
kubectl get pods -A

echo ""
echo "Checking node resources..."
kubectl top nodes 2>/dev/null || echo "Metrics not ready yet"
VERIFY

echo ""
echo "✅ Cluster verification complete!"
echo ""

# Deploy application
echo "🚀 Step 5: Deploying application..."

# Copy kubeconfig
scp -i ~/.ssh/id_rsa ubuntu@$MASTER_IP:~/.kube/config ~/.kube/config-devops
export KUBECONFIG=~/.kube/config-devops

# Deploy
cd ..
kubectl apply -f k8s/base/

echo "⏳ Waiting for application pods..."
kubectl wait --for=condition=ready pod -l app=backend -n devops-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n devops-app --timeout=300s

echo ""
echo "✅ Application deployed successfully!"
echo ""

# Get access info
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

echo "=============================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=============================================="
echo ""
echo "📊 Cluster Information:"
echo "   Master Node: t3.small (2 vCPU, 2GB RAM)"
echo "   Worker Node: t3.medium (2 vCPU, 4GB RAM)"
echo ""
echo "🌐 Access URLs:"
echo "   Application: http://$MASTER_IP:$NODEPORT"
echo "   Health Check: http://$MASTER_IP:$NODEPORT/health"
echo "   API: http://$MASTER_IP:$NODEPORT/api"
echo ""
echo "🔑 SSH Access:"
echo "   Master: ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP"
echo "   Worker: ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP (then ssh ubuntu@$WORKER_PRIVATE_IP)"
echo ""
echo "📝 Kubeconfig:"
echo "   export KUBECONFIG=~/.kube/config-devops"
echo ""
echo "🧪 Test Application:"
echo "   curl http://$MASTER_IP:$NODEPORT/health"
echo ""
echo "💰 Monthly Cost: ~\$88.90"
echo ""
echo "=============================================="
