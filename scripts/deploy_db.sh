#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y gnupg curl

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg --batch --yes -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

# Use the noble repo if it exists, otherwise jammy (works on 24.04 too)
CODENAME=noble
if ! curl -fsI "https://repo.mongodb.org/apt/ubuntu/dists/${CODENAME}/mongodb-org/7.0/Release" >/dev/null; then
  CODENAME=jammy
fi
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${CODENAME}/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update -y
sudo apt-get install -y mongodb-org

sudo sed -i 's/^\(\s*bindIp:\s*\)127\.0\.0\.1/\10.0.0.0/' /etc/mongod.conf

sudo systemctl enable mongod
sudo systemctl restart mongod
sleep 5
sudo systemctl is-active mongod
grep bindIp /etc/mongod.conf
EOF
