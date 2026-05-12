locals {
  base_tags = {
    Project     = "wcp"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
