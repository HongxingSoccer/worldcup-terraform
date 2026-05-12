output "account_id" {
  description = "Resolved AWS account ID for sanity checking after init."
  value       = data.aws_caller_identity.current.account_id
}

output "ecr_repository_urls" {
  description = "Map of short name → ECR push URL."
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of short name → ECR repo ARN. Reference in IAM policies."
  value       = module.ecr.repository_arns
}

output "s3_cards_bucket" {
  description = "S3 bucket name for rendered sharing cards."
  value       = module.s3_cards.bucket_id
}

output "s3_mlflow_bucket" {
  description = "S3 bucket name for MLflow artifacts."
  value       = module.s3_mlflow.bucket_id
}

output "s3_frontend_bucket" {
  description = "S3 bucket name for the static Next.js export."
  value       = module.s3_frontend_static.bucket_id
}
