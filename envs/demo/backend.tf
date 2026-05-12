terraform {
  backend "s3" {
    bucket         = "wcp-tf-state-mgmt"
    key            = "demo/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "wcp-tf-locks"
    encrypt        = true
  }
}
