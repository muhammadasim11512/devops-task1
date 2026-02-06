output "master_public_ip" {
  description = "Public IP of Kubernetes master"
  value       = aws_eip.master.public_ip
}

output "master_private_ip" {
  description = "Private IP of Kubernetes master"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_private_ip" {
  description = "Private IP of Kubernetes worker"
  value       = aws_instance.k8s_worker.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}
