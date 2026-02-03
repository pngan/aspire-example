#!/bin/bash
# View Aspire Application Logs
# Usage: ./view-logs.sh [service_name] [--follow]
# Examples:
#   ./view-logs.sh              # Show all logs
#   ./view-logs.sh webfrontend  # Show webfrontend logs only
#   ./view-logs.sh -f           # Follow all logs
#   ./view-logs.sh apiservice -f # Follow apiservice logs

set -e

DEPLOY_DIR="${DEPLOY_DIR:-$HOME/aspire-app}"
SERVICE=""
FOLLOW_FLAG=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        -f|--follow)
            FOLLOW_FLAG="-f"
            ;;
        *)
            SERVICE="$arg"
            ;;
    esac
done

# Check if docker-compose.yaml exists
if [ ! -f "$DEPLOY_DIR/docker-compose.yaml" ]; then
    echo "✗ docker-compose.yaml not found in $DEPLOY_DIR"
    exit 1
fi

cd "$DEPLOY_DIR"

echo "→ Viewing logs from: $DEPLOY_DIR"
if [ -n "$SERVICE" ]; then
    echo "→ Service: $SERVICE"
fi
if [ -n "$FOLLOW_FLAG" ]; then
    echo "→ Following logs (Ctrl+C to stop)"
fi
echo ""

# Show logs
if [ -n "$SERVICE" ]; then
    docker compose logs $FOLLOW_FLAG "$SERVICE"
else
    docker compose logs $FOLLOW_FLAG
fi
