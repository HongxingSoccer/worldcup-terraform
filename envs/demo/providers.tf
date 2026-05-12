provider "aws" {
  region = var.aws_region

  # TODO(phase1): assume into the demo workload account once the role exists.
  #
  # assume_role {
  #   role_arn = "arn:aws:iam::${var.demo_account_id}:role/TerraformExecution"
  # }

  default_tags {
    tags = local.base_tags
  }
}
