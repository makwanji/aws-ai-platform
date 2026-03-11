module "security_groups" {
  source = "./modules/security_groups"

  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr_block
  tags     = var.tags
}
