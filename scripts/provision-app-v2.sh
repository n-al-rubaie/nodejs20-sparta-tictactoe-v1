#!/bin/bash
set -euo pipefail

DB_PRIVATE_IP="${1:?Usage: ./provision-app-v2.sh <db-private-ip>}"

REPO_URL="https://github.com/n-al-rubaie/nodejs20-sparta-tictactoe-v1.git"
APP_DIR="/home/ubuntu/app"
APP_NAME="tic-tac-toe"
NGINX_CONFIG="/etc/nginx/sites-available/tic-tac-toe"

# Tell the app where the DB is
export MONGODB_URI="mongodb://${DB_PRIVATE_IP}:27017/tictactoe"
export STATEFUL_MODE="server"
sudo sed -i '/^MONGODB_URI=/d;/^STATEFUL_MODE=/d' /etc/environment
echo "MONGODB_URI=${MONGODB_URI}" | sudo tee -a /etc/environment >/dev/null
echo "STATEFUL_MODE=${STATEFUL_MODE}" | sudo tee -a /etc/environment >/dev/null

sudo apt-get update -y
sudo apt-get install -y git nginx

if [ -d "$APP_DIR/.git" ]; then
  cd "$APP_DIR" && git pull origin main
else
  git clone "$REPO_URL" "$APP_DIR"
fi

# npm install also runs the seed script (postinstall)
cd "$APP_DIR"
npm install

command -v pm2 >/dev/null || sudo npm install -g pm2
pm2 delete "$APP_NAME" 2>/dev/null || true
pm2 start npm --name "$APP_NAME" --update-env -- start
pm2 save

sudo tee "$NGINX_CONFIG" >/dev/null <<'EOF'
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
sudo ln -sfn "$NGINX_CONFIG" /etc/nginx/sites-enabled/tic-tac-toe
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl reload nginx

pm2 status
