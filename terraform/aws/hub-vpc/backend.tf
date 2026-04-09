terraform {
  backend "s3" {
    bucket         = "payflow-tfstate-647739191426"
    key            = "hub-vpc/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "payflow-tf-locks"
    encrypt        = true
  }
}
