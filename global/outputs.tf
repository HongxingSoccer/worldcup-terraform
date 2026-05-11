# Outputs will surface:
#   - github_oidc_provider_arn  (input to per-env github-actions-role module)
#   - public_zone_id            (input to per-env Route 53 alias records)
#   - public_zone_name_servers  (for delegating from a parent domain)
#
# Empty for now — populated alongside the resources they reference.
