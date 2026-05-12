variable "aws_region" {
  description = "AWS region for global resources. Route 53 / IAM are global but the provider still needs a region."
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "wcp"
      Scope     = "global"
      ManagedBy = "terraform"
    }
  }
}
