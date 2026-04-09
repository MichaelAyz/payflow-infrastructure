terraform {
  backend "s3" {
    bucket         = "payflow-tfstate-647739191426"
    key            = "managed-services/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "payflow-tf-locks"
    encrypt        = true
    use_lockfile   = true
  }
}
