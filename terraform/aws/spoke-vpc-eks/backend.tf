terraform {
  backend "s3" {
    bucket         = "payflow-tfstate-647739191426"
    key            = "spoke-vpc-eks/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "payflow-tf-locks"
    encrypt        = true
  }
}
