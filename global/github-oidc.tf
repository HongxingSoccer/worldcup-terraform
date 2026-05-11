# SKELETON — implemented in Phase 1.
#
# Will create:
#   aws_iam_openid_connect_provider.github
#     - url: https://token.actions.githubusercontent.com
#     - client_id_list: ["sts.amazonaws.com"]
#     - thumbprint pinned to GitHub's well-known cert
#
# Per-environment GitHub Actions roles (one per workload account) live in
# modules/github-actions-role and assume from this provider.
#
# Left out of this PR to keep Phase 3 self-contained.
