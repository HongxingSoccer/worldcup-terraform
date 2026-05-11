data "aws_caller_identity" "current" {}

locals {
  # Append the last four digits of the account ID to bucket names so that
  # the global S3 namespace stays unique across forks / staging accounts.
  account_suffix = substr(data.aws_caller_identity.current.account_id, -4, 4)
}

# -----------------------------------------------------------------------------
# ECR — one repository per Dockerfile we ship.
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  environment           = var.environment
  repositories          = ["ml-api", "java-api", "frontend", "card-worker"]
  image_retention_count = 30
  tags                  = local.base_tags

  # allowed_principals is populated once Phase 1 (GitHub Actions OIDC role)
  # and Phase 4 (EKS IRSA roles) outputs exist; leaving empty falls back to
  # IAM-side policies on the calling principal.
  # allowed_principals = []
}

# -----------------------------------------------------------------------------
# S3 — three buckets with three very different lifecycles.
# -----------------------------------------------------------------------------
module "s3_cards" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-${var.environment}-cards-${local.account_suffix}"
  environment        = var.environment
  tags               = local.base_tags
  versioning_enabled = false # share cards are regenerable; old versions waste storage
  force_destroy      = true  # dev: allow terraform destroy to clean up

  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"] # dev: wide-open; demo locks this to the public domain
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
  versioning_enabled = true # model artifacts need rollback
  force_destroy      = true # dev

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
  versioning_enabled = false # CI re-uploads on every deploy
  force_destroy      = true

  # CloudFront OAI policy lands here once the CDN module ships. For now the
  # bucket is private; nothing reads from it.
  # bucket_policy_json = data.aws_iam_policy_document.cloudfront_oai.json
}
