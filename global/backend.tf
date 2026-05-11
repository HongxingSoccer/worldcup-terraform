# `global` runs from the management account and bootstraps cross-account
# resources (Route 53 zone, GitHub OIDC provider, organisational policies).
# Its state lives in the same bucket as the per-env states, under a
# `global/` prefix so blast radius stays bounded.
terraform {
  backend "s3" {
    bucket         = "wcp-tf-state-mgmt"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "wcp-tf-locks"
    encrypt        = true
  }
}
