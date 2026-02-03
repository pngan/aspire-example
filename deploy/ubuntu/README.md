# Ubuntu Helper Scripts

These bash scripts help manage the Aspire application on Ubuntu servers.

## Prerequisites

- Docker and Docker Compose installed
- Scripts located in `~/aspire-app/deploy/ubuntu/` or `$DEPLOY_DIR/deploy/ubuntu/`
- Execute permissions: `chmod +x *.sh`

## Scripts

### pull-and-deploy.sh

Pulls Docker images from Docker Hub and starts the application.

**Usage:**
```bash
./pull-and-deploy.sh [image_tag]
```

**Examples:**
```bash
# Deploy latest version
./pull-and-deploy.sh

# Deploy specific version
./pull-and-deploy.sh v1.0.0

# Use custom deploy directory
DEPLOY_DIR=/opt/aspire ./pull-and-deploy.sh
```

**What it does:**
1. Updates `.env` with specified image tag
2. Pulls images from Docker Hub
3. Starts services with `docker compose up -d`
4. Waits 30 seconds for health checks
5. Shows deployment status

### stop-services.sh

Stops all Aspire application services.

**Usage:**
```bash
./stop-services.sh [options]
```

**Options:**
- `--remove-volumes`: Also remove Docker volumes (deletes data)

**Examples:**
```bash
# Stop services (keep volumes)
./stop-services.sh

# Stop services and remove all data
./stop-services.sh --remove-volumes
```

**What it does:**
1. Runs `docker compose down`
2. Optionally removes volumes with `-v` flag
3. Shows remaining containers

### view-logs.sh

Views logs from running services.

**Usage:**
```bash
./view-logs.sh [service_name] [--follow]
```

**Examples:**
```bash
# View all logs
./view-logs.sh

# View specific service logs
./view-logs.sh webfrontend

# Follow all logs (live tail)
./view-logs.sh -f

# Follow specific service logs
./view-logs.sh apiservice -f
./view-logs.sh apiservice --follow
```

**Available services:**
- `webfrontend` - Blazor web UI
- `apiservice` - Backend API
- `docker-compose-dashboard` - Aspire telemetry dashboard

## Environment Variables

All scripts support the `DEPLOY_DIR` environment variable:

```bash
# Default: ~/aspire-app
export DEPLOY_DIR=/opt/my-custom-path
./pull-and-deploy.sh
```

## Typical Workflows

### Initial Deployment

```bash
# First time setup (run from Windows dev machine)
# This copies docker-compose.yaml and .env to Ubuntu
.\deploy\Deploy-ToUbuntu.ps1

# Then on Ubuntu, deploy the application
cd ~/aspire-app
chmod +x deploy/ubuntu/*.sh
./deploy/ubuntu/pull-and-deploy.sh
```

### Update to New Version

```bash
# Deploy new version
./deploy/ubuntu/pull-and-deploy.sh v1.1.0

# Check logs
./deploy/ubuntu/view-logs.sh -f
```

### Troubleshooting

```bash
# View logs
./deploy/ubuntu/view-logs.sh webfrontend

# Restart services
./deploy/ubuntu/stop-services.sh
./deploy/ubuntu/pull-and-deploy.sh

# Full reset (removes all data)
./deploy/ubuntu/stop-services.sh --remove-volumes
./deploy/ubuntu/pull-and-deploy.sh
```

### Rolling Back

```bash
# Deploy previous version
./deploy/ubuntu/stop-services.sh
./deploy/ubuntu/pull-and-deploy.sh v1.0.0
```

## Integration with PowerShell

These scripts work alongside the PowerShell deployment script:

1. **PowerShell** (`Deploy-ToUbuntu.ps1`): Runs from Windows dev machine, automates entire deployment via SSH
2. **Bash scripts**: Run directly on Ubuntu server for manual operations and maintenance

Use PowerShell for:
- Automated deployments from CI/CD or dev machine
- Initial setup
- Remote management

Use bash scripts for:
- Quick updates on the server
- Troubleshooting and log viewing
- Manual rollbacks
- Local server maintenance

## Health Checks

The application includes health checks at:
- http://localhost:8080/health (webfrontend)
- http://localhost:8080/alive (liveness)

Check health status:
```bash
docker compose ps
curl http://localhost:8080/health
```

## Notes

- All scripts use `set -e` to exit on errors
- Scripts expect `docker-compose.yaml` and `.env` in `$DEPLOY_DIR`
- Default deploy directory is `~/aspire-app`
- Health checks take ~30 seconds to complete
- Scripts are safe to run multiple times (idempotent)
