# `worldcup-terraform` — AWS infrastructure

Terraform stack that provisions every AWS resource the World Cup 2026
Predictor depends on. Currently a sibling directory inside the
`HongxingSoccer/Project` monorepo; **scheduled to be extracted into its
own GitHub repo** (`worldcup-terraform`), which is why it lives at the
top level instead of under `worldcup-predictor/deploy/`.

Phase 3 ships only the **registry + object-storage layer** (ECR + three
S3 buckets) plus skeletons for the management-account `global/` stack.
Everything else (VPC, EKS, RDS, ElastiCache, MSK, Secrets Manager,
GHA OIDC role, Route 53) is pre-staged with empty files and TODO
comments — they land in later phases.

## Layout

```
worldcup-terraform/
├── README.md                    ← this file
├── .gitignore                   ← state, locks, .terraform/, *.tfvars
│
├── global/                      ← management account, cross-account resources
│   ├── backend.tf / providers.tf / versions.tf
│   ├── github-oidc.tf           🚧 skeleton — Phase 1
│   ├── route53.tf               🚧 skeleton — Phase 1
│   └── outputs.tf
│
├── modules/
│   ├── ecr/                     ✅ this PR
│   ├── s3-bucket/               ✅ this PR
│   ├── vpc/                     🚧 Phase 1
│   ├── security-groups/         🚧 Phase 1
│   ├── github-actions-role/     🚧 Phase 1
│   ├── rds/                     🚧 Phase 3 (data layer)
│   ├── elasticache/             🚧 Phase 3
│   ├── msk-serverless/          🚧 Phase 3
│   ├── secrets-manager/         🚧 Phase 3
│   └── eks/                     🚧 Phase 4
│
└── envs/
    ├── dev/                     ✅ wired to ecr + 3× s3-bucket
    └── demo/                    ✅ same, with prod-leaning overrides
```

The older `environments/` + module skeletons (`oss/`, `k8s-cluster/`,
`rds/`, `redis/`, `cdn/`) at the top level are Phase 5 cloud-agnostic
placeholders from the initial import. They predate the AWS-first decision
and will be retired once their AWS replacements ship.

## Bootstrap (one-time, by hand)

The S3 backend can't create its own state bucket — chicken/egg. Before
the first `terraform init` against any env, create the state bucket +
DynamoDB lock table in the management account:

```sh
ACCOUNT_ID=<mgmt account id>

aws s3api create-bucket --bucket wcp-tf-state-mgmt --region us-east-1
aws s3api put-bucket-versioning --bucket wcp-tf-state-mgmt \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket wcp-tf-state-mgmt \
  --server-side-encryption-configuration '{
    "Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]
  }'
aws s3api put-public-access-block --bucket wcp-tf-state-mgmt \
  --public-access-block-configuration \
    BlockPublicAcls=true,BlockPublicPolicy=true,IgnorePublicAcls=true,RestrictPublicBuckets=true

aws dynamodb create-table --table-name wcp-tf-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST --region us-east-1
```

## Local workflow

```sh
cd worldcup-terraform/envs/dev
cp terraform.tfvars.example terraform.tfvars
# Fill in dev_account_id with the real 12-digit ID.

terraform init                  # reads backend.tf, needs the state bucket
terraform plan                  # dry-run; nothing applied yet
# When you're happy:
terraform apply
```

For CI / offline validation (no state bucket needed):

```sh
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

## What this PR creates (per env)

Resolved against `account_id=987654321012` for illustration. The 4-digit
suffix is `substr(account_id, -4, 4)`.

| Resource | Dev | Demo |
|---|---|---|
| ECR repos | `wcp-dev-{ml-api,java-api,frontend,card-worker}` | `wcp-demo-…` |
| ECR `image_tag_mutability` | `MUTABLE` (iterate freely) | `IMMUTABLE` (block accidental re-push) |
| S3 cards bucket | `wcp-dev-cards-1012` | `wcp-demo-cards-1012` |
| S3 cards CORS origins | `["*"]` | `["https://${var.public_domain}"]` |
| S3 MLflow bucket | `wcp-dev-mlflow-artifacts-1012` (versioning on, 365d lifecycle) | `wcp-demo-mlflow-artifacts-1012` |
| S3 frontend static | `wcp-dev-frontend-static-1012` | `wcp-demo-frontend-static-1012` |
| `force_destroy` everywhere | `true` (let TF destroy clean up) | `false` (treat as prod-ish) |

## CI validation

`.github/workflows/terraform-validate.yml` triggers on PRs that touch
`worldcup-terraform/**`. It:

1. Installs Terraform 1.6
2. Runs `terraform fmt -check -recursive`
3. Runs `terraform init -backend=false` + `terraform validate` on every
   module and every env (the `-backend=false` flag skips the state-bucket
   requirement, which CI doesn't have).

## What's deliberately not here

- No `terraform apply` is wired anywhere — Phase 0 (cloud account
  provisioning) has to finish first.
- No KMS modules — defaults SSE-S3 for now. CMK-encrypted buckets are
  supported by the module's `kms_key_arn` input the moment we want them.
- No CloudFront / OAI policy on the frontend static bucket — those land
  when the CDN module ships.
- No cross-account assume-role policies on ECR — `allowed_principals`
  stays empty until the Phase 1 GHA role + Phase 4 IRSA roles exist.
