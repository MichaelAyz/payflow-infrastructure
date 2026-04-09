resource "aws_db_subnet_group" "postgres" {
  name       = "payflow-rds-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "rds" {
  name        = "payflow-rds-sg-${var.environment}"
  description = "Security group for RDS instance"
  vpc_id      = var.spoke_vpc_id

  ingress {
    description     = "Allow PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  tags = {
    Name = "payflow-rds-sg-${var.environment}"
  }
}

resource "aws_db_instance" "postgres" {
  identifier           = "payflow-postgres-${var.environment}"
  engine               = "postgres"
  engine_version       = "16"
  instance_class       = "db.t3.micro"
  db_name              = "payflow"
  username             = "payflow_user"
  password             = var.db_password
  allocated_storage    = 20
  storage_type         = "gp2"
  multi_az             = false
  publicly_accessible  = false
  deletion_protection  = false
  skip_final_snapshot  = true
  apply_immediately    = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.rds.id]
}
