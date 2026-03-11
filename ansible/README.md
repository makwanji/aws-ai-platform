# Ansible Management for AWS AI Platform

This directory contains Ansible playbooks and configurations for managing VMs in the AWS AI Platform infrastructure.

## 🎯 Overview

The Ansible setup provides:

- **Modular roles** for OS updates and GPU driver management
- **Bastion host tunneling** for secure access to private subnet VMs
- **Multiple playbooks** for different update scenarios
- **Reusable components** for other projects

## 📁 Directory Structure

```
ansible/
├── playbooks/                 # Main playbook files
│   ├── update_all_systems.yml          # Update all VMs
│   ├── update_gpu_drivers.yml          # GPU driver updates only
│   ├── update_gpu_nodes_full.yml       # OS + GPU driver updates
│   ├── update_private_vms.yml          # Update private subnet VMs
│   └── update_control_plane.yml        # Update critical infrastructure
├── roles/                     # Reusable Ansible roles
│   ├── common_updates/
│   │   ├── tasks/main.yml              # OS update tasks
│   │   ├── handlers/main.yml           # Reboot and service restart handlers
│   │   └── defaults/main.yml           # Default variables
│   └── gpu_updates/
│       ├── tasks/main.yml              # GPU driver and CUDA tasks
│       └── defaults/main.yml           # GPU defaults
├── group_vars/                # Group-level variables
│   ├── all.yml                # Variables for all hosts
│   ├── private_vms.yml        # Private subnet settings (bastion tunnel)
│   └── gpu_nodes.yml          # GPU-specific settings
├── inventory.ini              # Static inventory (populate manually)
├── inventory-dynamic.ini      # Auto-generated from Terraform
├── ansible.cfg                # Ansible configuration
├── scripts/
│   ├── generate_inventory_from_terraform.sh    # Generate inventory from TF
│   ├── test_bastion_connectivity.sh            # Test bastion tunnel
│   └── run_ansible_playbook.sh                 # Playbook wrapper script
└── README.md                  # This file
```

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install Ansible (macOS)
brew install ansible

# Verify installation
ansible --version

# Ensure SSH key is available
ls ~/.ssh/adnsg-aws-ai-platform.pem
```

### 2. Generate Inventory from Terraform

```bash
cd ansible

# Make script executable
chmod +x scripts/generate_inventory_from_terraform.sh

# Generate inventory
./scripts/generate_inventory_from_terraform.sh

# Verify generated inventory
cat inventory-dynamic.ini
```

### 3. Update Inventory File

Edit `inventory.ini` and replace placeholder IPs with real IPs from `inventory-dynamic.ini`:

```bash
# Copy IPs from generated inventory
sed -i '' 's/<BASTION_PUBLIC_IP>/x.x.x.x/g' inventory.ini
sed -i '' 's/<SLURM_CONTROLLER_PRIVATE_IP>/10.10.x.x/g' inventory.ini
# ... update other IPs
```

### 4. Test Connectivity

```bash
# Test bastion host access
chmod +x scripts/test_bastion_connectivity.sh
./scripts/test_bastion_connectivity.sh

# Test via Ansible
ansible -i inventory.ini bastion -m ping
ansible -i inventory.ini private_vms -m ping
```

### 5. Run Playbooks

```bash
# Update all systems (no reboot)
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml

# Update all systems with reboot
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "reboot_after_update=yes"

# Dry-run (check mode)
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --check

# Verbose output
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -vv
```

## 📚 Available Playbooks

### `update_all_systems.yml`

Updates OS packages on all VMs (bastion + private VMs)

**Usage:**

```bash
# Standard update (no reboot)
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml

# With reboot
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "reboot_after_update=yes"

# Security updates only
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "update_security_only=yes"
```

### `update_gpu_drivers.yml`

Updates NVIDIA GPU drivers and CUDA toolkit on GPU nodes

**Usage:**

```bash
# Update GPU drivers (latest version)
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml

# Update to specific driver version
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml \
  --extra-vars "nvidia_driver_version=550.54.14"

# Update CUDA to specific version
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml \
  --extra-vars "cuda_version=12.1"
