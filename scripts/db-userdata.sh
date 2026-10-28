#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y gnupg curl

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  gpg --batch --yes -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

CODENAME=noble
if ! curl -fsI "https://repo.mongodb.org/apt/ubuntu/dists/${CODENAME}/mongodb-org/7.0/Release" >/dev/null; then
  CODENAME=jammy
fi
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${CODENAME}/mongodb-org/7.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-7.0.list

apt-get update -y
apt-get install -y mongodb-org

sed -i 's/^\(\s*bindIp:\s*\)127\.0\.0\.1/\10.0.0.0/' /etc/mongod.conf

systemctl enable mongod
systemctl restart mongod
EOF
