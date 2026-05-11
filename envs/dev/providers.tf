provider "aws" {
  region = var.aws_region

  # TODO(phase1): once the dev AWS account + its TerraformExecution role
  # exist, uncomment to assume into them from the mgmt account:
  #
  # assume_role {
  #   role_arn = "arn:aws:iam::${var.dev_account_id}:role/TerraformExecution"
  # }

  default_tags {
    tags = local.base_tags
  }
}
