# Cost Analysis

## Monthly Cost Breakdown

### Compute
| Resource | Type | Hours/Month | Rate | Cost |
|----------|------|-------------|------|------|
| Master EC2 | t3.micro | 730 | $0.0104/hr | $7.59 |
| Worker EC2 | t3.micro | 730 | $0.0104/hr | $7.59 |

### Storage
| Resource | Type | Size | Rate | Cost |
|----------|------|------|------|------|
| Master EBS | gp3 | 20GB | $0.08/GB | $1.60 |
| Worker EBS | gp3 | 20GB | $0.08/GB | $1.60 |

### Networking
| Resource | Type | Rate | Cost |
|----------|------|------|------|
| NAT Gateway | - | $0.045/hr | $32.85 |
| NAT Data | 1GB | $0.045/GB | $0.05 |
| Elastic IP | 1 | $0.005/hr | $3.65 |

### Total Monthly Cost
**$54.93/month** (~$1.83/day)

## Cost Optimization Strategies

### Implemented
1. **t3.micro instances**: Burstable, cost-effective
2. **gp3 volumes**: 20% cheaper than gp2
3. **Single NAT Gateway**: Shared across AZs
4. **Alpine images**: Faster pulls, less bandwidth

### Future Optimizations
1. **Spot Instances**: 70% savings for worker nodes
2. **Reserved Instances**: 40% savings for 1-year commitment
3. **Savings Plans**: Flexible commitment-based discounts
4. **Auto-shutdown**: Stop instances during off-hours
5. **Multi-AZ NAT**: Remove NAT, use public IPs (less secure)

## Cost Comparison

### Current Setup
- **Monthly**: $54.93
- **Yearly**: $659.16

### With Spot Instances
- **Monthly**: $32.00 (42% savings)
- **Yearly**: $384.00

### With Reserved Instances (1-year)
- **Monthly**: $38.00 (31% savings)
- **Yearly**: $456.00

### Managed Kubernetes (EKS)
- **Control Plane**: $73/month
- **Worker Nodes**: $15/month (2x t3.micro)
- **Total**: $88/month (60% more expensive)

## Cost Monitoring

### AWS Cost Explorer
- Enable cost allocation tags
- Set up budget alerts
- Review monthly reports

### Recommendations
1. Set budget alert at $60/month
2. Review costs weekly
3. Tag all resources
4. Use AWS Cost Anomaly Detection

## Break-Even Analysis

Self-managed Kubernetes is cheaper than EKS when:
- Running < 3 clusters
- Need full control
- Have Kubernetes expertise

EKS is better when:
- Running multiple clusters
- Need managed upgrades
- Limited DevOps resources
