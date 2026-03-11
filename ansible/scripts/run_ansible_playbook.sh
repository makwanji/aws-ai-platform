#!/bin/bash
# Script: run_ansible_playbook.sh
# Purpose: Convenient wrapper for running Ansible playbooks with common options
# Usage: ./run_ansible_playbook.sh update_all_systems
# Usage: ./run_ansible_playbook.sh update_gpu_drivers --reboot
# Usage: ./run_ansible_playbook.sh update_control_plane --dry-run

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${SCRIPT_DIR}/.."

# Check if playbook name provided
if [ -z "$1" ]; then
    echo "❌ Playbook name not provided"
    echo ""
    echo "Available playbooks:"
    echo "  - update_all_systems"
    echo "  - update_gpu_drivers"
    echo "  - update_gpu_nodes_full"
    echo "  - update_private_vms"
    echo "  - update_control_plane"
    echo ""
    echo "Usage: $0 <playbook_name> [--reboot] [--dry-run] [--verbose]"
    exit 1
fi

PLAYBOOK_NAME="$1"
PLAYBOOK_FILE="${ANSIBLE_DIR}/playbooks/${PLAYBOOK_NAME}.yml"

# Check if playbook exists
if [ ! -f "$PLAYBOOK_FILE" ]; then
    echo "❌ Playbook not found: $PLAYBOOK_FILE"
    exit 1
fi

# Build ansible-playbook command
CMD="ansible-playbook -i ${ANSIBLE_DIR}/inventory.ini $PLAYBOOK_FILE"

# Parse additional arguments
for arg in "${@:2}"; do
    case "$arg" in
        --reboot)
            CMD="$CMD --extra-vars 'reboot_after_update=yes'"
            echo "🔄 Reboot enabled"
            ;;
        --dry-run)
            CMD="$CMD --check"
            echo "🧪 Running in check/dry-run mode"
            ;;
        --verbose)
            CMD="$CMD -vv"
            echo "📢 Verbose output enabled"
            ;;
        *)
            echo "⚠️  Unknown option: $arg"
            ;;
    esac
done

echo "🚀 Running Ansible playbook..."
echo "📄 Playbook: $PLAYBOOK_NAME"
echo ""

# Run the playbook
eval "$CMD"

echo ""
echo "✅ Playbook execution completed"
