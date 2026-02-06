# 🖥️ EC2 Instance Specifications

## Master Node (Control Plane)
- **Instance Type:** t3.small
- **vCPU:** 2
- **RAM:** 2 GB
- **Storage:** 20 GB gp3
- **Network:** Public subnet with Elastic IP
- **Role:** Kubernetes control plane (API server, etcd, scheduler, controller-manager)

## Worker Node (Application Workloads)
- **Instance Type:** t3.medium
- **vCPU:** 2
- **RAM:** 4 GB
- **Storage:** 20 GB gp3
- **Network:** Private subnet (NAT Gateway for internet)
- **Role:** Run application pods (frontend, backend, redis)

## Cost Breakdown (Updated)

| Resource | Type | Quantity | Rate | Monthly Cost |
|----------|------|----------|------|--------------|
| Master Node | t3.small | 1 | $0.0208/hr | $15.18 |
| Worker Node | t3.medium | 1 | $0.0416/hr | $30.37 |
| EBS Master | gp3 20GB | 1 | $0.08/GB | $1.60 |
| EBS Worker | gp3 20GB | 1 | $0.08/GB | $1.60 |
| NAT Gateway | - | 1 | $0.045/hr | $32.85 |
| Elastic IP (Master) | - | 1 | $0.005/hr | $3.65 |
| Elastic IP (NAT) | - | 1 | $0.005/hr | $3.65 |
| **TOTAL** | | | | **$88.90/month** |

## Why This Configuration?

### Master Node (2 vCPU, 2GB RAM)
- Kubernetes control plane components need moderate resources
- etcd database requires stable CPU
- API server handles cluster requests
- Scheduler and controller-manager are lightweight
- **2GB RAM is sufficient** for small-medium clusters

### Worker Node (2 vCPU, 4GB RAM)
- Runs application workloads (pods)
- More RAM needed for:
  - Backend application (FastAPI + Python)
  - Frontend (Nginx)
  - Redis (in-memory cache)
  - Multiple replicas (2 backend + 2 frontend + 1 redis)
- **4GB RAM allows better pod density**

## Resource Allocation

### Master Node Usage:
```
Control Plane Pods:
- kube-apiserver: ~200MB
- etcd: ~100MB
- kube-scheduler: ~50MB
- kube-controller-manager: ~100MB
- Calico components: ~200MB
- Ingress controller: ~200MB
Total: ~850MB (leaves 1.1GB for system)
```

### Worker Node Usage:
```
Application Pods:
- Backend (2 replicas): 256MB × 2 = 512MB
- Frontend (2 replicas): 128MB × 2 = 256MB
- Redis: 128MB
- System overhead: ~500MB
Total: ~1.4GB (leaves 2.6GB for scaling)
```

## Deployment Commands

```bash
# Deploy infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# Check instance types
terraform output master_instance_type
terraform output worker_instance_type

# Verify resources
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=k8s-*" \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],InstanceType,State.Name,PublicIpAddress,PrivateIpAddress]' \
  --output table
```

## Scaling Options

### Vertical Scaling (More Resources)
```hcl
# In terraform/variables.tf
master_instance_type = "t3.medium"  # 2 vCPU, 4GB RAM
worker_instance_type = "t3.large"   # 2 vCPU, 8GB RAM
```

### Horizontal Scaling (More Nodes)
Add more worker nodes in `terraform/main.tf`:
```hcl
resource "aws_instance" "k8s_worker_2" {
  # Same config as k8s_worker
}
```

## Cost Optimization Tips

1. **Use Spot Instances** (70% savings):
   ```hcl
   instance_market_options {
     market_type = "spot"
   }
   ```

2. **Reserved Instances** (40% savings):
   - 1-year commitment
   - Predictable workloads

3. **Auto-stop during off-hours**:
   ```bash
   aws ec2 stop-instances --instance-ids <INSTANCE_ID>
   ```

4. **Right-sizing**:
   - Monitor actual usage
   - Adjust instance types based on metrics

## Verification

After deployment, verify resources:

```bash
# SSH to master
ssh ubuntu@<MASTER_IP>

# Check CPU and RAM
nproc  # Should show 2
free -h  # Should show ~2GB

# Exit and SSH to worker (from master)
ssh ubuntu@<WORKER_PRIVATE_IP>

# Check CPU and RAM
nproc  # Should show 2
free -h  # Should show ~4GB
```