```

### `update_gpu_nodes_full.yml`

Performs complete update: OS packages + GPU drivers + CUDA

**Usage:**

```bash
# Full update with reboot
ansible-playbook -i inventory.ini playbooks/update_gpu_nodes_full.yml

# Full update with specific versions
ansible-playbook -i inventory.ini playbooks/update_gpu_nodes_full.yml \
  --extra-vars "nvidia_driver_version=550.54.14 cuda_version=12.4"
```

### `update_private_vms.yml`

Updates VMs in private subnets via bastion tunnel

**Usage:**

```bash
# Update private VMs
ansible-playbook -i inventory.ini playbooks/update_private_vms.yml
```

### `update_control_plane.yml`

Updates critical infrastructure VMs (SLURM controller, K8s control plane)

**Usage:**

```bash
# Update control plane (security updates only, no reboot)
ansible-playbook -i inventory.ini playbooks/update_control_plane.yml

# With reboot (only during maintenance windows)
ansible-playbook -i inventory.ini playbooks/update_control_plane.yml \
  --extra-vars "reboot_after_update=yes"
```

## 🔒 Bastion Host Tunneling

The setup uses SSH ProxyCommand for secure access to private subnet VMs through a bastion host.

### How It Works

1. **Bastion Host**: Public-facing EC2 instance in public subnet
2. **Private VMs**: EC2 instances in private subnets without direct public IPs
3. **SSH Tunnel**: Ansible creates SSH tunnel through bastion to reach private VMs

### Configuration

The tunnel is configured in `group_vars/private_vms.yml`:

```yaml
ansible_ssh_common_args: >
  -o ProxyCommand="ssh -W %h:%p
  -i ~/.ssh/adnsg-aws-ai-platform.pem
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  {{ bastion_user }}@{{ hostvars['bastion']['ansible_host'] }}"
```

### Testing Tunnel

```bash
# Test SSH to private VM via bastion
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem \
  -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>" \
  ec2-user@<PRIVATE_VM_IP>
```

## 🔧 Role-Based Organization

### `common_updates` Role

Handles OS-level updates for all Linux distributions.

**Tasks:**

- Update package manager cache
- Install OS updates (full or security-only)
- Install common utilities
- Reboot if necessary
- Log update activities

**Variables:**

```yaml
update_packages: yes
update_security_only: no
reboot_after_update: no
enable_update_logging: yes
log_directory: /var/log/updates
```

**Usage in playbooks:**

```yaml
roles:
  - common_updates
```

### `gpu_updates` Role

Handles GPU driver and CUDA toolkit installation.

**Tasks:**

- Install GPU prerequisites (kernel headers, gcc, dkms)
- Install NVIDIA GPU drivers
- Install CUDA toolkit
- Configure CUDA environment variables
- Verify GPU installation
- Reboot after driver installation

**Variables:**

```yaml
update_gpu_drivers: yes
nvidia_driver_version: "latest"
cuda_version: "12.4"
install_cuda_toolkit: yes
gpu_reboot_after_driver_update: yes
```

**Usage in playbooks:**

```yaml
roles:
  - gpu_updates
```

## 📊 Host Groups

The inventory defines several host groups for targeted operations:

- **`bastion`**: Public-facing bastion host (direct access)
- **`private_vms`**: All VMs in private subnets (via tunnel)
- **`control_plane`**: SLURM controller, K8s control plane
- **`compute_nodes`**: GPU nodes
- **`workers`**: CPU worker nodes
- **`gpu_nodes`**: All GPU-enabled nodes

**Example - Run on specific group:**

```bash
# Update only GPU nodes
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml \
  -l gpu_nodes

# Run only on control plane
ansible-playbook -i inventory.ini playbooks/update_control_plane.yml \
  -l control_plane
```

## 📝 Variables and Overrides

### Global Variables (`group_vars/all.yml`)

```yaml
update_packages: yes
reboot_after_update: no
auto_reboot_wait_timeout: 300
ssh_key_path: ~/.ssh/adnsg-aws-ai-platform.pem
log_directory: /var/log/updates
```

### GPU-Specific Variables (`group_vars/gpu_nodes.yml`)

```yaml
update_gpu_drivers: yes
nvidia_driver_version: "latest"
cuda_version: "12.4"
gpu_reboot_after_driver_update: yes
```

### Override Variables via Command Line

```bash
# Override single variable
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "reboot_after_update=yes"

