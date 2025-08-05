# Deployment Guide

## Overview

This guide covers the complete deployment process for the Whey Protein Price Comparison Platform, from local development to production deployment on self-hosted infrastructure.

## Prerequisites

### System Requirements
- **VPS**: 4GB RAM, 2 vCPU, 80GB SSD minimum
- **OS**: Ubuntu 22.04 LTS (recommended)
- **Network**: Static IP address, domain name configured
- **SSL**: Domain verification for Let's Encrypt certificates

### Required Software
- Docker 24.0+
- Docker Compose 2.20+
- Git 2.30+
- Make utility
- NGINX (for reverse proxy)

## Infrastructure Setup

### 1. VPS Provider Selection

**Recommended Providers**:
- **Hetzner Cloud**: CPX31 (€15.29/month) - Best price/performance
- **DigitalOcean**: 4GB Basic Droplet ($24/month) - Excellent documentation
- **Linode**: 4GB Shared ($24/month) - Reliable performance
- **Vultr**: 4GB High Performance ($24/month) - Global locations

**Minimum Specifications**:
```yaml
CPU: 2 vCPU
RAM: 4GB
Storage: 80GB SSD
Network: 1 Gbps
Location: Frankfurt/Singapore (for India latency)
```

### 2. Server Initial Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl wget git make unzip htop

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
docker --version
docker-compose --version
```

### 3. Security Hardening

```bash
# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Disable root login and configure SSH
sudo vim /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes

sudo systemctl restart ssh

# Set up automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Environment Configuration

### 1. Environment Variables

Create production environment file:
```bash
# /opt/proteinprices/.env.prod
NODE_ENV=production
GIN_MODE=release

# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=proteinprices
DB_USER=proteinprices
DB_PASSWORD=secure_random_password_here
DB_SSL_MODE=require

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=another_secure_password

# Application Configuration
API_PORT=8080
SCRAPER_INTERVAL=30m
LOG_LEVEL=info
METRICS_PORT=9090

# External Services
JAEGER_ENDPOINT=http://jaeger:14268/api/traces
PROMETHEUS_ENDPOINT=http://prometheus:9090

# MCP Server Configuration
MCP_PORT=8081
MCP_LOG_LEVEL=info
MCP_TIMEOUT=30s
MCP_MAX_CONNECTIONS=100

# Authentication Configuration
JWT_SECRET=very_long_random_jwt_secret_64_characters_minimum_for_security
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# OAuth Configuration
OAUTH_GOOGLE_CLIENT_ID=google_oauth_client_id_here
OAUTH_GOOGLE_CLIENT_SECRET=google_oauth_client_secret_here
OAUTH_GITHUB_CLIENT_ID=github_oauth_client_id_here
OAUTH_GITHUB_CLIENT_SECRET=github_oauth_client_secret_here
OAUTH_FACEBOOK_CLIENT_ID=facebook_oauth_client_id_here
OAUTH_FACEBOOK_CLIENT_SECRET=facebook_oauth_client_secret_here

# Encryption Configuration
ENCRYPTION_MASTER_KEY=32_byte_master_encryption_key_for_pii_data_protection
ENCRYPTION_KEY_ROTATION_DAYS=90

# GDPR Configuration
GDPR_DATA_RETENTION_DAYS=2555  # 7 years default
GDPR_EXPORT_EXPIRY_HOURS=72
GDPR_DELETION_DELAY_DAYS=30

# Email Configuration
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=sendgrid_api_key_here
FROM_EMAIL=noreply@proteinprices.com

# Notification Configuration
PUSH_NOTIFICATION_ENABLED=false
SMS_ENABLED=false
EMAIL_NOTIFICATIONS_ENABLED=true

# Rate Limiting Configuration
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PUBLIC_RPS=100
RATE_LIMIT_USER_RPS=1000
RATE_LIMIT_API_FREE_RPS=1000
RATE_LIMIT_API_DEVELOPER_RPS=10000
RATE_LIMIT_ADMIN_RPS=5000

# Scraping Configuration
SCRAPER_USER_AGENT=Mozilla/5.0 (compatible; ProteinPriceBot/1.0)
SCRAPER_TIMEOUT=30s
SCRAPER_RATE_LIMIT=2s

# SSL/TLS
SSL_CERT_PATH=/etc/letsencrypt/live/api.proteinprices.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/api.proteinprices.com/privkey.pem
```

