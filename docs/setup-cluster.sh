#!/bin/bash
set -e

echo "=== Kubernetes Cluster Setup ==="

MASTER_IP=$1

if [ -z "$MASTER_IP" ]; then
  echo "Usage: $0 <MASTER_IP>"
  exit 1
fi

echo "Master IP: $MASTER_IP"

echo "Step 1: Initialize cluster..."
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --apiserver-advertise-address=$MASTER_IP

echo "Step 2: Configure kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Step 3: Install Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

echo "Step 4: Wait for Calico..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s

echo "Step 5: Install NGINX Ingress..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

echo "Step 6: Wait for Ingress..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s

echo "Step 7: Install Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "Step 8: Generate join command..."
echo ""
echo "=== JOIN COMMAND FOR WORKER ==="
sudo kubeadm token create --print-join-command
echo ""

echo "Cluster setup complete!"
echo "Run 'kubectl get nodes' to verify"
