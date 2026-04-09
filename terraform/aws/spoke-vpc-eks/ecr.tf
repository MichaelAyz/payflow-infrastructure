locals {
  microservices = [
    "auth",
    "wallet",
    "transaction",
    "notification",
    "frontend",
    "api-gateway"
  ]
}

resource "aws_ecr_repository" "microservices" {
  for_each             = toset(local.microservices)
  name                 = "payflow/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
