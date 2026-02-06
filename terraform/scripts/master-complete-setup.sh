#!/bin/bash
set -e

exec > >(tee /var/log/master-setup.log)
exec 2>&1

echo "=========================================="
echo "Master Node Complete Setup - Starting"
echo "=========================================="

# Update system
echo "[1/10] Updating system..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl gpg jq wget netcat-openbsd git

# Install containerd
echo "[2/10] Installing containerd..."
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Install Kubernetes
echo "[3/10] Installing Kubernetes components..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Configure kernel
echo "[4/10] Configuring kernel modules..."
modprobe br_netfilter
modprobe overlay
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Disable swap
echo "[5/10] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Initialize Kubernetes
echo "[6/10] Initializing Kubernetes cluster..."
PRIVATE_IP=$(hostname -I | awk '{print $1}')
kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$PRIVATE_IP

# Configure kubectl for ubuntu user
echo "[7/10] Configuring kubectl..."
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Configure kubectl for root
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# Install Calico CNI
echo "[8/10] Installing Calico CNI..."
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Wait for Calico
echo "Waiting for Calico pods..."
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s || true

# Install NGINX Ingress
echo "[9/10] Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/baremetal/deploy.yaml

# Wait for Ingress
echo "Waiting for Ingress Controller..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s || true

# Install Metrics Server
echo "[10/10] Installing Metrics Server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Generate join command
echo "Generating worker join command..."
kubeadm token create --print-join-command > /home/ubuntu/join-command.txt
chown ubuntu:ubuntu /home/ubuntu/join-command.txt

# Create completion marker
echo "Master node setup completed at $(date)" > /var/log/k8s-master-ready

echo "=========================================="
echo "Master Node Setup Complete!"
echo "=========================================="
echo "Join command saved to: /home/ubuntu/join-command.txt"
echo "Cluster info:"
kubectl get nodes
kubectl get pods -A
