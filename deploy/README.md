# Deployment Guide

This guide explains how to deploy the Aspire app using Docker Compose with a Caddy reverse proxy.

## Table of Contents
1. [Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [Docker Hub Publishing](#docker-hub-publishing)
4. [Deployment Steps](#deployment-steps)
5. [Reverse Proxy Configuration](#reverse-proxy-configuration)
6. [Troubleshooting](#troubleshooting)

## Architecture

```
Internet → Router (ports 80/443) → Caddy (192.168.1.4) → Aspire webfrontend (192.168.1.11:8080)
                                                        ↓
                                                apiservice (internal)
```

- **Domain**: apps.nganfamily.com
- **SSL**: Automatic via Let's Encrypt (Caddy)
- **Aspire machine**: 192.168.1.11
- **Proxy machine**: 192.168.1.4

## Prerequisites

- Docker and Docker Compose installed on 192.168.1.11
- Caddy reverse proxy running on 192.168.1.4
- Ports 80 and 443 forwarded from router to Caddy machine
- Firewall allows traffic from 192.168.1.4 to 192.168.1.11:8080

## Docker Hub Publishing

This project uses GitHub Actions to publish Docker images to Docker Hub for easy deployment.

### Setup GitHub Secrets

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token (create at https://hub.docker.com/settings/security)

### Publish Images

1. Go to Actions tab in your GitHub repository
2. Select "Publish Docker Images" workflow
3. Click "Run workflow"
4. Enter a version tag (e.g., `v1.0.0`)
5. Click "Run workflow"

This will publish:
- `<username>/aspireapp-webfrontend:v1.0.0` and `latest`
- `<username>/aspireapp-apiservice:v1.0.0` and `latest`

## Deployment Steps

### Method 1: Automated PowerShell Deployment (Recommended)

From your Windows development machine:

```powershell
# Deploy latest version
.\deploy\Deploy-ToUbuntu.ps1

# Deploy specific version
.\deploy\Deploy-ToUbuntu.ps1 -ImageTag v1.0.0

# Deploy to different host
.\deploy\Deploy-ToUbuntu.ps1 -Host 192.168.1.15 -User admin -ImageTag v1.0.0
```

**Parameters:**
- `-Host`: Target server IP (default: 192.168.1.11)
- `-Port`: SSH port (default: 22)
- `-User`: SSH username (default: phil)
- `-DeployPath`: Remote directory (default: ~/aspire-app)
- `-SshKeyPath`: SSH key file path (optional)
- `-ImageTag`: Docker image tag (default: latest)

**Prerequisites:**
- SSH access to Ubuntu server (key-based auth recommended)
- Docker Hub images already published via GitHub Actions

### Method 2: Manual Deployment

#### Option A: Using Docker Hub Images (Production)

1. **Copy production compose to Ubuntu:**
   ```bash
   scp docker-compose.production.yaml user@192.168.1.11:~/aspire-app/docker-compose.yaml
   scp .env.example user@192.168.1.11:~/aspire-app/.env
   ```

2. **Edit .env on Ubuntu** to set your Docker Hub username:
   ```bash
   APISERVICE_IMAGE=pngan/aspireapp-apiservice:latest
   WEBFRONTEND_IMAGE=pngan/aspireapp-webfrontend:latest
   ```

3. **Deploy using Ubuntu helper script:**
   ```bash
   cd ~/aspire-app
   chmod +x deploy/ubuntu/*.sh
   ./deploy/ubuntu/pull-and-deploy.sh
   
   # Or deploy specific version
   ./deploy/ubuntu/pull-and-deploy.sh v1.0.0
   ```

#### Option B: Building from Source (Development)

1. **Generate artifacts on development machine:**
   ```powershell
   aspire publish --output-path artifacts --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj
   ```

2. **Copy to Ubuntu:**
   ```bash
   scp -r artifacts/ AspireApp/ user@192.168.1.11:~/aspire-build/
   ```

3. **Build and run:**
   ```bash
   cd ~/aspire-build/artifacts
   docker compose up -d --build
   ```

### 3. Configure Reverse Proxy (192.168.1.4)

Add the contents of `deploy/Caddyfile.aspire` to your existing Caddyfile:

```caddyfile
apps.nganfamily.com {
    reverse_proxy 192.168.1.11:8080 {
        health_uri /health
        health_interval 30s
        health_timeout 10s
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

Reload Caddy:

```bash
docker exec -it caddy caddy reload --config /etc/caddy/Caddyfile
```

## Configuration

### Environment Variables

Edit `artifacts/.env` to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `APISERVICE_PORT` | 8080 | Internal port for API service |
| `WEBFRONTEND_PORT` | 8080 | Internal port for web frontend |
| `WEBFRONTEND_HOST_PORT` | 8080 | Host port exposed for reverse proxy |

### Services

| Service | Port | Access |
|---------|------|--------|
| webfrontend | 8080 (host) | External via Caddy |
| apiservice | 8080 (internal) | Internal only |
| dashboard | 18888 (host) | http://192.168.1.11:18888 |

## Management Commands

### Using Ubuntu Helper Scripts

```bash
# Deploy/update application
./deploy/ubuntu/pull-and-deploy.sh          # Deploy latest
./deploy/ubuntu/pull-and-deploy.sh v1.0.0   # Deploy specific version

# View logs
./deploy/ubuntu/view-logs.sh                # All services
./deploy/ubuntu/view-logs.sh webfrontend    # Specific service
./deploy/ubuntu/view-logs.sh -f             # Follow all logs
./deploy/ubuntu/view-logs.sh apiservice -f  # Follow specific service

# Stop services
./deploy/ubuntu/stop-services.sh            # Stop containers
./deploy/ubuntu/stop-services.sh --remove-volumes  # Stop and remove data
```

### Using Docker Compose Directly

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Update and restart
docker compose pull
docker compose up -d

# Check health
curl http://localhost:8080/health
```

## Troubleshooting

### SSH Connection Issues

**Problem:** PowerShell deployment script can't connect to Ubuntu server

**Solutions:**
1. Verify SSH key setup: `ssh user@192.168.1.11 'echo Connected'`
2. Check SSH key permissions (Linux): `chmod 600 ~/.ssh/id_rsa`
3. Use `-SshKeyPath` parameter to specify key explicitly
4. Check firewall allows SSH port 22

### Docker Hub Access Issues

**Problem:** Cannot pull images from Docker Hub

**Solutions:**
1. Verify images exist: `docker search pngan/aspireapp-webfrontend`
2. Check Docker Hub credentials: `docker login`
3. Ensure GitHub Actions workflow completed successfully
4. Verify image tag exists in Docker Hub repository

### Webfrontend can't reach apiservice

Check that both services are on the `aspire` network:
```bash
docker network inspect artifacts_aspire
```

### Caddy can't reach webfrontend

1. Verify firewall allows 192.168.1.4 → 192.168.1.11:8080
2. Check webfrontend is healthy: `curl http://192.168.1.11:8080/health`
3. Check Caddy logs: `docker logs caddy`

### SSL certificate issues

Ensure:
- Domain DNS points to your external IP
- Ports 80/443 are forwarded to Caddy machine
- No other service is using port 80 (needed for ACME challenge)
