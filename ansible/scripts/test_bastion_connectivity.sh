#!/bin/bash
# Script: test_bastion_connectivity.sh
# Purpose: Test SSH connectivity through bastion host
# Usage: ./test_bastion_connectivity.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${SCRIPT_DIR}/.."
SSH_KEY="${HOME}/.ssh/adnsg-aws-ai-platform.pem"

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH key not found at $SSH_KEY"
    exit 1
fi

# Source inventory
if [ -f "${ANSIBLE_DIR}/inventory-dynamic.ini" ]; then
    INVENTORY="${ANSIBLE_DIR}/inventory-dynamic.ini"
elif [ -f "${ANSIBLE_DIR}/inventory.ini" ]; then
    INVENTORY="${ANSIBLE_DIR}/inventory.ini"
else
    echo "❌ Inventory file not found"
    exit 1
fi

echo "🔍 Testing connectivity..."
echo ""

# Parse inventory to get IPs
BASTION_IP=$(grep -A 1 "^\[bastion\]" "$INVENTORY" | grep ansible_host | awk '{print $2}' | cut -d= -f2)

if [ -z "$BASTION_IP" ]; then
    echo "❌ Could not find bastion IP in inventory"
    exit 1
fi

echo "📡 Bastion Host: $BASTION_IP"
echo ""

# Test SSH connectivity to bastion
echo "🧪 Testing SSH connection to bastion..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$BASTION_IP" "echo '✅ Bastion connectivity OK'" 2>/dev/null; then
    echo "✅ Bastion connection successful"
else
    echo "❌ Failed to connect to bastion"
    exit 1
fi

echo ""
echo "🧪 Testing ProxyCommand connectivity to private VMs..."

# Get private VM IPs from inventory
PRIVATE_VMS=$(grep -E "^\s*[a-z].*-.*ansible_host=" "$INVENTORY" | grep -v "bastion" | head -5)

if [ -z "$PRIVATE_VMS" ]; then
    echo "⚠️  No private VMs found in inventory"
    exit 0
fi

# Test connectivity via bastion tunnel
while IFS= read -r line; do
    HOST_NAME=$(echo "$line" | awk '{print $1}')
    HOST_IP=$(echo "$line" | awk '{print $2}' | cut -d= -f2)

    if [ -n "$HOST_IP" ]; then
        echo ""
        echo "🔗 Testing connection to $HOST_NAME ($HOST_IP) via bastion..."
        if ssh -o ConnectTimeout=10 \
                -o ProxyCommand="ssh -W %h:%p -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$BASTION_IP" \
                -o StrictHostKeyChecking=no \
                -i "$SSH_KEY" \
                ec2-user@"$HOST_IP" "echo '✅ Connection to $HOST_NAME OK'" 2>/dev/null; then
            echo "✅ Connection to $HOST_NAME successful"
        else
            echo "⚠️  Could not connect to $HOST_NAME (this may be normal if host is not ready)"
        fi
    fi
done <<< "$PRIVATE_VMS"

echo ""
echo "✅ Connectivity tests completed!"
