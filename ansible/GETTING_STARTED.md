# Ansible Setup - Getting Started Guide

Complete step-by-step guide to set up Ansible for managing your AWS AI Platform infrastructure.

## 📋 Prerequisites

- Ansible 2.9+ installed on your management machine
- SSH access to bastion host
- SSH key file: `~/.ssh/adnsg-aws-ai-platform.pem`
- Terraform outputs available
- AWS infrastructure deployed

## 🔧 Installation

### 1. Install Ansible

**macOS:**
```bash
brew install ansible
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

**Linux (RHEL/CentOS):**
```bash
sudo yum install ansible
```

**Verify Installation:**
```bash
ansible --version
```

### 2. Verify SSH Key Setup

```bash
# Check SSH key exists and has correct permissions
ls -la ~/.ssh/adnsg-aws-ai-platform.pem

# Fix permissions if needed (should be 600)
chmod 600 ~/.ssh/adnsg-aws-ai-platform.pem

# Test SSH key access
ssh-keygen -y -f ~/.ssh/adnsg-aws-ai-platform.pem | head -c 20
# Should show: ssh-rsa AAAAB3NzaC1y...
```

## 🚀 Initial Setup (5 minutes)

### Step 1: Add Terraform Outputs

Add the following to `terraform/vm.tf` (see [TERRAFORM_OUTPUTS.tf](TERRAFORM_OUTPUTS.tf) for full list):

```terraform
output "bastion_public_ip" {
  value = module.bastion.instance_public_ip
}

output "slurm_controller_private_ip" {
  value = module.slurm_controller.instance_private_ip
}

# ... (add other outputs)
```

### Step 2: Generate Terraform Outputs

```bash
cd terraform
terraform apply  # If not already applied
terraform output
```

### Step 3: Generate Ansible Inventory

```bash
cd ../ansible
chmod +x scripts/generate_inventory_from_terraform.sh
./scripts/generate_inventory_from_terraform.sh
```

Expected output:
```
📝 Generating Ansible inventory from Terraform outputs...
✅ Inventory generated successfully!
📄 Location: ./inventory-dynamic.ini

📋 Inventory Summary:
   Bastion: 52.221.XXX.XXX
   SLURM Controller: 10.10.20.50
   ...
```

### Step 4: Update Static Inventory

The `inventory.ini` file is your working inventory. Update it with IPs from `inventory-dynamic.ini`:

**Option A: Manual Edit**
```bash
# Open and edit with your IPs
nano inventory.ini

# Example - replace these placeholders:
# <BASTION_PUBLIC_IP> with 52.221.XXX.XXX
# <SLURM_CONTROLLER_PRIVATE_IP> with 10.10.20.50
# etc.
```

**Option B: Automated Update**
```bash
# Using sed (macOS/Linux)
sed -i 's/<BASTION_PUBLIC_IP>/52.221.XXX.XXX/g' inventory.ini
sed -i 's/<SLURM_CONTROLLER_PRIVATE_IP>/10.10.20.50/g' inventory.ini
# ... repeat for other placeholders
```

**Reference Example:**
See [inventory-example.ini](inventory-example.ini) for a populated example

### Step 5: Verify Connectivity

```bash
# Test ping to all hosts
ansible -i inventory.ini all -m ping

# Expected output:
# bastion | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

If you see `FAILED - Permission denied`, check:
1. SSH key path is correct in `inventory.ini`
2. SSH key has correct permissions: `chmod 600`
3. EC2 instance security groups allow SSH (port 22)
4. EC2 instance is in a running state

## ✅ Verification Checklist

After setup, verify everything works:

```bash
# 1. Check inventory is valid
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --syntax-check
# Should output: "playbook loaded successfully"

# 2. List all hosts
ansible -i inventory.ini all --list-hosts
# Should list all 6 hosts

# 3. Test bastion connectivity
ansible -i inventory.ini bastion -m ping
# Should return SUCCESS

# 4. Test private VM tunnel
ansible -i inventory.ini private_vms -m ping
# Should return SUCCESS for all private VMs

# 5. Get system facts
ansible -i inventory.ini all -m setup | head -20
# Should return system information
```

## 🎯 First Playbook Run

### Run in Check Mode (Dry-Run)

```bash
# Always run in check mode first to see what will happen
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --check

# Expected output shows what WOULD be changed, but nothing is actually changed
```

### Run the Update Playbook

```bash
# Update all systems (no reboot)
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml

# With reboot after update
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "reboot_after_update=yes"

# Verbose output for debugging
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -vv
```

### Monitor Execution

The playbook will:
1. Display pre-update system information
2. Update packages
3. Install common utilities
4. Optionally reboot
5. Display post-update status

