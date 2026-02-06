# Security Documentation

## Shift-Left Security

Security integrated at every stage of development lifecycle.

## Code Security

### Static Analysis
- SonarQube scans for code quality and vulnerabilities
- Automated in CI/CD pipeline
- Blocks deployment on critical issues

### Dependency Scanning
- Trivy scans filesystem for vulnerable dependencies
- Checks Python packages and OS packages

## Image Security

### Container Scanning
- Trivy scans Docker images before push
- Detects CVEs in base images and dependencies
- Fails pipeline on HIGH/CRITICAL vulnerabilities

### Image Hardening
- Multi-stage builds (smaller attack surface)
- Alpine/Distroless base images
- Non-root user (UID 1001)
- No unnecessary packages

## Runtime Security

### Kubernetes SecurityContext
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
    - ALL
```

### Network Policies
- Default deny all traffic
- Explicit allow rules only
- Namespace isolation

### RBAC
- ServiceAccount per application
- Role with minimal permissions
- RoleBinding for authorization

## Application Security

### Authentication
- JWT tokens (30 min expiry)
- Bcrypt password hashing (cost factor 12)
- Token validation on every request

### Secrets Management
- Kubernetes Secrets (not in Git)
- Environment variables only
- Rotate regularly

### API Security
- Rate limiting (100 req/s)
- CORS configuration
- Input validation (Pydantic)

## Network Security

### AWS Security Groups
- Master: SSH (22), K8s API (6443), HTTP/HTTPS (80/443)
- Worker: Only VPC traffic
- Egress: All (can be restricted)

### Ingress Security
- TLS termination
- Rate limiting
- DDoS protection (AWS Shield)

## Compliance

### Best Practices
- CIS Kubernetes Benchmark
- OWASP Top 10
- AWS Well-Architected Framework

## Incident Response

1. Detect: Monitoring alerts
2. Contain: NetworkPolicy, pod deletion
3. Investigate: Logs, metrics
4. Remediate: Patch, redeploy
5. Review: Post-mortem

## Security Checklist

- [x] Code scanning (SonarQube)
- [x] Dependency scanning (Trivy)
- [x] Image scanning (Trivy)
- [x] Non-root containers
- [x] Read-only filesystem
- [x] Dropped capabilities
- [x] NetworkPolicy
- [x] RBAC
- [x] Secrets management
- [x] TLS at ingress
- [x] Rate limiting
- [ ] WAF (future)
- [ ] Secrets encryption at rest (future)
