#!/bin/bash
set -e

echo "🚀 100% Automated Infrastructure Deployment"
echo "=============================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not installed"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not installed"; exit 1; }
aws sts get-caller-identity >/dev/null 2>&1 || { echo "❌ AWS credentials not configured"; exit 1; }
[ -f ~/.ssh/id_rsa.pub ] || { echo "❌ SSH key not found"; exit 1; }

echo "✅ All prerequisites met"
echo ""

# Deploy infrastructure
echo "🏗️  Deploying AWS Infrastructure..."
cd terraform
terraform init
terraform apply -auto-approve

MASTER_IP=$(terraform output -raw master_public_ip)
MASTER_PRIVATE_IP=$(terraform output -raw master_private_ip)
WORKER_PRIVATE_IP=$(terraform output -raw worker_private_ip)

echo ""
echo "✅ Infrastructure deployed!"
echo "   Master: $MASTER_IP (t3.small - 2 vCPU, 2GB RAM)"
echo "   Worker: $WORKER_PRIVATE_IP (t3.medium - 2 vCPU, 4GB RAM)"
echo ""

# Wait for setup to complete
echo "⏳ Waiting for automated setup to complete (10 minutes)..."
echo "   Master node is installing: containerd, kubeadm, kubectl, Calico, Ingress, Metrics Server"
echo "   Worker node is installing: containerd, kubeadm, kubectl"
sleep 600

# Check master status
echo ""
echo "🔍 Checking master node status..."
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$MASTER_IP << 'CHECK_MASTER'
if [ -f /var/log/k8s-master-ready ]; then
    echo "✅ Master node ready!"
    kubectl get nodes
    kubectl get pods -A | grep -E "Running|NAME"
else
    echo "⚠️  Master still setting up, checking logs..."
    tail -20 /var/log/master-setup.log
fi
CHECK_MASTER

# Join worker
echo ""
echo "🔗 Joining worker node to cluster..."
JOIN_CMD=$(ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP "cat /home/ubuntu/join-command.txt")

ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP << WORKER_JOIN
ssh -o StrictHostKeyChecking=no ubuntu@$WORKER_PRIVATE_IP << 'WORKER_INNER'
if [ -f /var/log/k8s-worker-ready ]; then
    echo "Worker node ready, joining cluster..."
    sudo $JOIN_CMD
    echo "✅ Worker joined successfully!"
else
    echo "⚠️  Worker still setting up..."
    tail -10 /var/log/worker-setup.log
fi
WORKER_INNER
WORKER_JOIN

# Wait for worker to join
sleep 30

# Verify cluster
echo ""
echo "🔍 Verifying cluster..."
ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP << 'VERIFY'
kubectl get nodes
echo ""
kubectl get pods -A
VERIFY

# Copy kubeconfig
echo ""
echo "📥 Copying kubeconfig..."
scp -i ~/.ssh/id_rsa ubuntu@$MASTER_IP:~/.kube/config ~/.kube/config-devops
export KUBECONFIG=~/.kube/config-devops

# Deploy application
echo ""
echo "🚀 Deploying application..."
cd ..
kubectl apply -f k8s/base/

echo "⏳ Waiting for application..."
kubectl wait --for=condition=ready pod -l app=backend -n devops-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=frontend -n devops-app --timeout=300s

NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "=============================================="
echo "🎉 DEPLOYMENT COMPLETE - 100% AUTOMATED!"
echo "=============================================="
echo ""
echo "🌐 Access Application:"
echo "   URL: http://$MASTER_IP:$NODEPORT"
echo "   Health: http://$MASTER_IP:$NODEPORT/health"
echo "   API: http://$MASTER_IP:$NODEPORT/api"
echo ""
echo "🔑 SSH Access:"
echo "   ssh -i ~/.ssh/id_rsa ubuntu@$MASTER_IP"
echo ""
echo "📊 Cluster Status:"
kubectl get nodes
echo ""
kubectl get pods -n devops-app
echo ""
echo "💰 Monthly Cost: ~\$88.90"
echo "=============================================="
