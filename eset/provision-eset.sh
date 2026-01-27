#!/bin/bash
# Post-deployment script to install ESET on Ubuntu server

set -e

UBUNTU_HOST="10.2.10.10"
SSH_USER="debian"

echo "Connecting to Ubuntu ESET server at ${UBUNTU_HOST}..."

# Upload and execute the installation script
ssh -o StrictHostKeyChecking=no ${SSH_USER}@${UBUNTU_HOST} << 'ENDSSH'
export MYSQL_ROOT_PASSWORD="StrongRootPass!2024"
export ESET_ADMIN_PASSWORD="EsetAdminPass!2024"
export DB_USER_USERNAME="era_user"
export DB_USER_PASSWORD="StrongDbPass!2024"

curl -fsSL https://raw.githubusercontent.com/rwgb/eset.epop.tools/dev/scripts/linux/install-eset.sh | sudo -E bash
ENDSSH

echo "ESET installation complete!"
echo "Access ESET Web Console at: https://${UBUNTU_HOST}:8443/era"
echo "Username: Administrator"
echo "Password: EsetAdminPass!2024"
