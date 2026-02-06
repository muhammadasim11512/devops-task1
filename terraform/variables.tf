variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "master_instance_type" {
  description = "EC2 instance type for master node"
  type        = string
  default     = "t3.small"  # 2 vCPU, 2GB RAM
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker node"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB RAM
}

variable "public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
