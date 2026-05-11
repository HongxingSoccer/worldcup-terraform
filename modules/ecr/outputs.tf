output "repository_urls" {
  description = "Map of short name → repository URL (used as the docker push target)."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "repository_arns" {
  description = "Map of short name → repository ARN. Reference these in IAM policies."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.arn }
}

output "repository_names" {
  description = "Map of short name → full ECR repository name."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.name }
}

output "registry_id" {
  description = "AWS account ID hosting the registry. Stable across repositories."
  value       = values(aws_ecr_repository.this)[0].registry_id
}
