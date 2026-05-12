# `modules/ecr`

Creates a batch of ECR repositories with sane defaults:

- `scan_on_push = true` (CVE scanning)
- AES256 encryption at rest
- Lifecycle policy: keep the most recent N tagged images, expire untagged after 7 days
- Optional cross-principal access policy (set `allowed_principals` once the
  GitHub Actions / EKS IRSA roles exist)

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"

  environment           = "dev"
  repositories          = ["ml-api", "java-api", "frontend", "card-worker"]
  image_retention_count = 30
  tags                  = local.base_tags
  # allowed_principals  = [aws_iam_role.gha_oidc.arn, module.eks.workers_role_arn]
}
```

Resolved names: `wcp-dev-ml-api`, `wcp-dev-java-api`, … Stable map keys
(`"ml-api"`, `"frontend"`, …) so downstream `module.ecr.repository_urls["ml-api"]`
keeps working even if the resolved repo name format changes.

## Image tag strategy

Recommended:

- **CI builds:** `git-${SHORT_SHA}` (e.g. `git-a1b2c3d`). Reproducible, easy to
  trace back to a commit, never collides.
- **Releases:** add a semver tag (`v0.3.0`) on top of the SHA-tagged image.
  Use `docker buildx imagetools create --tag …` to retag without re-pushing layers.
- **Don't use `latest`:** the lifecycle policy won't expire it (it's always
  the newest "tagged" image) but it makes rollbacks ambiguous.

`image_tag_mutability` defaults to `MUTABLE` because dev needs to be able to
re-push `latest` while iterating. For demo/prod, override to `IMMUTABLE`.

## Local docker login + push

```sh
# Authenticate (rotates every 12h)
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin \
      $(terraform output -raw registry_id).dkr.ecr.us-east-1.amazonaws.com

# Push
URL=$(terraform output -json repository_urls | jq -r '.["ml-api"]')
docker tag wcp-ml-api:local "$URL:git-$(git rev-parse --short HEAD)"
docker push "$URL:git-$(git rev-parse --short HEAD)"
```

## Variables

| Name | Type | Default | Notes |
|---|---|---|---|
| `environment` | string | — | Used in the repo name prefix |
| `repositories` | list(string) | — | Short names; resolved to `wcp-{env}-{name}` |
| `tags` | map(string) | `{}` | Merged with module-level base tags |
| `allowed_principals` | list(string) | `[]` | If empty, no repository policy is created |
| `image_retention_count` | number | `30` | Tagged images to keep |
| `untagged_image_expiration_days` | number | `7` | When untagged builds get pruned |
| `image_tag_mutability` | string | `MUTABLE` | `IMMUTABLE` for prod/demo |

## Outputs

| Name | Type | Notes |
|---|---|---|
| `repository_urls` | map(string) | docker push target per repo |
| `repository_arns` | map(string) | Reference in IAM policies |
| `repository_names` | map(string) | Full resolved name per repo |
| `registry_id` | string | The owning AWS account ID |
