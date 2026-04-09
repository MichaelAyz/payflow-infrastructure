output "hub_vpc_id" {
  description = "The ID of the Hub VPC"
  value       = aws_vpc.hub.id
}

output "hub_public_subnet_id" {
  description = "The ID of the Hub public subnet"
  value       = aws_subnet.hub_public.id
}

output "hub_private_subnet_id" {
  description = "The ID of the Hub private subnet"
  value       = aws_subnet.hub_private.id
}

output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.tgw.id
}

output "transit_gateway_attachment_id" {
  description = "The ID of the Hub Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}
