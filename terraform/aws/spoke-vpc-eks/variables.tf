variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "transit_gateway_id" {
  description = "TGW ID from hub-vpc module output"
  type        = string
}