### 2. Secrets Management

```bash
# Generate secure passwords
openssl rand -base64 32  # For database password
openssl rand -base64 32  # For Redis password  
openssl rand -base64 64  # For JWT secret

# Set proper permissions
sudo chmod 600 /opt/proteinprices/.env.prod
sudo chown root:docker /opt/proteinprices/.env.prod
```

## Application Deployment

### 1. Repository Setup

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/yourusername/whey-price-compare.git proteinprices
cd proteinprices

# Set up deployment user
sudo useradd -r -s /bin/false proteinprices
sudo chown -R proteinprices:proteinprices /opt/proteinprices
sudo usermod -aG docker proteinprices
```

### 2. Production Docker Compose

```yaml  
# docker-compose.prod.yml
version: '3.8'

services:
  api:
    build:
      context: .
      dockerfile: deployments/docker/Dockerfile.api
      target: production
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    environment:
      - NODE_ENV=production
      - GIN_MODE=release
    env_file:
      - .env.prod
    depends_on:
      - postgres
      - redis
    volumes:
      - ./logs:/app/logs
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
          cpus: '0.25'

  scraper:
    build:
      context: .
      dockerfile: deployments/docker/Dockerfile.scraper
      target: production
    restart: unless-stopped
    env_file:
      - .env.prod
    depends_on:
      - postgres
      - redis
    volumes:
      - ./logs:/app/logs
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.3'

  mcp:
    build:
      context: .
      dockerfile: deployments/docker/Dockerfile.mcp
      target: production
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:8081"
    environment:
      - MCP_PORT=8081
      - MCP_LOG_LEVEL=info
    env_file:
      - .env.prod
    depends_on:
      - api
      - postgres
      - redis
    volumes:
      - ./logs:/app/logs
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.2'

  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./deployments/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "127.0.0.1:5432:5432"
    command: >
      postgres
      -c max_connections=100
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c maintenance_work_mem=64MB
      -c checkpoint_completion_target=0.9
      -c wal_buffers=16MB
      -c default_statistics_target=100
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --appendonly yes
      --maxmemory 512mb
      --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    ports:
      - "127.0.0.1:6379:6379"
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'

  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:9090:9090"
    volumes:
      - ./deployments/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=90d'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'

  grafana:
    image: grafana/grafana-oss:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel
    volumes:
      - grafana_data:/var/lib/grafana
      - ./deployments/grafana/provisioning:/etc/grafana/provisioning

  jaeger:
    image: jaegertracing/all-in-one:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:16686:16686"
      - "127.0.0.1:14268:14268"
    environment:
      - COLLECTOR_OTLP_ENABLED=true
      - SPAN_STORAGE_TYPE=memory

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./deployments/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./deployments/nginx/sites:/etc/nginx/sites-available
      - ./web/static:/var/www/static
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - api
      - mcp

volumes:
  postgres_data:
  redis_data:
  prometheus_data:
  grafana_data:

networks:
  default:
    driver: bridge
```

### 3. Build and Deploy

```bash
# Build production images
make build-prod

# Deploy to production
make deploy-prod

# Or manually:
docker-compose -f docker-compose.prod.yml up -d

