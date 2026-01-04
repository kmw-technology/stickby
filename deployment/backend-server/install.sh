#!/bin/bash
# =============================================================================
# StickBy Deployment Scripts Installer
# =============================================================================
# Run this once to set up the deployment scripts on the server
# Usage: ./install.sh
# =============================================================================

set -e

STICKBY_DIR="/opt/stickby"
SCRIPTS_DIR="$STICKBY_DIR/deployment/backend-server"

echo "Installing StickBy deployment scripts..."

# Make scripts executable
chmod +x "$SCRIPTS_DIR/deploy.sh"
chmod +x "$SCRIPTS_DIR/install.sh"

# Create symlink for easy access
if [ ! -L "/usr/local/bin/stickby-deploy" ]; then
    ln -s "$SCRIPTS_DIR/deploy.sh" /usr/local/bin/stickby-deploy
    echo "Created symlink: stickby-deploy"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  stickby-deploy          # Deploy backend only"
echo "  stickby-deploy backend  # Deploy backend only"
echo "  stickby-deploy all      # Deploy all services"
echo "  stickby-deploy nginx    # Update nginx config"
echo "  stickby-deploy test     # Test all endpoints"
echo "  stickby-deploy logs     # Show backend logs"
echo ""