Output example:
```
PLAY [Update all systems in the AI Platform]

TASK [Gathering Facts]
ok: [bastion]

TASK [common_updates : Display update information]
ok: [bastion] => {
    "msg": "Starting system updates on bastion..."
}

...

PLAY RECAP
bastion : ok=15 changed=5 unreachable=0 failed=0
```

## 🐛 Common Issues & Solutions

### Issue 1: Connection Refused (Port 22)

```
UNREACHABLE! => {
    "msg": "Failed to connect to the host via ssh: "
}
```

**Solution:**
```bash
# 1. Check instance is running in AWS Console
# 2. Check security group allows SSH (port 22)
# 3. Verify public/private IP is correct in inventory
# 4. Test SSH manually:
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<IP>
```

### Issue 2: Permission Denied (Publickey)

```
Permission denied (publickey)
```

**Solution:**
```bash
# Check SSH key path in inventory.ini
grep ssh_private_key_file inventory.ini

# Fix permissions on SSH key
chmod 600 ~/.ssh/adnsg-aws-ai-platform.pem

# Test SSH key works
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem -v ec2-user@<IP>
```

### Issue 3: Bastion Tunnel Fails

```
ssh: Could not resolve hostname
```

**Solution:**
```bash
# Verify bastion IP in inventory
grep "bastion ansible_host" inventory.ini

# Test bastion tunnel manually:
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem \
  -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>" \
  ec2-user@<PRIVATE_IP>

# If tunnel works, issue might be with ansible_ssh_common_args
```

### Issue 4: Ansible Not Found

```
-bash: ansible: command not found
```

**Solution:**
```bash
# Install Ansible
brew install ansible          # macOS
# or
sudo apt install ansible      # Linux

# Verify installation
which ansible
ansible --version
```

## 📚 Next Steps

After successful setup:

1. **Review Variables** - Customize defaults in `group_vars/`
2. **Test on Non-Prod** - Run on staging/dev first
3. **Schedule Updates** - Set up cron jobs for regular updates
4. **Monitor Logs** - Check `/var/log/updates/` on each host
5. **Document Changes** - Keep track of what was updated
6. **Create Snapshots** - Backup VMs before major updates

## 🔄 Regular Usage

### Daily/Weekly Updates

```bash
# Security updates only
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "update_security_only=yes"

# Full OS updates
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml
```

### Monthly GPU Driver Updates

```bash
# Update GPU drivers
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml

# Full GPU nodes update (OS + GPU + CUDA)
ansible-playbook -i inventory.ini playbooks/update_gpu_nodes_full.yml
```

### Critical Infrastructure Updates

```bash
# Check mode first (dry-run)
ansible-playbook -i inventory.ini playbooks/update_control_plane.yml --check

# Run with security updates only
ansible-playbook -i inventory.ini playbooks/update_control_plane.yml
```

## 📖 Documentation Reference

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Complete Ansible documentation |
| [INVENTORY.md](INVENTORY.md) | Inventory setup and management |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Common commands cheat sheet |
| [TERRAFORM_OUTPUTS.tf](TERRAFORM_OUTPUTS.tf) | Terraform outputs to add |

## 🆘 Getting Help

```bash
# List all available hosts
ansible -i inventory.ini all --list-hosts

# Check Ansible version
ansible --version

# Get detailed error messages
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -vvv

# Check Ansible configuration
cat ansible.cfg

# List all variables for a host
ansible -i inventory.ini bastion -m debug -a "var=hostvars[inventory_hostname]"
```

## ✨ Tips & Best Practices

1. **Always Run Check Mode First**: Test with `--check` before actual changes
2. **Use Verbose Output**: Add `-v` or `-vv` for more detailed information
3. **Keep Logs**: Check update logs: `ansible -i inventory.ini all -m shell -a "tail /var/log/updates/*"`
4. **Serial Updates**: Playbooks use `serial: 1` to prevent simultaneous updates
5. **Backup Before Major Updates**: Create VM snapshots before significant changes
6. **Version Control**: Keep `inventory.ini` and playbooks in git

---

## 📞 Support & Troubleshooting

For detailed troubleshooting, see [README.md - Debugging](README.md#debugging-and-troubleshooting)

**Quick Debug Steps:**
1. Check SSH access: `ssh -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<IP>`
2. Verify inventory: `ansible -i inventory.ini all --list-hosts`
3. Test connectivity: `ansible -i inventory.ini all -m ping`
4. Run in verbose mode: Add `-v`, `-vv`, or `-vvv`
5. Check logs: `/var/log/updates/` on each host

---

**Last Updated:** March 2026

**Ready to start?** Follow the "Initial Setup (5 minutes)" section above!
