resource "aws_elasticache_subnet_group" "redis" {
  name       = "payflow-redis-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
  name        = "payflow-redis-sg-${var.environment}"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.spoke_vpc_id

  ingress {
    description     = "Allow Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.node_security_group_id]
  }

  tags = {
    Name = "payflow-redis-sg-${var.environment}"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "payflow-redis-${var.environment}"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  engine_version       = "7.0"
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
  apply_immediately    = true
}
