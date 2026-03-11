
# NAT Gateway to provide internet for private subnets
module "natgw" {
  source = "./modules/natgw"

  vpc_id                  = module.vpc.vpc_id
  public_subnet_id        = module.vpc.public_subnet_ids[0]
  private_route_table_ids = module.vpc.private_route_table_ids
  tags                    = var.tags
}
