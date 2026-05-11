variable "environment" {
  description = "Environment slug used in repo name prefix (e.g. \"dev\", \"demo\")."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "environment must be lowercase alphanumeric with optional dashes."
  }
}

variable "repositories" {
  description = "List of repository short names. Resolved name becomes wcp-{environment}-{name}."
  type        = list(string)

  validation {
    condition     = length(var.repositories) > 0
    error_message = "Provide at least one repository name."
  }
}

variable "tags" {
  description = "Tags merged with the module's base tags onto every resource."
  type        = map(string)
  default     = {}
}

variable "allowed_principals" {
  description = <<-EOT
    IAM principal ARNs allowed to push / pull from these repositories. When
    empty (the default) no aws_ecr_repository_policy resource is created, so
    access falls back to plain IAM policies in the calling account. Populate
    with EKS IRSA role + GitHub Actions OIDC role ARNs once those exist.
  EOT
  type        = list(string)
  default     = []
}

variable "image_retention_count" {
  description = "Number of most-recent tagged images to keep per repository. Older ones are expired by the lifecycle policy."
  type        = number
  default     = 30

  validation {
    condition     = var.image_retention_count >= 1
    error_message = "image_retention_count must be >= 1."
  }
}

variable "untagged_image_expiration_days" {
  description = "Days after which untagged images are deleted (build leftovers)."
  type        = number
  default     = 7
}

variable "image_tag_mutability" {
  description = "MUTABLE or IMMUTABLE. IMMUTABLE rejects re-pushing the same tag; safer for prod, awkward for dev."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}
