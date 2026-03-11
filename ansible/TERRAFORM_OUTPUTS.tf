# Add these outputs to your terraform/vm.tf or terraform/outputs.tf
# These outputs are required for the Ansible inventory generation script

output "bastion_public_ip" {
  description = "Public IP of bastion host"
  value       = module.bastion.instance_public_ip
}

output "bastion_private_ip" {
  description = "Private IP of bastion host"
  value       = module.bastion.instance_private_ip
}

output "slurm_controller_private_ip" {
  description = "Private IP of SLURM controller"
  value       = module.slurm_controller.instance_private_ip
}

output "k8s_control_plane_private_ip" {
  description = "Private IP of Kubernetes control plane"
  value       = module.k8s_control_plane.instance_private_ip
}

output "gpu_node_1_private_ip" {
  description = "Private IP of GPU node 1"
  value       = module.gpu_node_1.instance_private_ip
}

output "gpu_node_2_private_ip" {
  description = "Private IP of GPU node 2"
  value       = module.gpu_node_2.instance_private_ip
}

output "cpu_worker_private_ip" {
  description = "Private IP of CPU worker"
  value       = module.cpu_worker.instance_private_ip
}

# Optional: Additional useful outputs
output "all_vm_ids" {
  description = "All VM instance IDs"
  value = {
    bastion           = module.bastion.instance_id
    slurm_controller  = module.slurm_controller.instance_id
    k8s_control_plane = module.k8s_control_plane.instance_id
    gpu_node_1        = module.gpu_node_1.instance_id
    gpu_node_2        = module.gpu_node_2.instance_id
    cpu_worker        = module.cpu_worker.instance_id
  }
}

output "all_vm_ips" {
  description = "All VM IPs for reference"
  value = {
    bastion = {
      public_ip  = module.bastion.instance_public_ip
      private_ip = module.bastion.instance_private_ip
    }
    slurm_controller = {
      private_ip = module.slurm_controller.instance_private_ip
    }
    k8s_control_plane = {
      private_ip = module.k8s_control_plane.instance_private_ip
    }
    gpu_node_1 = {
      private_ip = module.gpu_node_1.instance_private_ip
    }
    gpu_node_2 = {
      private_ip = module.gpu_node_2.instance_private_ip
    }
    cpu_worker = {
      private_ip = module.cpu_worker.instance_private_ip
    }
  }
}
