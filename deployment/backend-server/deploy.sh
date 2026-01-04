#!/bin/bash
# =============================================================================
# StickBy Backend Deployment Script
# =============================================================================
# Usage: ./deploy.sh [backend|all|nginx]
#
# Options:
#   backend  - Rebuild and restart only the backend container
#   all      - Rebuild and restart all StickBy services
#   nginx    - Update nginx config and reload
#   (none)   - Same as 'backend'
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STICKBY_DIR="/opt/stickby"
DEPLOYMENT_DIR="$STICKBY_DIR/deployment"
NGINX_CONF="/opt/infrastructure/nginx.conf"
COMPOSE_FILE="docker-compose.production.yml"
ENV_FILE=".env.production"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
check_directory() {
    if [ ! -d "$STICKBY_DIR" ]; then
        log_error "StickBy directory not found at $STICKBY_DIR"
        exit 1
    fi
    cd "$STICKBY_DIR"
}

# Pull latest changes from git
pull_changes() {
    log_info "Pulling latest changes from git..."
    git pull origin master
    log_success "Git pull completed"
}

# Deploy backend only
deploy_backend() {
    log_info "Building backend container..."
    cd "$DEPLOYMENT_DIR"
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build backend

    log_info "Starting backend container..."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d backend

    log_info "Waiting for backend to start..."
    sleep 5

    # Check health
    if curl -s -o /dev/null -w "%{http_code}" https://www.kmw-technology.de/stickby/backend/health | grep -q "200"; then
        log_success "Backend is healthy!"
    else
        log_warn "Backend health check failed - checking logs..."
        docker logs stickby-backend --tail 20
    fi
}

# Deploy all services
deploy_all() {
    log_info "Building all containers..."
    cd "$DEPLOYMENT_DIR"
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build

    log_info "Starting all containers..."
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

    log_success "All services deployed"
}

# Update nginx configuration
update_nginx() {
    log_info "Checking nginx configuration..."

    # Backup current config
    BACKUP_FILE="${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$NGINX_CONF" "$BACKUP_FILE"
    log_info "Backup created: $BACKUP_FILE"

    # Check if SignalR hub location exists
    if grep -q "/stickby/backend/hubs/" "$NGINX_CONF"; then
        log_success "SignalR hub location already configured"
    else
        log_warn "SignalR hub location NOT found in nginx config!"
        log_info "Please add the following location block BEFORE /stickby/backend:"
        echo ""
        cat "$DEPLOYMENT_DIR/nginx-stickby.conf" | grep -A 18 "SignalR WebSocket Hub"
        echo ""
        log_warn "After adding, run: docker exec nginx nginx -t && docker exec nginx nginx -s reload"
        return 1
    fi

    # Test nginx config
    log_info "Testing nginx configuration..."
    if docker exec nginx nginx -t; then
        log_info "Reloading nginx..."
        docker exec nginx nginx -s reload
        log_success "nginx reloaded successfully"
    else
        log_error "nginx configuration test failed!"
        log_info "Restoring backup..."
        cp "$BACKUP_FILE" "$NGINX_CONF"
        return 1
    fi
}

# Test endpoints
test_endpoints() {
    log_info "Testing endpoints..."

    echo -n "  Backend Health: "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://www.kmw-technology.de/stickby/backend/health)
    if [ "$STATUS" = "200" ]; then
        echo -e "${GREEN}OK${NC} ($STATUS)"
    else
        echo -e "${RED}FAIL${NC} ($STATUS)"
    fi

    echo -n "  Demo Identities: "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://www.kmw-technology.de/stickby/backend/api/demo/identities)
    if [ "$STATUS" = "200" ]; then
        echo -e "${GREEN}OK${NC} ($STATUS)"
    else
        echo -e "${RED}FAIL${NC} ($STATUS)"
    fi

    echo -n "  SignalR Hub: "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://www.kmw-technology.de/stickby/backend/hubs/demosync)
    if [ "$STATUS" = "400" ]; then
        echo -e "${GREEN}OK${NC} ($STATUS - expected, needs WebSocket)"
    else
        echo -e "${YELLOW}CHECK${NC} ($STATUS)"
    fi

    echo -n "  Website: "
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://www.kmw-technology.de/stickby/website/)
    if [ "$STATUS" = "200" ]; then
        echo -e "${GREEN}OK${NC} ($STATUS)"
    else
        echo -e "${RED}FAIL${NC} ($STATUS)"
    fi
}

# Show logs
show_logs() {
    log_info "Recent backend logs:"
    docker logs stickby-backend --tail 30
}

# Main
main() {
    echo "=========================================="
    echo "  StickBy Backend Deployment"
    echo "=========================================="
    echo ""

    check_directory

    case "${1:-backend}" in
        backend)
            pull_changes
            deploy_backend
            test_endpoints
            ;;
        all)
            pull_changes
            deploy_all
            test_endpoints
            ;;
        nginx)
            pull_changes
            update_nginx
            ;;
        test)
            test_endpoints
            ;;
        logs)
            show_logs
            ;;
        *)
            echo "Usage: $0 [backend|all|nginx|test|logs]"
            exit 1
            ;;
    esac

    echo ""
    log_success "Deployment completed!"
}

main "$@"
