output "bastion_instance_id" {
  description = "The ID of the Bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "The public IP of the Bastion instance"
  value       = aws_instance.bastion.public_ip
}

output "ssm_connect_command" {
  description = "Command to connect to bastion via SSM"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id} --region us-east-1"
}
