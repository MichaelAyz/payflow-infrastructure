# RDS PostgreSQL URL
resource "aws_secretsmanager_secret" "db" {
  name                    = "payflow/db-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = "postgresql://payflow_user:${var.db_password}@${aws_db_instance.postgres.endpoint}/payflow"
}

# ElastiCache Redis URL
resource "aws_secretsmanager_secret" "redis" {
  name                    = "payflow/redis-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id     = aws_secretsmanager_secret.redis.id
  secret_string = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
}

# Amazon MQ RabbitMQ URL
resource "aws_secretsmanager_secret" "mq" {
  name                    = "payflow/mq-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "mq" {
  secret_id     = aws_secretsmanager_secret.mq.id
  secret_string = "amqps://payflow_mq:${var.mq_password}@${replace(aws_mq_broker.rabbitmq.instances[0].endpoints[0], "amqps://", "")}"
}

# JWT Secret
resource "aws_secretsmanager_secret" "jwt" {
  name                    = "payflow/jwt-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "jwt" {
  secret_id     = aws_secretsmanager_secret.jwt.id
  secret_string = var.jwt_secret
}
