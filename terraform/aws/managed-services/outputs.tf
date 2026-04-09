output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "redis_endpoint" {
  description = "The endpoint address of the Redis cluster"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "mq_endpoint" {
  description = "The endpoint of the RabbitMQ broker"
  value       = aws_mq_broker.rabbitmq.instances[0].endpoints[0]
}

output "db_secret_arn" {
  description = "The ARN of the DB URL secret"
  value       = aws_secretsmanager_secret.db.arn
}

output "redis_secret_arn" {
  description = "The ARN of the Redis URL secret"
  value       = aws_secretsmanager_secret.redis.arn
}

output "mq_secret_arn" {
  description = "The ARN of the MQ URL secret"
  value       = aws_secretsmanager_secret.mq.arn
}

output "jwt_secret_arn" {
  description = "The ARN of the JWT secret"
  value       = aws_secretsmanager_secret.jwt.arn
}
