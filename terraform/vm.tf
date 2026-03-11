# Bastion VM
module "bastion" {
  source = "./modules/vm"

  instance_name               = "bastion"
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnet_ids[0]
  security_groups             = [module.security_groups.bastion_security_group_id]
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name
  tags = merge(var.tags, {
    Component = "bastion"
  })
}

# SLURM Controller VM
module "slurm_controller" {
  source = "./modules/vm"

  instance_name   = "slurm-controller"
  instance_type   = "t3.medium"
  subnet_id       = module.vpc.private_control_subnet_ids[0]
  security_groups = [module.security_groups.private_security_group_id]
  key_name        = var.ssh_key_name
  tags = merge(var.tags, {
    Component = "slurm-controller"
  })
}

# Kubernetes Control Plane VM
module "k8s_control_plane" {
  source = "./modules/vm"

  instance_name   = "k8s-control-plane"
  instance_type   = "t3.medium"
  subnet_id       = module.vpc.private_control_subnet_ids[0]
  security_groups = [module.security_groups.private_security_group_id]
  key_name        = var.ssh_key_name
  tags = merge(var.tags, {
    Component = "kubernetes-control-plane"
  })
}

# GPU Node 1 VM
module "gpu_node_1" {
  source = "./modules/vm"

  instance_name   = "gpu-node-1"
  instance_type   = "g4dn.xlarge"
  subnet_id       = module.vpc.private_compute_subnet_ids[0]
  security_groups = [module.security_groups.private_security_group_id]
  key_name        = var.ssh_key_name
  tags = merge(var.tags, {
    Component = "gpu-node"
    NodeID    = "1"
  })
}

# GPU Node 2 VM
module "gpu_node_2" {
  source = "./modules/vm"

  instance_name   = "gpu-node-2"
  instance_type   = "g4dn.xlarge"
  subnet_id       = module.vpc.private_compute_subnet_ids[1]
  security_groups = [module.security_groups.private_security_group_id]
  key_name        = var.ssh_key_name
  tags = merge(var.tags, {
    Component = "gpu-node"
    NodeID    = "2"
  })
}

# CPU Worker VM
module "cpu_worker" {
  source = "./modules/vm"

  instance_name   = "cpu-worker"
  instance_type   = "c5.xlarge"
  subnet_id       = module.vpc.private_compute_subnet_ids[0]
  security_groups = [module.security_groups.private_security_group_id]
  key_name        = var.ssh_key_name
  tags = merge(var.tags, {
    Component = "cpu-worker"
  })
}
