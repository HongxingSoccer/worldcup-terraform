output "bucket_id" {
  description = "Bucket name (same as the input bucket_name)."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "Bucket ARN. Reference in IAM policies."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Legacy DNS-style bucket endpoint (us-east-1 only)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Region-scoped DNS endpoint. Prefer this for cross-region or CloudFront origin configs."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the bucket's S3 website endpoint. Used in alias records."
  value       = aws_s3_bucket.this.hosted_zone_id
}
