#!/bin/bash
# =============================================================================
# StickBy Deployment Scripts Installer
# =============================================================================
# Run this once to set up the deployment scripts on the server
# Usage: ./install.sh
# =============================================================================

set -e

STICKBY_DIR="/opt/stickby"
SCRIPTS_DIR="$STICKBY_DIR/deployment/scripts"

echo "Installing StickBy deployment scripts..."

# Make scripts executable
chmod +x "$SCRIPTS_DIR/deploy.sh"
chmod +x "$SCRIPTS_DIR/install.sh"

# Create/update symlink for easy access
if [ -L "/usr/local/bin/stickby-deploy" ]; then
    rm /usr/local/bin/stickby-deploy
fi
ln -s "$SCRIPTS_DIR/deploy.sh" /usr/local/bin/stickby-deploy
echo "Created symlink: stickby-deploy"

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  stickby-deploy          # Deploy backend (default)"
echo "  stickby-deploy backend  # Deploy backend API"
echo "  stickby-deploy website  # Deploy website"
echo "  stickby-deploy admin    # Deploy admin panel"
echo "  stickby-deploy all      # Deploy all services"
echo "  stickby-deploy nginx    # Update nginx config"
echo "  stickby-deploy test     # Test all endpoints"
echo "  stickby-deploy status   # Show container status"
echo "  stickby-deploy logs     # Show logs"
echo ""
