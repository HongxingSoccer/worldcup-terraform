variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment slug. Hard-coded per env directory; here to be referenced by locals + modules."
  type        = string
  default     = "dev"
}

variable "dev_account_id" {
  description = "12-digit AWS account ID for the dev workload account. Injected via terraform.tfvars; no default to force an explicit value."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.dev_account_id))
    error_message = "dev_account_id must be a 12-digit AWS account ID."
  }
}
