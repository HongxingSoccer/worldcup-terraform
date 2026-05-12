# SKELETON — implemented in Phase 1.
#
# Will create:
#   aws_route53_zone.public  (e.g. wcp.example.com)
#   aws_route53_delegation_set (optional, lets us pre-allocate NS records)
#
# Per-environment subdomains (dev.wcp.example.com, demo.wcp.example.com)
# are delegated NS records pointing at zones owned by the workload accounts,
# or — simpler — A records in this same zone aliased to the per-env ALBs.
# Decision deferred to Phase 1.
