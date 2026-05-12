data "aws_caller_identity" "current" {}

locals {
  account_suffix = substr(data.aws_caller_identity.current.account_id, -4, 4)
}

# -----------------------------------------------------------------------------
# ECR — same repo set as dev. image_tag_mutability flipped to IMMUTABLE so
# a recycled SHA-tagged image can't be silently re-pushed in demo.
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  environment           = var.environment
  repositories          = ["ml-api", "java-api", "frontend", "card-worker"]
  image_retention_count = 30
  image_tag_mutability  = "IMMUTABLE"
  tags                  = local.base_tags
}

# -----------------------------------------------------------------------------
# S3 — demo defaults lean toward "treat this like prod":
#   force_destroy=false everywhere (no accidental wipes)
#   cors locked to the public domain (no wildcard origin)
# -----------------------------------------------------------------------------
module "s3_cards" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-${var.environment}-cards-${local.account_suffix}"
  environment        = var.environment
  tags               = local.base_tags
  versioning_enabled = false
  force_destroy      = false

  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://${var.public_domain}"]
      allowed_headers = ["*"]
      max_age_seconds = 3600
    }
  ]
}

module "s3_mlflow" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-${var.environment}-mlflow-artifacts-${local.account_suffix}"
  environment        = var.environment
  tags               = local.base_tags
  versioning_enabled = true
  force_destroy      = false

  lifecycle_rules = [
    {
      id              = "expire-old-runs"
      enabled         = true
      expiration_days = 365
    }
  ]
}

module "s3_frontend_static" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-${var.environment}-frontend-static-${local.account_suffix}"
  environment        = var.environment
  tags               = local.base_tags
  versioning_enabled = false
  force_destroy      = false
}
