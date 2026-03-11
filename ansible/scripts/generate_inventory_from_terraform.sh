#!/bin/bash
# Script: generate_inventory_from_terraform.sh
# Purpose: Generate dynamic Ansible inventory from Terraform outputs
# Usage: ./generate_inventory_from_terraform.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
ANSIBLE_DIR="${SCRIPT_DIR}"
INVENTORY_FILE="${ANSIBLE_DIR}/inventory-dynamic.ini"

# Check if Terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "❌ Terraform directory not found at $TERRAFORM_DIR"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

echo "📝 Generating Ansible inventory from Terraform outputs..."

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Get Terraform outputs
BASTION_PUBLIC_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
SLURM_CONTROLLER_IP=$(terraform output -raw slurm_controller_private_ip 2>/dev/null || echo "")
K8S_CONTROL_PLANE_IP=$(terraform output -raw k8s_control_plane_private_ip 2>/dev/null || echo "")
GPU_NODE_1_IP=$(terraform output -raw gpu_node_1_private_ip 2>/dev/null || echo "")
GPU_NODE_2_IP=$(terraform output -raw gpu_node_2_private_ip 2>/dev/null || echo "")
CPU_WORKER_IP=$(terraform output -raw cpu_worker_private_ip 2>/dev/null || echo "")

# Validate we got the bastion IP
if [ -z "$BASTION_PUBLIC_IP" ]; then
    echo "❌ Could not retrieve bastion public IP from Terraform outputs"
    echo "📌 Ensure terraform outputs are defined in vm.tf"
    exit 1
fi

# Generate inventory file
cat > "$INVENTORY_FILE" << EOF
# Ansible Inventory - Generated from Terraform
# Generated: $(date)
# Source: Terraform outputs from $TERRAFORM_DIR

# Bastion host (public subnet, direct access)
[bastion]
bastion ansible_host=$BASTION_PUBLIC_IP ansible_user=ec2-user

# Private VMs accessed via bastion tunnel
[private_vms:children]
control_plane
compute_nodes
workers

# Control plane VMs
[control_plane]
slurm-controller ansible_host=$SLURM_CONTROLLER_IP ansible_user=ec2-user
k8s-control-plane ansible_host=$K8S_CONTROL_PLANE_IP ansible_user=ec2-user

# GPU compute nodes
[compute_nodes]
gpu-node-1 ansible_host=$GPU_NODE_1_IP ansible_user=ec2-user
gpu-node-2 ansible_host=$GPU_NODE_2_IP ansible_user=ec2-user

# CPU workers
[workers]
cpu-worker ansible_host=$CPU_WORKER_IP ansible_user=ec2-user

# GPU nodes for GPU-specific roles
[gpu_nodes]
gpu-node-1
gpu-node-2

# Group variables
[all:vars]
ansible_ssh_private_key_file=~/.ssh/adnsg-aws-ai-platform.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_connection_timeout=30
ansible_command_timeout=300
EOF

echo "✅ Inventory generated successfully!"
echo "📄 Location: $INVENTORY_FILE"
echo ""
echo "📋 Inventory Summary:"
echo "   Bastion: $BASTION_PUBLIC_IP"
echo "   SLURM Controller: $SLURM_CONTROLLER_IP"
echo "   K8s Control Plane: $K8S_CONTROL_PLANE_IP"
echo "   GPU Node 1: $GPU_NODE_1_IP"
echo "   GPU Node 2: $GPU_NODE_2_IP"
echo "   CPU Worker: $CPU_WORKER_IP"
echo ""
echo "🔗 Next steps:"
echo "   1. Update inventory.ini with IPs from inventory-dynamic.ini"
echo "   2. Run: ansible-playbook playbooks/update_all_systems.yml"
