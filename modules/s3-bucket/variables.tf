variable "bucket_name" {
  description = "Fully-resolved bucket name. The caller is responsible for global uniqueness (typical pattern: wcp-{env}-{purpose}-{accountSuffix})."
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "S3 bucket names must be 3–63 characters."
  }
}

variable "environment" {
  description = "Environment slug used in tags."
  type        = string
}

variable "tags" {
  description = "Tags merged with module base tags onto every resource."
  type        = map(string)
  default     = {}
}

variable "versioning_enabled" {
  description = "Enable bucket versioning. Required for MLflow artifacts (rollback) and Terraform state buckets; cheap for everything else but pays storage for old object versions."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow `terraform destroy` to wipe a non-empty bucket. Use true in dev, false in demo/prod."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN for SSE. Empty string falls back to AES256 (SSE-S3)."
  type        = string
  default     = ""
}

variable "block_public_access" {
  description = "Apply the four-way Public Access Block (block public ACLs + block public policy + ignore public ACLs + restrict public buckets). Default true; only set false if you really need public objects."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = <<-EOT
    List of lifecycle rules. Each entry supports:
      - id              (required, unique within the bucket)
      - enabled         (bool, default true)
      - prefix          (string, default "")
      - expiration_days (number, optional — delete current version after N days)
      - noncurrent_version_expiration_days (number, optional — only meaningful when versioning is on)
      - transitions     (list of { days, storage_class } objects)
  EOT
  type = list(object({
    id                                 = string
    enabled                            = optional(bool, true)
    prefix                             = optional(string, "")
    expiration_days                    = optional(number)
    noncurrent_version_expiration_days = optional(number)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
  }))
  default = []
}

variable "cors_rules" {
  description = "List of CORS rules. Set for the frontend / cards bucket; leave empty for ML / TF state."
  type = list(object({
    allowed_methods = list(string)
    allowed_origins = list(string)
    allowed_headers = optional(list(string), [])
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

variable "bucket_policy_json" {
  description = "Optional bucket policy as a JSON string. Use jsonencode({...}) on the caller side. Empty string skips the policy resource."
  type        = string
  default     = ""
}