# Override multiple variables
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml \
  --extra-vars "nvidia_driver_version=550.54.14 cuda_version=12.4 gpu_reboot_after_driver_update=yes"

# Load from JSON file
echo '{"reboot_after_update": true}' > overrides.json
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "@overrides.json"
```

## 🛠️ Reusable Components

### Using Roles in Other Projects

The roles are modular and can be reused in other projects:

```yaml
# your-playbook.yml
---
- name: Update systems in your project
  hosts: your_servers
  roles:
    - /path/to/aws-ai-platform/ansible/roles/common_updates
    - /path/to/aws-ai-platform/ansible/roles/gpu_updates
```

Or copy roles to your project:

```bash
cp -r ansible/roles/common_updates ../your-project/roles/
cp -r ansible/roles/gpu_updates ../your-project/roles/
```

### Bastion Configuration Template

Use the bastion tunnel setup for other projects:

```yaml
# group_vars/private_vms.yml in your project
ansible_ssh_common_args: >
  -o ProxyCommand="ssh -W %h:%p
  -i /path/to/ssh-key.pem
  -o StrictHostKeyChecking=no
  {{ bastion_user }}@{{ hostvars['bastion']['ansible_host'] }}"
```

## 🔍 Debugging and Troubleshooting

### Connectivity Issues

```bash
# Test SSH to bastion
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>

# Test SSH to private VM
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem \
  -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>" \
  ec2-user@<PRIVATE_IP>

# Verbose SSH for debugging
ssh -vvv -i ~/.ssh/adnsg-aws-ai-platform.pem \
  -o ProxyCommand="ssh -vvv -W %h:%p -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>" \
  ec2-user@<PRIVATE_IP>
```

### Ansible Debugging

```bash
# Very verbose output
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -vvv

# Show task details
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -v

# Syntax check
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --syntax-check

# List tasks without running
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --list-tasks

# Run specific tag only
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -t package-update
```

### GPU Verification

```bash
# SSH to GPU node
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem \
  -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>" \
  ec2-user@<GPU_NODE_IP>

# Check GPU status
nvidia-smi

# Check CUDA version
nvcc --version

# List GPUs
nvidia-smi --query-gpu=index,name,driver_version --format=csv
```

## 📋 Update Logs

Update logs are stored in `/var/log/updates/` on each host:

```bash
# View update logs on a host
ansible -i inventory.ini gpu-node-1 -m command \
  -a "ls -la /var/log/updates/"

# Copy logs from host
ansible -i inventory.ini gpu-node-1 -m fetch \
  -a "src=/var/log/updates/ dest=./logs/gpu-node-1"
```

## 🔄 Scheduling Regular Updates

### Cron-based Updates

Create a cron job for regular updates:

```bash
# Run monthly updates on first Sunday at 2 AM
0 2 * * 0 cd /path/to/ansible && ansible-playbook -i inventory.ini playbooks/update_all_systems.yml

# Add to crontab
crontab -e
# Add line: 0 2 * * 0 /path/to/run-updates.sh
```

### Wrapper Script

Create `run-updates.sh`:

```bash
#!/bin/bash
cd /path/to/aws-ai-platform/ansible
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "reboot_after_update=no" \
  | tee /var/log/ansible-updates.log
```

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
- [SSH ProxyCommand](https://docs.ansible.com/ansible/latest/user_guide/connection_details.html)
- [NVIDIA Driver Installation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- [CUDA Installation](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/)

## ⚠️ Important Notes

1. **Bastion Access**: Ensure bastion host is accessible before running playbooks on private VMs
2. **SSH Key Permissions**: SSH key should have 600 permissions: `chmod 600 ~/.ssh/adnsg-aws-ai-platform.pem`
3. **Testing**: Always use `--check` (dry-run) flag for critical systems before applying updates
4. **Reboot Timing**: Schedule reboots during maintenance windows, especially for control plane nodes
5. **Backup**: Ensure VMs have snapshots before major updates
6. **Security**: Keep SSH keys secure and rotate regularly

---

Last Updated: March 2026
