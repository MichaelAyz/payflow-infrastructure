terraform {
  backend "s3" {
    bucket         = "payflow-tfstate-647739191426"
    key            = "bastion/dev/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }
}
