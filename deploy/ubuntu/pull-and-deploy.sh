#!/bin/bash
# Pull and Deploy Aspire Application
# Usage: ./pull-and-deploy.sh [image_tag]
# Example: ./pull-and-deploy.sh v1.0.0

set -e

IMAGE_TAG=${1:-latest}
DEPLOY_DIR="${DEPLOY_DIR:-$HOME/aspire-app}"

echo "→ Aspire Application Deployment"
echo "→ Deploy directory: $DEPLOY_DIR"
echo "→ Image tag: $IMAGE_TAG"
echo ""

# Check if docker-compose.yaml exists
if [ ! -f "$DEPLOY_DIR/docker-compose.yaml" ]; then
    echo "✗ docker-compose.yaml not found in $DEPLOY_DIR"
    echo "  Run Deploy-ToUbuntu.ps1 from your dev machine first."
    exit 1
fi

# Check if .env exists
if [ ! -f "$DEPLOY_DIR/.env" ]; then
    echo "✗ .env not found in $DEPLOY_DIR"
    echo "  Run Deploy-ToUbuntu.ps1 from your dev machine first."
    exit 1
fi

cd "$DEPLOY_DIR"

# Update .env with specified image tag
echo "→ Updating .env with tag: $IMAGE_TAG"
sed -i "s|pngan/aspireapp-apiservice:.*|pngan/aspireapp-apiservice:$IMAGE_TAG|g" .env
sed -i "s|pngan/aspireapp-webfrontend:.*|pngan/aspireapp-webfrontend:$IMAGE_TAG|g" .env

# Pull latest images
echo "→ Pulling Docker images from Docker Hub..."
docker compose pull

# Start services
echo "→ Starting services with docker compose..."
docker compose up -d

# Wait for health checks
echo "→ Waiting for services to become healthy (30 seconds)..."
sleep 30

# Show status
echo ""
echo "✓ Deployment Status:"
docker compose ps

# Check if webfrontend is healthy
if docker compose ps | grep -q "webfrontend.*healthy"; then
    echo ""
    echo "✓ Deployment successful! Application is healthy."
    echo "→ Access at: http://$(hostname -I | awk '{print $1}'):8080"
else
    echo ""
    echo "⚠ Services started but health status unclear."
    echo "→ Check logs with: docker compose logs -f"
fi
