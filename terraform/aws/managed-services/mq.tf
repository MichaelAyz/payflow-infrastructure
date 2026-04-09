resource "aws_security_group" "mq" {
  name        = "payflow-mq-sg-${var.environment}"
  description = "Security group for Amazon MQ RabbitMQ"
  vpc_id      = var.spoke_vpc_id

  ingress {
    description     = "Allow AMQPS from EKS nodes"
    from_port       = 5671
    to_port         = 5671
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  ingress {
    description     = "Allow Management Console from EKS nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  tags = {
    Name = "payflow-mq-sg-${var.environment}"
  }
}

resource "aws_mq_broker" "rabbitmq" {
  broker_name                = "payflow-rabbitmq-${var.environment}"
  engine_type                = "RabbitMQ"
  engine_version             = "3.13"
  host_instance_type         = "mq.t3.micro"
  deployment_mode            = "SINGLE_INSTANCE"
  publicly_accessible        = false
  auto_minor_version_upgrade = true
  subnet_ids                 = [var.private_subnet_ids[0]]
  security_groups            = [aws_security_group.mq.id]

  user {
    username = "payflow_mq"
    password = var.mq_password
  }
}
