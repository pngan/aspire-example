#!/bin/bash
# Stop Aspire Application Services
# Usage: ./stop-services.sh [--remove-volumes]

set -e

DEPLOY_DIR="${DEPLOY_DIR:-$HOME/aspire-app}"
REMOVE_VOLUMES=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --remove-volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
    esac
done

echo "→ Stopping Aspire Application"
echo "→ Deploy directory: $DEPLOY_DIR"
echo ""

# Check if docker-compose.yaml exists
if [ ! -f "$DEPLOY_DIR/docker-compose.yaml" ]; then
    echo "✗ docker-compose.yaml not found in $DEPLOY_DIR"
    exit 1
fi

cd "$DEPLOY_DIR"

# Stop and remove containers
echo "→ Stopping services..."
docker compose down

if [ "$REMOVE_VOLUMES" = true ]; then
    echo "→ Removing volumes..."
    docker compose down -v
    echo "✓ Services stopped and volumes removed"
else
    echo "✓ Services stopped"
    echo "  To remove volumes, run: ./stop-services.sh --remove-volumes"
fi

echo ""
echo "→ Remaining containers:"
docker ps -a | grep aspire || echo "  (none)"
