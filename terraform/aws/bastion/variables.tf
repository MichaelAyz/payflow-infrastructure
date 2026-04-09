variable "hub_vpc_id" {
  description = "The ID of the Hub VPC"
  type        = string
}

variable "hub_public_subnet_id" {
  description = "The ID of the Hub public subnet"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "payflow-eks-cluster"
}
