output "master_public_ip" {
  description = "Public IP of Kubernetes master (t3.small: 2 vCPU, 2GB RAM)"
  value       = aws_eip.master.public_ip
}

output "master_private_ip" {
  description = "Private IP of Kubernetes master"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_private_ip" {
  description = "Private IP of Kubernetes worker (t3.medium: 2 vCPU, 4GB RAM)"
  value       = aws_instance.k8s_worker.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "master_instance_type" {
  description = "Master node instance type"
  value       = var.master_instance_type
}

output "worker_instance_type" {
  description = "Worker node instance type"
  value       = var.worker_instance_type
}
