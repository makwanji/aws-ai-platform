module "vpc" {
  source = "./modules/vpc"

  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  public_subnets          = var.public_subnets
  private_compute_subnets = var.private_compute_subnets
  private_control_subnets = var.private_control_subnets
  storage_subnets         = var.storage_subnets
  tags                    = var.tags
}
