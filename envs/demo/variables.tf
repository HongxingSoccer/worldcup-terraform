variable "aws_region" {
  description = "AWS region for the demo environment."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment slug."
  type        = string
  default     = "demo"
}

variable "demo_account_id" {
  description = "12-digit AWS account ID for the demo workload account."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.demo_account_id))
    error_message = "demo_account_id must be a 12-digit AWS account ID."
  }
}

variable "public_domain" {
  description = "Public domain that fronts the demo environment. Used as the only allowed CORS origin on the cards bucket."
  type        = string
  default     = "demo.wcp.example.com"
}
