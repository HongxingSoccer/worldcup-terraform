# `modules/s3-bucket`

Opinionated wrapper around `aws_s3_bucket` with the surrounding hardening
resources (versioning, SSE, public-access block, lifecycle, CORS, policy)
all wired through one input surface. Designed to be reused for every
S3 bucket the project needs.

Defaults assume **private, encrypted, versioned**. Override per use case.

## Common use cases

### 1. Sharing-card render bucket (cards)

Pages download these via the frontend, so CORS is open. They're cheap to
regenerate, so versioning is off and `force_destroy = true` is OK in dev.

```hcl
module "s3_cards" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-${var.environment}-cards-${local.account_suffix}"
  environment        = var.environment
  versioning_enabled = false
  force_destroy      = var.environment == "dev"

  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://${var.domain}", "https://www.${var.domain}"]
      max_age_seconds = 3600
    }
  ]
}
```

### 2. MLflow artifacts

Models matter — versioning on. Lifecycle expires runs after a year.

```hcl
module "s3_mlflow" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-${var.environment}-mlflow-artifacts-${local.account_suffix}"
  environment        = var.environment
  versioning_enabled = true
  lifecycle_rules = [
    {
      id              = "expire-old-runs"
      expiration_days = 365
    }
  ]
}
```

### 3. Frontend static bundle (Next.js export → CloudFront)

CloudFront serves; bucket itself stays private. Policy comes from the
CloudFront OAI module (not in this PR — left as `bucket_policy_json = ""`).

```hcl
module "s3_frontend_static" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-${var.environment}-frontend-static-${local.account_suffix}"
  environment        = var.environment
  versioning_enabled = false      # CI re-uploads on every deploy
}
```

### 4. Terraform state (bootstrap)

Created **manually** before the rest of the stack — the backend can't
reference its own bucket. But once it exists, this module can describe it
for documentation.

```hcl
module "s3_tf_state" {
  source = "../../modules/s3-bucket"

  bucket_name        = "wcp-tf-state-mgmt"
  environment        = "global"
  versioning_enabled = true       # mandatory for state
  force_destroy      = false      # do not let TF clobber its own state
  lifecycle_rules = [
    {
      id                                 = "expire-old-state-versions"
      noncurrent_version_expiration_days = 90
    }
  ]
}
```

## Variables (full list)

See [`variables.tf`](variables.tf). Highlights:

| Name | Default | Notes |
|---|---|---|
| `bucket_name` | — | Caller resolves it (account-suffixed for uniqueness) |
| `versioning_enabled` | `true` | Off for transient buckets (cards / static export) |
| `force_destroy` | `false` | `true` in dev so `terraform destroy` cleans up |
| `kms_key_arn` | `""` | Empty falls back to SSE-S3 (AES256). Provide a CMK ARN for SSE-KMS — bucket keys auto-enabled |
| `block_public_access` | `true` | Almost always leave on. Set false only for truly public buckets |
| `lifecycle_rules` | `[]` | List of rule objects; see variable docstring |
| `cors_rules` | `[]` | Frontend/cards bucket only |
| `bucket_policy_json` | `""` | Use `jsonencode({...})`; depends_on the public-access block |

## Outputs

| Name | Notes |
|---|---|
| `bucket_id` | Same as input name |
| `bucket_arn` | For IAM policies |
| `bucket_domain_name` | Legacy global endpoint |
| `bucket_regional_domain_name` | Use for CloudFront origin |
| `bucket_hosted_zone_id` | Route 53 alias-record target |
