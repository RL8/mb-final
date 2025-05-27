#!/bin/bash
set -e

echo "🚀 Starting deployment at $(date)"
echo "----------------------------------------"

# Base directories
BASE_DIR="/opt/mb-final"
FRONTEND_DIR="/var/www/mindbridge"
LOG_FILE="/var/log/mb-deploy-$(date +%Y%m%d-%H%M%S).log"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Start logging
echo "Starting deployment - Logging to $LOG_FILE"
log "Starting deployment process"

# Backend Deployment
if [ -f "$BASE_DIR/docker-compose.yml" ]; then
    log "🔄 Updating backend services..."
    cd "$BASE_DIR"
    
    # Pull latest images
    if docker-compose pull; then
        log "✅ Successfully pulled Docker images"
    else
        log "⚠️  Warning: Failed to pull some Docker images. Continuing with existing images."
    fi
    
    # Start containers
    if docker-compose up -d; then
        log "✅ Backend services started successfully"
    else
        log "❌ Failed to start backend services"
        exit 1
    fi
    
    # Verify containers are running
    if [ "$(docker-compose ps --services --filter "status=running" | wc -l)" -gt 0 ]; then
        log "✅ All backend containers are running"
    else
        log "❌ Some backend containers failed to start"
        docker-compose ps
        exit 1
    fi
else
    log "ℹ️  No docker-compose.yml found, skipping backend update"
fi

# Frontend Deployment
if [ -d "$BASE_DIR/.output/public" ]; then
    log "🖥️  Updating frontend files..."
    
    # Create frontend directory if it doesn't exist
    mkdir -p "$FRONTEND_DIR"
    
    # Backup current frontend (optional, remove if not needed)
    BACKUP_DIR="/var/backups/mindbridge-frontend-$(date +%Y%m%d-%H%M%S)"
    if [ "$(ls -A $FRONTEND_DIR)" ]; then
        log "💾 Creating backup of current frontend at $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        cp -r "$FRONTEND_DIR/"* "$BACKUP_DIR/"
    fi
    
    # Sync new frontend files
    if rsync -a --delete "$BASE_DIR/.output/public/" "$FRONTEND_DIR/"; then
        log "✅ Frontend files updated successfully"
    else
        log "❌ Failed to update frontend files"
        exit 1
    fi
    
    # Set correct permissions
    chown -R www-data:www-data "$FRONTEND_DIR"
    find "$FRONTEND_DIR" -type d -exec chmod 755 {} \;
    find "$FRONTEND_DIR" -type f -exec chmod 644 {} \;
    log "✅ Set correct permissions for frontend files"
else
    log "ℹ️  No frontend build found, skipping frontend update"
fi

# Nginx Configuration
if [ -f "$BASE_DIR/nginx/mindbridge.conf" ]; then
    log "🔧 Updating Nginx configuration..."
    
    # Backup current Nginx config
    NGINX_BACKUP_DIR="/etc/nginx/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$NGINX_BACKUP_DIR"
    
    # Backup existing configs
    log "💾 Backing up current Nginx configuration to $NGINX_BACKUP_DIR"
    [ -d "/etc/nginx/conf.d" ] && cp -r /etc/nginx/conf.d/ "$NGINX_BACKUP_DIR/"
    [ -d "/etc/nginx/sites-available" ] && cp -r /etc/nginx/sites-available/ "$NGINX_BACKUP_DIR/"
    [ -d "/etc/nginx/sites-enabled" ] && cp -r /etc/nginx/sites-enabled/ "$NGINX_BACKUP_DIR/"
    
    # Clean up old configs
    log "🧹 Cleaning up old Nginx configurations..."
    rm -f /etc/nginx/sites-enabled/*
    rm -f /etc/nginx/conf.d/*.conf
    
    # Create necessary directories
    mkdir -p /etc/nginx/{sites-available,sites-enabled,conf.d}
    
    # Deploy new config
    log "📋 Installing new Nginx configuration..."
    cp "$BASE_DIR/nginx/mindbridge.conf" /etc/nginx/conf.d/mindbridge.conf
    cp "$BASE_DIR/nginx/mindbridge.conf" /etc/nginx/sites-available/mindbridge
    ln -sf /etc/nginx/sites-available/mindbridge /etc/nginx/sites-enabled/
    
    # Test configuration
    log "🔍 Testing Nginx configuration..."
    if nginx -t; then
        log "✅ Nginx configuration test passed"
        
        # Reload Nginx
        if systemctl reload nginx; then
            log "🔄 Nginx reloaded successfully"
        else
            log "❌ Failed to reload Nginx"
            systemctl status nginx --no-pager | tee -a "$LOG_FILE"
            exit 1
        fi
    else
        log "❌ Nginx configuration test failed"
        log "Current Nginx configuration files:"
        find /etc/nginx -type f -name "*.conf" | while read -r conf; do
            log "\n=== $conf ==="
            cat "$conf" | tee -a "$LOG_FILE"
        done
        exit 1
    fi
else
    log "ℹ️  No Nginx configuration found, skipping Nginx update"
fi

# Final status check
log "\n📊 Deployment Summary:"
log "- Backend services: $(docker-compose ps --services --filter "status=running" | wc -l) running"
log "- Frontend directory: $FRONTEND_DIR ($(du -sh "$FRONTEND_DIR" | cut -f1))"
log "- Nginx status: $(systemctl is-active nginx)"

log "\n✅ Deployment completed successfully at $(date)"
echo "✅ Deployment complete! See $LOG_FILE for details"
