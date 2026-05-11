locals {
  base_tags = {
    Project     = "wcp"
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-bucket"
  }

  use_kms = var.kms_key_arn != ""
}

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(local.base_tags, var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# SSE: customer-managed KMS when an ARN is supplied, otherwise SSE-S3 (AES256).
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = local.use_kms ? "aws:kms" : "AES256"
      kms_master_key_id = local.use_kms ? var.kms_key_arn : null
    }
    # KMS-encrypted buckets benefit hugely from bucket keys (cuts KMS-side
    # request costs by ~99% on hot objects). Harmless when SSE-S3 is in use.
    bucket_key_enabled = local.use_kms
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days == null ? [] : [rule.value.expiration_days]
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration_days == null ? [] : [rule.value.noncurrent_version_expiration_days]
        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }
    }
  }

  # Lifecycle config has to wait for versioning to settle; otherwise applying
  # noncurrent-version rules to a versioning-suspended bucket can error.
  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      allowed_headers = cors_rule.value.allowed_headers
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.bucket_policy_json != "" ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy_json

  # Public-access block resources are evaluated before policy attachment; if
  # the policy grants principal:"*" while block_public_policy=true the API
  # rejects the policy. The order is enforced here to surface that as a
  # clear `depends_on`-driven graph dependency rather than a runtime error.
  depends_on = [aws_s3_bucket_public_access_block.this]
}
