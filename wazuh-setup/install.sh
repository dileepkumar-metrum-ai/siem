#!/bin/bash
# Wazuh Stack Installer — manager + indexer + dashboard
# Tested on Ubuntu 24.04

set -e

PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)

echo "[1/6] Adding Wazuh repo..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH \
  | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list
apt-get update -q

echo "[2/6] Installing packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y wazuh-manager wazuh-indexer wazuh-dashboard

echo "[3/6] Generating certificates..."
curl -so wazuh-certs-tool.sh https://packages.wazuh.com/4.9/wazuh-certs-tool.sh
curl -so config.yml https://packages.wazuh.com/4.9/config.yml
sed -i "s/<indexer-node-ip>/127.0.0.1/g;
        s/<wazuh-manager-ip>/127.0.0.1/g;
        s/<dashboard-node-ip>/127.0.0.1/g" config.yml
bash wazuh-certs-tool.sh -A
CERTS=$(pwd)/wazuh-certificates

echo "[4/6] Installing certs..."
# Indexer
mkdir -p /etc/wazuh-indexer/certs
cp $CERTS/node-1.pem      /etc/wazuh-indexer/certs/indexer.pem
cp $CERTS/node-1-key.pem  /etc/wazuh-indexer/certs/indexer-key.pem
cp $CERTS/root-ca.pem     /etc/wazuh-indexer/certs/root-ca.pem
cp $CERTS/admin.pem       /etc/wazuh-indexer/certs/admin.pem
cp $CERTS/admin-key.pem   /etc/wazuh-indexer/certs/admin-key.pem
chmod 500 /etc/wazuh-indexer/certs && chmod 400 /etc/wazuh-indexer/certs/*
chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs

# Manager (filebeat path)
mkdir -p /etc/filebeat/certs
cp $CERTS/wazuh-1.pem      /etc/filebeat/certs/filebeat.pem
cp $CERTS/wazuh-1-key.pem  /etc/filebeat/certs/filebeat-key.pem
cp $CERTS/root-ca.pem      /etc/filebeat/certs/root-ca.pem
chmod 400 /etc/filebeat/certs/*

# Dashboard
mkdir -p /etc/wazuh-dashboard/certs
cp $CERTS/dashboard.pem      /etc/wazuh-dashboard/certs/dashboard.pem
cp $CERTS/dashboard-key.pem  /etc/wazuh-dashboard/certs/dashboard-key.pem
cp $CERTS/root-ca.pem        /etc/wazuh-dashboard/certs/root-ca.pem
chmod 500 /etc/wazuh-dashboard/certs && chmod 400 /etc/wazuh-dashboard/certs/*
chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs

echo "[5/6] Configuring services..."
# Fix indexer host in manager config
sed -i 's|<host>https://0.0.0.0:9200</host>|<host>https://127.0.0.1:9200</host>|' /var/ossec/etc/ossec.conf

# Fix inotify limit
echo 'fs.inotify.max_user_instances=512' >> /etc/sysctl.conf
sysctl -p

echo "[6/6] Starting services..."
systemctl enable wazuh-indexer wazuh-manager wazuh-dashboard
systemctl start wazuh-indexer
sleep 20
/usr/share/wazuh-indexer/bin/indexer-security-init.sh
sleep 5

# Add indexer credentials to manager keystore
echo 'admin' | /var/ossec/bin/wazuh-keystore -f indexer -k username
echo 'admin' | /var/ossec/bin/wazuh-keystore -f indexer -k password

systemctl start wazuh-manager
systemctl start wazuh-dashboard

echo ""
echo "========================================="
echo " Wazuh installed successfully!"
echo "========================================="
echo " Dashboard : https://$PUBLIC_IP"
echo " Username  : admin"
echo " Password  : admin"
echo ""
echo " To add a Windows agent, run:"
echo "   bash add-agent.sh <agent-name>"
echo "========================================="
