#!/bin/bash
# Usage: bash add-agent.sh <agent-name>

NAME=${1:-"new-agent"}
PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)

KEY=$(printf "A\n${NAME}\nany\ny\nE\n001\nQ\n" | /var/ossec/bin/manage_agents 2>&1 \
  | grep -A1 "Agent key information" | tail -1 | tr -d ' ')

echo ""
echo "========================================="
echo " Agent: $NAME"
echo " Manager IP: $PUBLIC_IP"
echo ""
echo " Authentication key:"
echo " $KEY"
echo ""
echo " Paste this key into the Wazuh Agent GUI"
echo " on your Windows/Linux/macOS machine."
echo "========================================="
