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
    
    # Clean up old configs - be more aggressive
    log "🧹 Cleaning up old Nginx configurations..."
    # Remove all symlinks in sites-enabled
    find /etc/nginx/sites-enabled/ -type l -delete 2>/dev/null || true
    # Remove all .conf files in conf.d
    rm -f /etc/nginx/conf.d/*.conf 2>/dev/null || true
    # Remove default config if it exists
    [ -f "/etc/nginx/sites-available/default" ] && rm -f /etc/nginx/sites-available/default
    [ -f "/etc/nginx/sites-enabled/default" ] && rm -f /etc/nginx/sites-enabled/default
    
    # Create necessary directories with correct permissions
    mkdir -p /etc/nginx/{sites-available,sites-enabled,conf.d}
    chmod 755 /etc/nginx/{sites-available,sites-enabled,conf.d}
    
    # Deploy new config
    log "📋 Installing new Nginx configuration..."
    # Only deploy to conf.d for simplicity
    cp "$BASE_DIR/nginx/mindbridge.conf" /etc/nginx/conf.d/mindbridge.conf
    chmod 644 /etc/nginx/conf.d/mindbridge.conf
    
    # Test configuration
    log "🔍 Testing Nginx configuration..."
    if nginx -t 2>>"$LOG_FILE"; then
        log "✅ Nginx configuration test passed"
        
        # Check if Nginx is running
        if systemctl is-active --quiet nginx; then
            log "🔄 Nginx is running, attempting to reload..."
            if ! systemctl reload nginx 2>>"$LOG_FILE"; then
                log "❌ Failed to reload Nginx"
                systemctl status nginx --no-pager -l | tee -a "$LOG_FILE"
                exit 1
            fi
        else
            log "🔄 Nginx is not running, attempting to start..."
            if ! systemctl start nginx 2>>"$LOG_FILE"; then
                log "❌ Failed to start Nginx"
                systemctl status nginx --no-pager -l | tee -a "$LOG_FILE"
                exit 1
            fi
        fi
        
        # Verify Nginx is running after start/reload
        if systemctl is-active --quiet nginx; then
            log "✅ Nginx is now active and running"
            # Show listening ports to confirm Nginx is bound correctly
            log "🌐 Nginx is listening on:"
            ss -tulpn | grep nginx || true
        else
            log "❌ Nginx failed to start after configuration"
            systemctl status nginx --no-pager -l | tee -a "$LOG_FILE"
            exit 1
        fi
    else
        log "❌ Nginx configuration test failed"
        log "=== Nginx Configuration Test Output ==="
        nginx -T 2>&1 | tee -a "$LOG_FILE"
        log "=== End of Nginx Configuration Test Output ==="
        
        # Show the last 20 lines of the error log for more context
        if [ -f "/var/log/nginx/error.log" ]; then
            log "=== Last 20 lines of Nginx error log ==="
            tail -n 20 /var/log/nginx/error.log | tee -a "$LOG_FILE"
        fi
        
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