# Check services
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f api
```

## NGINX Configuration

### 1. Main Configuration

```nginx
# /opt/proteinprices/deployments/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                   '$status $body_bytes_sent "$http_referer" '
                   '"$http_user_agent" "$http_x_forwarded_for" '
                   'rt=$request_time uct="$upstream_connect_time" '
                   'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main;

    # Performance settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 1M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=search:10m rate=2r/s;

    # Include site configurations
    include /etc/nginx/sites-available/*;
}
```

### 2. Site Configuration

```nginx
# /opt/proteinprices/deployments/nginx/sites/proteinprices.conf
server {
    listen 80;
    server_name proteinprices.com www.proteinprices.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name proteinprices.com www.proteinprices.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/proteinprices.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/proteinprices.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Static files (cached heavily)
    location /static/ {
        alias /var/www/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Source "nginx-static";
        
        # Compress static files
        gzip_static on;
        
        # Security for static files
        location ~* \.(js|css)$ {
            add_header Content-Security-Policy "default-src 'self'";
        }
    }

    # API endpoints
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Headers for caching
        proxy_set_header Cache-Control $http_cache_control;
    }

    # Search endpoint with stricter rate limiting
    location /api/products/search {
        limit_req zone=search burst=5 nodelay;
        
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8080;
        access_log off;
    }

    # MCP server endpoint (for AI integrations)
    location /mcp/ {
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
        
        proxy_pass http://127.0.0.1:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # MCP-specific timeouts
        proxy_connect_timeout 10s;
        proxy_send_timeout 120s;
        proxy_read_timeout 120s;
    }

    # Main application
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Cache static HTML pages
        proxy_cache_valid 200 302 5m;
        proxy_cache_valid 404 1m;
    }

    # Monitoring (restrict access)
    location /metrics {
        allow 127.0.0.1;
        deny all;
        proxy_pass http://127.0.0.1:9090;
    }

    # Block unwanted requests
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
```

## SSL Certificate Setup

### 1. Let's Encrypt with Certbot

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get certificates
sudo certbot --nginx -d proteinprices.com -d www.proteinprices.com

# Test renewal
sudo certbot renew --dry-run

# Set up automatic renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 2. Manual Certificate Verification

```bash
# Check certificate
openssl x509 -in /etc/letsencrypt/live/proteinprices.com/fullchain.pem -text -noout

# Test SSL configuration
curl -I https://proteinprices.com
```

## Database Migration

### 1. Initial Setup

```bash
# Run initial migrations
docker-compose -f docker-compose.prod.yml exec api /app/migrate up

# Seed initial data
docker-compose -f docker-compose.prod.yml exec api /app/seed
```

### 2. Backup Strategy

```bash
# Create backup script
sudo vim /opt/proteinprices/scripts/backup.sh
```

```bash
#!/bin/bash
# Database backup script

BACKUP_DIR="/opt/proteinprices/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="proteinprices"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
docker-compose -f /opt/proteinprices/docker-compose.prod.yml exec -T postgres pg_dump -U proteinprices $DB_NAME | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Keep only last 30 days of backups
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/db_backup_$DATE.sql.gz"
```

```bash
# Make executable and schedule
sudo chmod +x /opt/proteinprices/scripts/backup.sh
sudo crontab -e
# Add: 0 2 * * * /opt/proteinprices/scripts/backup.sh
```

## Monitoring Setup

### 1. System Monitoring

```bash
# Install monitoring tools
sudo apt install -y htop iotop nethogs

# Set up log rotation
sudo vim /etc/logrotate.d/proteinprices
```

```
/opt/proteinprices/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    create 0644 proteinprices proteinprices
}
```

### 2. Application Monitoring

Access monitoring dashboards:
- **Grafana**: https://proteinprices.com:3000
- **Prometheus**: https://proteinprices.com:9090  
- **Jaeger**: https://proteinprices.com:16686

## Deployment Scripts

### 1. Deployment Makefile

```makefile
# Makefile
.PHONY: build-prod deploy-prod health-check backup restore

build-prod:
	docker-compose -f docker-compose.prod.yml build --no-cache

deploy-prod:
	docker-compose -f docker-compose.prod.yml down
	docker-compose -f docker-compose.prod.yml up -d
	sleep 30
	$(MAKE) health-check

health-check:
	@echo "Checking API health..."
	@curl -f http://localhost:8080/health || (echo "Health check failed" && exit 1)
	@echo "API is healthy"
	@echo "Checking services..."
	@docker-compose -f docker-compose.prod.yml ps

backup:
	./scripts/backup.sh

restore:
	@read -p "Enter backup file name: " backup_file; \
	gunzip -c /opt/proteinprices/backups/$backup_file | \
	docker-compose -f docker-compose.prod.yml exec -T postgres psql -U proteinprices proteinprices

logs:
	docker-compose -f docker-compose.prod.yml logs -f --tail=100

restart-api:
	docker-compose -f docker-compose.prod.yml restart api

restart-scraper:
	docker-compose -f docker-compose.prod.yml restart scraper

restart-mcp:
	docker-compose -f docker-compose.prod.yml restart mcp

update:
	git pull origin main
	$(MAKE) build-prod
	$(MAKE) deploy-prod

rollback:
	git checkout HEAD~1
	$(MAKE) build-prod
	$(MAKE) deploy-prod
```

### 2. Blue-Green Deployment Script

```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.prod.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if services are healthy
check_health() {
    local max_attempts=30
    local attempt=1
    
    log "Checking application health..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:8080/health > /dev/null; then
            log "Health check passed"
            return 0
        fi
        
        warn "Health check failed, attempt $attempt/$max_attempts"
        sleep 10
        ((attempt++))
    done
    
    error "Health check failed after $max_attempts attempts"
}

# Backup current state
backup_current() {
    log "Creating backup before deployment..."
    ./scripts/backup.sh
    
    # Backup current docker images
    docker save proteinprices_api:latest | gzip > /tmp/proteinprices_api_backup.tar.gz
    docker save proteinprices_scraper:latest | gzip > /tmp/proteinprices_scraper_backup.tar.gz
}

# Rollback to previous state
rollback() {
    warn "Rolling back to previous version..."
    
    # Stop current services
    docker-compose -f $COMPOSE_FILE down
    
    # Restore previous images
    if [ -f /tmp/proteinprices_api_backup.tar.gz ]; then
        docker load < /tmp/proteinprices_api_backup.tar.gz
        docker load < /tmp/proteinprices_scraper_backup.tar.gz
    fi
    
    # Start services
    docker-compose -f $COMPOSE_FILE up -d
    
    # Check health
    if check_health; then
        log "Rollback successful"
    else
        error "Rollback failed"
    fi
}

# Main deployment function
deploy() {
    log "Starting blue-green deployment..."
    
    # Backup current state
    backup_current
    
    # Build new images
    log "Building new application images..."
    docker-compose -f $COMPOSE_FILE build --no-cache
    
    # Tag current images as backup
    docker tag proteinprices_api:latest proteinprices_api:backup || true
    docker tag proteinprices_scraper:latest proteinprices_scraper:backup || true
    
    # Deploy new version
    log "Deploying new version..."
    docker-compose -f $COMPOSE_FILE up -d
    
    # Wait for services to start
    sleep 30
    
    # Health check
    if check_health; then
        log "Deployment successful!"
        
        # Clean up backup images
        docker rmi proteinprices_api:backup proteinprices_scraper:backup || true
        rm -f /tmp/proteinprices_*_backup.tar.gz
        
        log "Deployment completed successfully"
    else
        error "Deployment failed, initiating rollback..."
        rollback
    fi
}

# Script execution
case "${1:-}" in
    "deploy")
        deploy
        ;;
    "rollback")
        rollback
        ;;
    "health")
        check_health
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|health}"
        echo "  deploy  - Deploy new version with automatic rollback on failure"
        echo "  rollback - Manually rollback to previous version"
        echo "  health  - Check application health"
        exit 1
        ;;
esac
```

## Monitoring and Alerting

### 1. Prometheus Configuration

```yaml
# deployments/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'api-server'
    static_configs:
      - targets: ['api:9090']
    scrape_interval: 10s
    metrics_path: /metrics

  - job_name: 'scraper'
    static_configs:
      - targets: ['scraper:9091']
    scrape_interval: 30s

  - job_name: 'mcp-server'
    static_configs:
      - targets: ['mcp:9092']
    scrape_interval: 30s

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:9121']

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:9113']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

### 2. Alert Rules

```yaml
# deployments/prometheus/alert_rules.yml
groups:
  - name: api_alerts
    rules:
      - alert: APIHighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "API error rate is {{ $value }} errors per second"

      - alert: APIHighLatency
        expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High API latency"
          description: "95th percentile latency is {{ $value }}s"

      - alert: ScrapingFailure
        expr: scraper_success_rate < 0.9
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "Scraping success rate too low"
          description: "Scraping success rate is {{ $value }}"

      - alert: DatabaseConnections
        expr: pg_stat_database_numbackends > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High database connections"
          description: "Database has {{ $value }} active connections"

  - name: infrastructure_alerts
    rules:
      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"

      - alert: LowDiskSpace
        expr: (node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes > 0.9
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space"
          description: "Disk usage is {{ $value | humanizePercentage }}"
```

## Maintenance Procedures

### 1. Regular Maintenance Tasks

```bash
# scripts/maintenance.sh
#!/bin/bash

set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Clean up old Docker images
cleanup_docker() {
    log "Cleaning up old Docker images..."
    docker system prune -f
    docker volume prune -f
    docker image prune -a -f
}

# Update SSL certificates
update_ssl() {
    log "Updating SSL certificates..."
    certbot renew --quiet
    systemctl reload nginx
}

# Rotate logs
rotate_logs() {
    log "Rotating application logs..."
    logrotate -f /etc/logrotate.d/proteinprices
}

# Update system packages
update_system() {
    log "Updating system packages..."
    apt update && apt upgrade -y
    apt autoremove -y
    apt autoclean
}

# Database maintenance
maintain_database() {
    log "Running database maintenance..."
    docker-compose -f /opt/proteinprices/docker-compose.prod.yml exec -T postgres psql -U proteinprices proteinprices -c "VACUUM ANALYZE;"
    docker-compose -f /opt/proteinprices/docker-compose.prod.yml exec -T postgres psql -U proteinprices proteinprices -c "REINDEX DATABASE proteinprices;"
}

# Main maintenance routine
main() {
    log "Starting maintenance routine..."
    
    cleanup_docker
    update_ssl
    rotate_logs
    update_system
    maintain_database
    
    log "Maintenance completed successfully"
}

# Run maintenance
main
```

### 2. Performance Optimization

```bash
# scripts/optimize.sh
#!/bin/bash

# Optimize PostgreSQL configuration
optimize_postgres() {
    echo "Optimizing PostgreSQL configuration..."
    
    # Update postgresql.conf with optimized settings
    cat > /tmp/postgres_optimizations.conf << EOF
# Memory settings
shared_buffers = 512MB
effective_cache_size = 2GB
maintenance_work_mem = 128MB
work_mem = 8MB

# Checkpoint settings
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Logging
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h'
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
EOF

    # Apply optimizations
    docker cp /tmp/postgres_optimizations.conf proteinprices_postgres_1:/tmp/
    docker-compose -f /opt/proteinprices/docker-compose.prod.yml exec postgres sh -c "cat /tmp/postgres_optimizations.conf >> /var/lib/postgresql/data/postgresql.conf"
    docker-compose -f /opt/proteinprices/docker-compose.prod.yml restart postgres
}

# Optimize Redis configuration  
optimize_redis() {
    echo "Optimizing Redis configuration..."
    
    # Redis optimizations are handled in docker-compose.yml
    # through command line parameters
    docker-compose -f /opt/proteinprices/docker-compose.prod.yml restart redis
}

# System optimizations
optimize_system() {
    echo "Applying system optimizations..."
    
    # Increase file descriptor limits
    echo "* soft nofile 65536" >> /etc/security/limits.conf
    echo "* hard nofile 65536" >> /etc/security/limits.conf
    
    # Optimize network settings
    cat >> /etc/sysctl.conf << EOF
# Network optimizations
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 10
EOF

    sysctl -p
}

optimize_postgres
optimize_redis
optimize_system

echo "Performance optimizations applied successfully"
```

## Troubleshooting Guide

### 1. Common Issues

**Issue: API returns 502 Bad Gateway**
```bash
# Check if API container is running
docker-compose -f docker-compose.prod.yml ps api

# Check API logs
docker-compose -f docker-compose.prod.yml logs api

# Check if API is listening on port 8080
docker-compose -f docker-compose.prod.yml exec api netstat -tlnp | grep 8080

# Restart API service
docker-compose -f docker-compose.prod.yml restart api
```

**Issue: Database connection errors**
```bash
# Check PostgreSQL status
docker-compose -f docker-compose.prod.yml ps postgres

# Check database logs
docker-compose -f docker-compose.prod.yml logs postgres

# Test database connection
docker-compose -f docker-compose.prod.yml exec postgres psql -U proteinprices proteinprices -c "SELECT 1;"

# Check connection limits
docker-compose -f docker-compose.prod.yml exec postgres psql -U proteinprices proteinprices -c "SELECT count(*) FROM pg_stat_activity;"
```

**Issue: High memory usage**
```bash
# Check container memory usage
docker stats

# Check system memory
free -h

# Check for memory leaks in logs
grep -i "memory\|oom" /var/log/syslog

# Restart memory-intensive services
docker-compose -f docker-compose.prod.yml restart api scraper
```

### 2. Emergency Procedures

**Complete Service Restart**
```bash
# Stop all services
docker-compose -f docker-compose.prod.yml down

# Clear any stuck containers
docker system prune -f

# Restart all services
docker-compose -f docker-compose.prod.yml up -d

# Monitor startup
docker-compose -f docker-compose.prod.yml logs -f
```

**Database Recovery**
```bash
# Stop API to prevent writes
docker-compose -f docker-compose.prod.yml stop api scraper

# Restore from latest backup
latest_backup=$(ls -t /opt/proteinprices/backups/db_backup_*.sql.gz | head -1)
gunzip -c $latest_backup | docker-compose -f docker-compose.prod.yml exec -T postgres psql -U proteinprices proteinprices

# Start services
docker-compose -f docker-compose.prod.yml start api scraper
```

## Security Updates

### 1. Update Procedure
```bash
# scripts/security-update.sh
#!/bin/bash

set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SECURITY UPDATE: $1"
}

# Update system packages
log "Updating system packages..."
apt update
apt list --upgradable | grep -i security
apt upgrade -y

# Update Docker images
log "Updating Docker images..."
docker-compose -f /opt/proteinprices/docker-compose.prod.yml pull
docker-compose -f /opt/proteinprices/docker-compose.prod.yml up -d

# Restart services to apply updates
log "Restarting services..."
systemctl restart nginx

# Verify services are healthy
log "Verifying service health..."
sleep 30
curl -f http://localhost:8080/health || exit 1

log "Security update completed successfully"
```

### 2. SSL Certificate Monitoring
```bash
# scripts/ssl-monitor.sh
#!/bin/bash

DOMAIN="proteinprices.com"
CERT_FILE="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"

# Check certificate expiration
EXPIRY_DATE=$(openssl x509 -enddate -noout -in $CERT_FILE | cut -d= -f2)
EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))

if [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
    echo "WARNING: SSL certificate expires in $DAYS_UNTIL_EXPIRY days"
    # Trigger certificate renewal
    certbot renew --force-renewal
    systemctl reload nginx
fi

echo "SSL certificate is valid for $DAYS_UNTIL_EXPIRY more days"
```

## Performance Monitoring

### 1. Application Metrics
Key metrics to monitor:
- **Response Time**: < 50ms for cached responses
- **Throughput**: Requests per second
- **Error Rate**: < 1% error rate
- **Cache Hit Ratio**: > 90% for price data
- **Scraping Success Rate**: > 95%

### 2. Infrastructure Metrics
- **CPU Usage**: < 70% average
- **Memory Usage**: < 80% of available
- **Disk Usage**: < 80% of capacity
- **Network I/O**: Monitor for anomalies
- **Database Connections**: < 80% of max

### 3. Business Metrics
- **Price Update Frequency**: Every 30 minutes
- **Data Freshness**: Average age of price data
- **User Engagement**: Page views, search queries
- **Affiliate Click-through Rate**: Conversion metrics

---

This deployment guide provides a comprehensive foundation for running the Whey Protein Price Comparison Platform in production with proper monitoring, security, and maintenance procedures.