locals {
  base_tags = {
    Project     = "wcp"
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "ecr"
  }

  # Short name → full ECR repo name. Stable map key for downstream references.
  repository_names = { for name in var.repositories : name => "wcp-${var.environment}-${name}" }
}

resource "aws_ecr_repository" "this" {
  for_each = local.repository_names

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  # AES256 is the AWS-managed default — fine for now. KMS lives behind a
  # separate variable when we have a dedicated key per environment.
  encryption_configuration {
    encryption_type = "AES256"
  }

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(local.base_tags, var.tags, {
    Name       = each.value
    Repository = each.key
  })
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_retention_count} tagged images"
        selection = {
          tagStatus      = "tagged"
          tagPatternList = ["*"]
          countType      = "imageCountMoreThan"
          countNumber    = var.image_retention_count
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after ${var.untagged_image_expiration_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiration_days
        }
        action = { type = "expire" }
      }
    ]
  })
}

# Only attached when the caller has explicit role ARNs to grant pull/push.
# Until those exist (Phase 1 GitHub Actions role + Phase 4 EKS IRSA roles)
# IAM-side policies on those principals are the access path.
resource "aws_ecr_repository_policy" "this" {
  for_each = length(var.allowed_principals) > 0 ? aws_ecr_repository.this : {}

  repository = each.value.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPullPushFromTrustedPrincipals"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
        ]
      }
    ]
  })
}
