#!/bin/bash
# =============================================================================
# StickBy Backend Deployment Script
# =============================================================================
# Usage: ./deploy.sh [backend|website|admin|all|nginx|test|logs]
#
# Follows the standard Hetzner server deployment process:
# - Uses shared-network (external Docker network)
# - nginx config at /opt/infrastructure/nginx.conf
# - NEVER restarts nginx container, only reloads config
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
STICKBY_DIR="/opt/stickby"
DEPLOYMENT_DIR="$STICKBY_DIR/deployment"
NGINX_CONF="/opt/infrastructure/nginx.conf"
COMPOSE_FILE="docker-compose.production.yml"
ENV_FILE=".env.production"

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

check_directory() {
    if [ ! -d "$STICKBY_DIR" ]; then
        log_error "StickBy directory not found at $STICKBY_DIR"
        exit 1
    fi
}

pull_changes() {
    log_info "Pulling latest changes..."
    cd "$STICKBY_DIR"
    git pull origin master
    log_success "Git pull completed"
}

deploy_service() {
    local service=$1
    log_info "Deploying $service..."
    cd "$DEPLOYMENT_DIR"

    # Stop old container
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" stop "$service" 2>/dev/null || true

    # Build and start
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build "$service"
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d "$service"

    # Wait for container to start
    sleep 3

    # Verify container is running
    if docker ps | grep -q "stickby-$service"; then
        log_success "$service container is running"
    else
        log_error "$service container failed to start"
        docker logs "stickby-$service" --tail 20
        exit 1
    fi

    # Ensure container is on shared-network
    if ! docker network inspect shared-network | grep -q "stickby-$service"; then
        log_info "Connecting $service to shared-network..."
        docker network connect shared-network "stickby-$service" 2>/dev/null || true
    fi
}

deploy_all() {
    log_info "Deploying all StickBy services..."
    cd "$DEPLOYMENT_DIR"

    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" down 2>/dev/null || true
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" build
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

    sleep 5
    log_success "All services deployed"
}

check_nginx_config() {
    log_info "Checking nginx configuration for StickBy..."

    local missing=0

    # Check upstreams
    if ! grep -q "upstream stickby-website" "$NGINX_CONF"; then
        log_warn "Missing: upstream stickby-website"
        missing=1
    fi
    if ! grep -q "upstream stickby-backend" "$NGINX_CONF"; then
        log_warn "Missing: upstream stickby-backend"
        missing=1
    fi
    if ! grep -q "upstream stickby-admin" "$NGINX_CONF"; then
        log_warn "Missing: upstream stickby-admin"
        missing=1
    fi

    # Check locations
    if ! grep -q "location /stickby/backend/hubs/" "$NGINX_CONF"; then
        log_warn "Missing: location /stickby/backend/hubs/ (SignalR WebSocket)"
        missing=1
    fi
    if ! grep -q "location /stickby/backend" "$NGINX_CONF"; then
        log_warn "Missing: location /stickby/backend"
        missing=1
    fi
    if ! grep -q "location /stickby/website" "$NGINX_CONF"; then
        log_warn "Missing: location /stickby/website"
        missing=1
    fi
    if ! grep -q "location /stickby/admin-panel" "$NGINX_CONF"; then
        log_warn "Missing: location /stickby/admin-panel"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        log_error "nginx config is incomplete!"
        echo ""
        echo "Add the following to /opt/infrastructure/nginx.conf:"
        echo ""
        echo "1. Add upstreams in the http block (with other upstreams):"
        echo "   cat $DEPLOYMENT_DIR/nginx-stickby.conf | head -25"
        echo ""
        echo "2. Add locations in the server block (before fallback):"
        echo "   cat $DEPLOYMENT_DIR/nginx-stickby.conf | tail -n +27"
        echo ""
        echo "Then run: docker exec nginx nginx -t && docker exec nginx nginx -s reload"
        return 1
    fi

    log_success "nginx config looks complete"
}

update_nginx() {
    log_info "Updating nginx configuration..."

    # Backup
    cp "$NGINX_CONF" "${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Backup created"

    # Check if config is complete
    if ! check_nginx_config; then
        return 1
    fi

    # Test and reload
    log_info "Testing nginx configuration..."
    if docker exec nginx nginx -t; then
        log_info "Reloading nginx..."
        docker exec nginx nginx -s reload
        log_success "nginx reloaded"
    else
        log_error "nginx config test failed!"
        return 1
    fi
}

test_endpoints() {
    log_info "Testing StickBy endpoints..."
    echo ""

    local base="https://www.kmw-technology.de/stickby"

    test_url() {
        local name=$1
        local url=$2
        local expected=$3

        printf "  %-25s " "$name:"
        local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")

        if [ "$status" = "$expected" ]; then
            echo -e "${GREEN}OK${NC} ($status)"
        elif [ "$status" = "000" ]; then
            echo -e "${RED}TIMEOUT${NC}"
        else
            echo -e "${YELLOW}$status${NC} (expected $expected)"
        fi
    }

    test_url "Backend Health" "$base/backend/health" "200"
    test_url "Demo Identities API" "$base/backend/api/demo/identities" "200"
    test_url "SignalR Hub" "$base/backend/hubs/demosync" "400"
    test_url "Website" "$base/website/" "200"
    test_url "Admin Panel" "$base/admin-panel/" "200"

    echo ""
}

show_logs() {
    local service=${1:-backend}
    log_info "Logs for stickby-$service:"
    docker logs "stickby-$service" --tail 50
}

show_status() {
    log_info "StickBy container status:"
    echo ""
    docker ps --filter "name=stickby" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""

    log_info "Checking shared-network connectivity:"
    for container in stickby-website stickby-backend stickby-admin stickby-postgres; do
        if docker network inspect shared-network 2>/dev/null | grep -q "$container"; then
            echo -e "  $container: ${GREEN}connected${NC}"
        else
            echo -e "  $container: ${RED}not connected${NC}"
        fi
    done
}

main() {
    echo "=========================================="
    echo "  StickBy Deployment"
    echo "=========================================="
    echo ""

    check_directory

    case "${1:-backend}" in
        backend)
            pull_changes
            deploy_service "backend"
            test_endpoints
            ;;
        website)
            pull_changes
            deploy_service "website"
            test_endpoints
            ;;
        admin)
            pull_changes
            deploy_service "admin"
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
        nginx-check)
            check_nginx_config
            ;;
        test)
            test_endpoints
            ;;
        logs)
            show_logs "${2:-backend}"
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  backend     Deploy backend only (default)"
            echo "  website     Deploy website only"
            echo "  admin       Deploy admin panel only"
            echo "  all         Deploy all services"
            echo "  nginx       Update and reload nginx config"
            echo "  nginx-check Check nginx config without changing"
            echo "  test        Test all endpoints"
            echo "  logs [svc]  Show logs (default: backend)"
            echo "  status      Show container status"
            exit 1
            ;;
    esac

    echo ""
    log_success "Done!"
}

main "$@"
