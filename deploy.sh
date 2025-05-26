#!/bin/bash

# Exit on error
set -e

echo "Starting deployment process..."

# Check if Node.js is installed, if not install it
if ! command -v node &> /dev/null; then
  echo "Node.js not found, installing..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
  echo "Node.js installed: $(node -v)"
  echo "NPM installed: $(npm -v)"
fi

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Build the Nuxt application
echo "Building the application..."
npm run build

# Create frontend directory in nginx
echo "Setting up Nginx directory..."
mkdir -p /var/www/mindbridge

# Copy the built files to Nginx directory
echo "Copying built files to Nginx..."
cp -r .output/public/* /var/www/mindbridge/

# Create Nginx config for the frontend
echo "Configuring Nginx for frontend..."
cat > /etc/nginx/sites-available/mindbridge << EOL
server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        root /var/www/mindbridge;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Enable the site
ln -sf /etc/nginx/sites-available/mindbridge /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
echo "Testing Nginx configuration..."
nginx -t

echo "Restarting Nginx..."
systemctl restart nginx

echo "Deployment complete! The application should now be accessible via the droplet's IP address."
