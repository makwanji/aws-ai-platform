# Ansible Quick Reference Guide

## 🚀 One-Minute Setup

```bash
# 1. Generate inventory from Terraform
cd ansible
chmod +x scripts/*.sh
./scripts/generate_inventory_from_terraform.sh

# 2. Update inventory.ini with IPs
# (copy IPs from inventory-dynamic.ini)

# 3. Test connectivity
./scripts/test_bastion_connectivity.sh

# 4. Run playbook
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml
```

## 📋 Common Commands

### Inventory Management

```bash
# List all hosts
ansible -i inventory.ini all --list-hosts

# List GPU nodes
ansible -i inventory.ini gpu_nodes --list-hosts

# Test connectivity
ansible -i inventory.ini all -m ping
```

### Playbook Execution

```bash
# Dry-run (check mode)
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --check

# Run with verbose output
ansible -i inventory.ini playbooks/update_all_systems.yml -vv

# Run specific tags
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -t package-update

# Run on specific hosts
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml -l bastion

# Run with reboot enabled
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml \
  --extra-vars "reboot_after_update=yes"
```

### GPU Node Updates

```bash
# Update GPU drivers only
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml

# Update with specific NVIDIA driver version
ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml \
  --extra-vars "nvidia_driver_version=550.54.14"

# Full update (OS + GPU + CUDA)
ansible-playbook -i inventory.ini playbooks/update_gpu_nodes_full.yml
```

### Private VM Updates

```bash
# Update via bastion tunnel
ansible-playbook -i inventory.ini playbooks/update_private_vms.yml

# Update control plane
ansible-playbook -i inventory.ini playbooks/update_control_plane.yml
```

## 📊 Playbook Selection Guide

| Scenario | Playbook | Command |
|----------|----------|---------|
| Update all VMs (OS only) | `update_all_systems.yml` | `ansible-playbook -i inventory.ini playbooks/update_all_systems.yml` |
| Update GPU nodes (drivers) | `update_gpu_drivers.yml` | `ansible-playbook -i inventory.ini playbooks/update_gpu_drivers.yml` |
| Full GPU node update | `update_gpu_nodes_full.yml` | `ansible-playbook -i inventory.ini playbooks/update_gpu_nodes_full.yml` |
| Update private VMs | `update_private_vms.yml` | `ansible-playbook -i inventory.ini playbooks/update_private_vms.yml` |
| Update control plane | `update_control_plane.yml` | `ansible-playbook -i inventory.ini playbooks/update_control_plane.yml` |

## 🔧 Variable Overrides

```bash
# Single variable
--extra-vars "reboot_after_update=yes"

# Multiple variables
--extra-vars "reboot_after_update=yes cuda_version=12.4"

# From JSON file
--extra-vars "@vars.json"

# From environment variable
--extra-vars "env_var=$MY_VAR"
```

## 🔍 Debugging Commands

```bash
# Check syntax
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --syntax-check

# List all tasks
ansible-playbook -i inventory.ini playbooks/update_all_systems.yml --list-tasks

# Get host facts
ansible -i inventory.ini gpu-node-1 -m setup

# Run ad-hoc command
ansible -i inventory.ini all -m shell -a "uptime"

# View variable values
ansible -i inventory.ini gpu-node-1 -m debug -a "var=ansible_os_family"
```

## 🔐 SSH & Bastion Tunneling

```bash
# SSH to bastion
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>

# SSH to private VM via bastion
ssh -i ~/.ssh/adnsg-aws-ai-platform.pem \
  -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/adnsg-aws-ai-platform.pem ec2-user@<BASTION_IP>" \
  ec2-user@<PRIVATE_IP>

# Test tunnel connectivity
./scripts/test_bastion_connectivity.sh
```

## ✅ Pre-Playbook Checklist

- [ ] SSH key available: `~/.ssh/adnsg-aws-ai-platform.pem`
- [ ] SSH key permissions correct: `chmod 600`
- [ ] Inventory file populated: `ansible/inventory.ini`
- [ ] Bastion host accessible
- [ ] Running in check mode first (if new): `--check`
- [ ] Backup/snapshots created (if prod)

## ⚠️ Important Notes

1. **Security Updates Only**: Use `--extra-vars "update_security_only=yes"`
2. **Control Plane**: Always use `--check` first on critical nodes
3. **GPU Reboot**: GPU playbooks auto-reboot after driver install
4. **Serial Updates**: Most playbooks use `serial: 1` to maintain availability
5. **Logs**: Stored in `/var/log/updates/` on each host

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection refused | Check bastion is running, SSH key path correct |
| Inventory not found | Specify full path: `-i /full/path/to/inventory.ini` |
| Host unreachable | Verify host IPs in inventory, test with `ansible all -m ping` |
| SSH key rejected | Check key permissions: `chmod 600 ~/.ssh/adnsg-aws-ai-platform.pem` |
| Python not found | May need python interpreter set in inventory |
| Bastion tunnel fails | Test: `ssh -v -W <PRIVATE_IP>:22 ec2-user@<BASTION_IP>` |

## 🔗 Useful Links

- Full Documentation: [README.md](README.md)
- Inventory Setup: [INVENTORY.md](INVENTORY.md)
- Ansible Docs: <https://docs.ansible.com/>
- Bastion SSH: <https://docs.ansible.com/ansible/latest/user_guide/connection_details.html>

---

For detailed information, see [README.md](README.md) and [INVENTORY.md](INVENTORY.md)
