variable "spoke_vpc_id" {
  description = "The ID of the Spoke VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs in the Spoke VPC"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "The ID of the EKS node security group"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "dev"
}

variable "db_password" {
  description = "Password for the RDS postgres database"
  type        = string
  sensitive   = true
}

variable "mq_password" {
  description = "Password for the Amazon MQ broker"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT Secret for application auth"
  type        = string
  sensitive   = true
}
