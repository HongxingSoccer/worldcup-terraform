# Remote state lives in the management account's state bucket. That bucket
# and the lock table must be created by hand (or by a one-shot bootstrap
# script — see deploy/terraform/README.md) before `terraform init` will work.
terraform {
  backend "s3" {
    bucket         = "wcp-tf-state-mgmt"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "wcp-tf-locks"
    encrypt        = true
  }
}
