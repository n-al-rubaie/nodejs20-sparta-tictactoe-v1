cat > scripts/deploy_db.sh <<'EOF'
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y gnupg curl

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg --batch --yes -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update -y
sudo apt-get install -y mongodb-org

sudo sed -i 's/^\(\s*bindIp:\s*\)127\.0\.0\.1/\10.0.0.0/' /etc/mongod.conf

sudo systemctl enable mongod
sudo systemctl restart mongod
sleep 3
sudo systemctl is-active mongod
grep bindIp /etc/mongod.conf
EOF
