#!/bin/bash
set -e

echo "🚀 Starting deployment..."

# Base directories
BASE_DIR="/opt/mb-final"
FRONTEND_DIR="/var/www/mindbridge"

# Backend
if [ -f "$BASE_DIR/docker-compose.yml" ]; then
    echo "🔄 Updating backend..."
    cd "$BASE_DIR"
    docker-compose pull
    docker-compose up -d
fi

# Frontend
if [ -d "$BASE_DIR/.output/public" ]; then
    echo "🖥️  Updating frontend..."
    mkdir -p "$FRONTEND_DIR"
    rsync -a --delete "$BASE_DIR/.output/public/" "$FRONTEND_DIR/"
    chown -R www-data:www-data "$FRONTEND_DIR"
fi

# Nginx
if [ -f "$BASE_DIR/nginx/mindbridge.conf" ]; then
    echo "🔧 Updating Nginx config..."
    cp "$BASE_DIR/nginx/mindbridge.conf" /etc/nginx/sites-available/mindbridge
    ln -sf /etc/nginx/sites-available/mindbridge /etc/nginx/sites-enabled/
    
    # Remove default config if it exists
    [ -f "/etc/nginx/sites-enabled/default" ] && rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    if nginx -t; then
        systemctl reload nginx
        echo "🔄 Nginx reloaded successfully"
    else
        echo "❌ Nginx configuration test failed"
        exit 1
    fi
fi

echo "✅ Deployment complete!"
