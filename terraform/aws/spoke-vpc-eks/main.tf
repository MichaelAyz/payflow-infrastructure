provider "aws" {
  region = var.aws_region
}

locals {
  private_subnets = {
    "a" = "10.1.1.0/24"
    "b" = "10.1.2.0/24"
    "c" = "10.1.3.0/24"
  }
  public_subnets = {
    "a" = "10.1.101.0/24"
    "b" = "10.1.102.0/24"
  }
  endpoints = {
    "ecr_api"              = "com.amazonaws.${var.aws_region}.ecr.api"
    "ecr_dkr"              = "com.amazonaws.${var.aws_region}.ecr.dkr"
    "sts"                  = "com.amazonaws.${var.aws_region}.sts"
    "secretsmanager"       = "com.amazonaws.${var.aws_region}.secretsmanager"
    "ec2"                  = "com.amazonaws.${var.aws_region}.ec2"
    "elasticloadbalancing" = "com.amazonaws.${var.aws_region}.elasticloadbalancing"
  }
}

# Spoke VPC
resource "aws_vpc" "spoke" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "payflow-spoke-vpc-${var.environment}"
  }
}

resource "aws_subnet" "private" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.spoke.id
  cidr_block        = each.value
  availability_zone = "${var.aws_region}${each.key}"

  tags = {
    Name                                        = "payflow-spoke-private-1${each.key}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/payflow-eks-cluster" = "shared"
  }
}

resource "aws_subnet" "public" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.spoke.id
  cidr_block              = each.value
  availability_zone       = "${var.aws_region}${each.key}"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "payflow-spoke-public-1${each.key}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/payflow-eks-cluster" = "shared"
  }
}

resource "aws_internet_gateway" "spoke" {
  vpc_id = aws_vpc.spoke.id

  tags = {
    Name = "payflow-spoke-igw-${var.environment}"
  }
}

# ONE shared NAT Gateway for dev
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "payflow-spoke-nat-eip-${var.environment}"
  }
}

resource "aws_nat_gateway" "spoke" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["a"].id

  tags = {
    Name = "payflow-spoke-nat-${var.environment}"
  }
  depends_on = [aws_internet_gateway.spoke]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.spoke.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.spoke.id
  }

  route {
    cidr_block         = "10.0.0.0/16"
    transit_gateway_id = var.transit_gateway_id
  }

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke] 

  tags = {
    Name = "payflow-spoke-public-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.spoke.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.spoke.id
  }

  route {
    cidr_block         = "10.0.0.0/16"
    transit_gateway_id = var.transit_gateway_id
  }

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.spoke]   

  tags = {
    Name = "payflow-spoke-private-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Transit Gateway Attachment using ec2 prefix as required
resource "aws_ec2_transit_gateway_vpc_attachment" "spoke" {
  subnet_ids         = [for s in aws_subnet.private : s.id]
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.spoke.id

  tags = {
    Name = "payflow-spoke-tgw-attachment"
  }
}

# VPC Endpoints Security Group
resource "aws_security_group" "vpc_endpoints" {
  name        = "payflow-spoke-vpce-sg-${var.environment}"
  description = "Security group for VPC endpoints allowing HTTPS from Spoke VPC"
  vpc_id      = aws_vpc.spoke.id

  ingress {
    description = "Allow HTTPS from Spoke VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.spoke.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "payflow-spoke-vpce-sg-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "interfaces" {
  for_each            = local.endpoints
  vpc_id              = aws_vpc.spoke.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "payflow-spoke-vpce-${each.key}-${var.environment}"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.spoke.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id, aws_route_table.public.id]

  tags = {
    Name = "payflow-spoke-vpce-s3-${var.environment}"
  }
}
