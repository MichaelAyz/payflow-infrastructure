provider "aws" {
  region = var.aws_region
}

# Hub VPC
resource "aws_vpc" "hub" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "payflow-hub-vpc-${var.environment}"
  }
}

# Public Subnet (for bastion)
resource "aws_subnet" "hub_public" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "payflow-hub-public-1a"
  }
}

# Private Subnet (for future use / TGW attachment)
resource "aws_subnet" "hub_private" {
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "payflow-hub-private-1a"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "payflow-hub-igw-${var.environment}"
  }
}

# Public Route Table
resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub.id
  }

  tags = {
    Name = "payflow-hub-public-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "hub_public" {
  subnet_id      = aws_subnet.hub_public.id
  route_table_id = aws_route_table.hub_public.id
}

# Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {
  description                     = "payflow-tgw"
  auto_accept_shared_attachments  = "enable"

  tags = {
    Name = "payflow-tgw"
  }
}

# Transit Gateway VPC Attachment (using Hub PRIVATE subnet)
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  subnet_ids         = [aws_subnet.hub_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.hub.id

  tags = {
    Name = "payflow-hub-tgw-attachment"
  }
}

# Route to Spoke VPC via TGW in Public Route Table
resource "aws_route" "public_to_spoke" {
  route_table_id         = aws_route_table.hub_public.id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Private Route Table
resource "aws_route_table" "hub_private" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "payflow-hub-private-rt-${var.environment}"
  }
}

resource "aws_route_table_association" "hub_private" {
  subnet_id      = aws_subnet.hub_private.id
  route_table_id = aws_route_table.hub_private.id
}

# Route to Spoke VPC via TGW in Private Route Table
resource "aws_route" "private_to_spoke" {
  route_table_id         = aws_route_table.hub_private.id
  destination_cidr_block = "10.1.0.0/16"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}