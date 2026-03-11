# Inventory Management

This document describes the inventory structure and how to populate it with actual infrastructure IPs.

## Static Inventory (`inventory.ini`)

The `inventory.ini` file contains your infrastructure's inventory and should be populated with actual IPs.

### Structure

```ini
# Bastion (public subnet - direct SSH access)
[bastion]
bastion ansible_host=<BASTION_PUBLIC_IP> ansible_user=ec2-user

# Private VMs (private subnets - SSH via bastion tunnel)
[private_vms:children]
control_plane
compute_nodes
workers

[control_plane]
slurm-controller ansible_host=<IP> ansible_user=ec2-user
k8s-control-plane ansible_host=<IP> ansible_user=ec2-user

[compute_nodes]
gpu-node-1 ansible_host=<IP> ansible_user=ec2-user
gpu-node-2 ansible_host=<IP> ansible_user=ec2-user

[workers]
cpu-worker ansible_host=<IP> ansible_user=ec2-user

[gpu_nodes]
gpu-node-1
gpu-node-2

[all:vars]
ansible_ssh_private_key_file=~/.ssh/adnsg-aws-ai-platform.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

## Dynamic Inventory (`inventory-dynamic.ini`)

The `scripts/generate_inventory_from_terraform.sh` script generates this file automatically from Terraform outputs.

### Generation Steps

1. **Add Terraform Outputs to `vm.tf`**

```terraform
output "bastion_public_ip" {
  value = module.bastion.instance_public_ip
}

output "slurm_controller_private_ip" {
  value = module.slurm_controller.instance_private_ip
}

output "k8s_control_plane_private_ip" {
  value = module.k8s_control_plane.instance_private_ip
}

output "gpu_node_1_private_ip" {
  value = module.gpu_node_1.instance_private_ip
}

output "gpu_node_2_private_ip" {
  value = module.gpu_node_2.instance_private_ip
}

output "cpu_worker_private_ip" {
  value = module.cpu_worker.instance_private_ip
}
```

1. **Run Generation Script**

```bash
cd ansible
./scripts/generate_inventory_from_terraform.sh
```

1. **Verify Output**

```bash
cat inventory-dynamic.ini
```

1. **Update Static Inventory**

Copy IPs from `inventory-dynamic.ini` to `inventory.ini`:

```bash
# Manual copy or use sed
sed 's/<BASTION_PUBLIC_IP>/x.x.x.x/g' inventory.ini > inventory.ini.tmp
mv inventory.ini.tmp inventory.ini
```

## Host Variables (`host_vars/`)

Individual host configurations can go in `host_vars/<hostname>.yml`:

```yaml
# host_vars/gpu-node-1.yml
---
ansible_host: 10.10.10.5
ansible_user: ec2-user
gpu_count: 1
cuda_version: "12.4"
```

## Group Variables (`group_vars/`)

### `all.yml` - Global Settings

```yaml
update_packages: yes
reboot_after_update: no
ssh_key_path: ~/.ssh/adnsg-aws-ai-platform.pem
```

### `private_vms.yml` - Private VM Settings

```yaml
bastion_host: bastion
bastion_user: ec2-user
ansible_ssh_common_args: >
  -o ProxyCommand="ssh -W %h:%p
  -i ~/.ssh/adnsg-aws-ai-platform.pem
  ec2-user@{{ hostvars['bastion']['ansible_host'] }}"
```

### `gpu_nodes.yml` - GPU Node Settings

```yaml
update_gpu_drivers: yes
nvidia_driver_version: "latest"
cuda_version: "12.4"
```

## Usage Examples

### Verify Inventory

```bash
# List all hosts
ansible-i inventory.ini all --list-hosts

# List specific group
ansible -i inventory.ini bastion --list-hosts
ansible -i inventory.ini private_vms --list-hosts
ansible -i inventory.ini gpu_nodes --list-hosts
```

### Test Connectivity

```bash
# Ping all hosts
ansible -i inventory.ini all -m ping

# Ping with debugging
ansible -i inventory.ini all -m ping -vv

# Ping specific group
ansible -i inventory.ini bastion -m ping
ansible -i inventory.ini private_vms -m ping
```

### Get Host Information

```bash
# Show all variables for a host
ansible -i inventory.ini gpu-node-1 -m debug -a "var=hostvars[inventory_hostname]"

# Show specific variable
ansible -i inventory.ini all -m debug -a "var=ansible_os_family"

# Run remote command
ansible -i inventory.ini all -m command -a "uname -a"
```

## Tips and Best Practices

1. **Keep IPs Updated**: Update inventory when infrastructure changes
2. **Use Comments**: Add comments in inventory for clarity
3. **Version Control**: Track inventory changes in git
4. **Sensitive Data**: Don't commit SSH keys or sensitive IPs - use `.gitignore`
5. **Organization**: Use groups logically (by function, environment, etc.)

## Troubleshooting

### Inventory File Not Found

```bash
# Ensure inventory file exists
ls -la ansible/inventory.ini

# Specify path explicitly
ansible-playbook -i /full/path/to/inventory.ini playbooks/update_all_systems.yml
```

### Host Not Found

```bash
# Check if host is in inventory
ansible -i inventory.ini <hostname> --list-hosts

# List all available hosts
ansible -i inventory.ini all --list-hosts
```

### SSH Connection Failed

```bash
# Verify SSH key
ls -la ~/.ssh/adnsg-aws-ai-platform.pem
chmod 600 ~/.ssh/adnsg-aws-ai-platform.pem

# Test SSH manually
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<host-ip>
```

---

For more information, see [README.md](README.md)
