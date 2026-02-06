#!/bin/bash
set -e

exec > >(tee /var/log/worker-setup.log)
exec 2>&1

echo "=========================================="
echo "Worker Node Complete Setup - Starting"
echo "=========================================="

# Update system
echo "[1/6] Updating system..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl gpg jq wget netcat-openbsd

# Install containerd
echo "[2/6] Installing containerd..."
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Install Kubernetes
echo "[3/6] Installing Kubernetes components..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Configure kernel
echo "[4/6] Configuring kernel modules..."
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
echo "[5/6] Disabling swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Create ready marker
echo "[6/6] Worker node ready for joining..."
echo "Worker node setup completed at $(date)" > /var/log/k8s-worker-ready

echo "=========================================="
echo "Worker Node Setup Complete!"
echo "=========================================="
echo "Ready to join cluster. Waiting for join command from master..."
