# Deploys the Node.js application from a GitHub repository.
# Installs Git and Nginx if needed.
# Clones the repository or pulls the latest code from GitHub.
# Installs application dependencies using npm install.
# Installs PM2 if it is not already installed.
# Starts the application or restarts it if it is already running.
# Configures Nginx as a reverse proxy from port 80 to port 3000.
# Tests the Nginx configuration before reloading Nginx.
# Requires Node.js and npm to be installed beforehand.
# Purpose: Automated deployment using Git, npm, PM2 and Nginx.

#!/bin/bash
set -e # Tells Bash to stop the script when a command fails.

# Configuration
REPO_URL="https://github.com/n-al-rubaie/nodejs20-sparta-tictactoe-v1.git"
APP_DIR="/home/ubuntu/app"
APP_NAME="tic-tac-toe"
NGINX_CONFIG="/etc/nginx/sites-available/tic-tac-toe"

# 1. Install required packages
sudo apt-get update
sudo apt-get install -y git nginx

# 2. Get the application from GitHub
if [ -d "$APP_DIR/.git" ]; then
    cd "$APP_DIR"
    git pull origin main
else
    if [ -d "$APP_DIR" ] && [ -n "$(ls -A "$APP_DIR")" ]; then
        echo "Error: App directory exists but is not a Git repository."
        exit 1
    fi

    git clone "$REPO_URL" "$APP_DIR"
fi

# 3. Install application dependencies
cd "$APP_DIR"
npm install

# 4. Install PM2 if needed
if ! command -v pm2 >/dev/null 2>&1; then
    sudo npm install -g pm2
fi

# 5. Start or restart the application
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
    pm2 restart "$APP_NAME"
else
    pm2 start npm --name "$APP_NAME" -- start
fi

# Save the PM2 process list
pm2 save

# 6. Configure Nginx as a reverse proxy
sudo tee "$NGINX_CONFIG" > /dev/null <<'EOF'
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

# 7. Enable the application site in Nginx
sudo ln -sfn "$NGINX_CONFIG" /etc/nginx/sites-enabled/tic-tac-toe

# Disable the default welcome page if enabled
if [ -L /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

# 8. Test Nginx before reloading it
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl reload nginx

echo "Application and Nginx deployment complete."
pm2 status
