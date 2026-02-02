# Deployment Guide

This guide explains how to deploy the Aspire app using Docker Compose with a Caddy reverse proxy.

## Architecture

```
Internet → Router (ports 80/443) → Caddy (192.168.1.2) → Aspire webfrontend (192.168.1.11:8080)
                                                        ↓
                                                apiservice (internal)
```

- **Domain**: app.nganfamily.com
- **SSL**: Automatic via Let's Encrypt (Caddy)
- **Aspire machine**: 192.168.1.11
- **Proxy machine**: 192.168.1.2

## Prerequisites

- Docker and Docker Compose installed on 192.168.1.11
- Caddy reverse proxy running on 192.168.1.2
- Ports 80 and 443 forwarded from router to Caddy machine
- Firewall allows traffic from 192.168.1.2 to 192.168.1.11:8080

## Deployment Steps

### 1. Generate Docker Compose Artifacts (Development Machine)

```powershell
# From repository root
aspire publish --output-path artifacts --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj
```

### 2. Deploy to Aspire Machine (192.168.1.11)

Copy the following to 192.168.1.11:
- `artifacts/` directory
- `AspireApp/` directory (for building images)

Then run:

```bash
cd artifacts
docker compose up -d --build
```

### 3. Configure Reverse Proxy (192.168.1.2)

Add the contents of `deploy/Caddyfile.aspire` to your existing Caddyfile:

```caddyfile
app.nganfamily.com {
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

```bash
# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Update and restart
docker compose pull
docker compose up -d --build

# Check health
curl http://192.168.1.11:8080/health
```

## Troubleshooting

### Webfrontend can't reach apiservice

Check that both services are on the `aspire` network:
```bash
docker network inspect artifacts_aspire
```

### Caddy can't reach webfrontend

1. Verify firewall allows 192.168.1.2 → 192.168.1.11:8080
2. Check webfrontend is healthy: `curl http://192.168.1.11:8080/health`
3. Check Caddy logs: `docker logs caddy`

### SSL certificate issues

Ensure:
- Domain DNS points to your external IP
- Ports 80/443 are forwarded to Caddy machine
- No other service is using port 80 (needed for ACME challenge)
