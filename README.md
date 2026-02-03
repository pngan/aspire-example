# Aspire Example App

This is a .NET Aspire distributed application with a Blazor frontend and an API backend.

## Architecture

- **Web Frontend**: Blazor Server app
- **API Service**: Minimal API backend
- **Service Defaults**: Shared configuration for telemetry, health checks, and service discovery

## Development

### Prerequisites

- .NET 10.0 SDK
- Docker Desktop (optional, for running containerized resources)

### Run locally

```powershell
# Run the AppHost (starts all services)
dotnet run --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj
```

The dashboard will be available at the URL shown in the console (typically localhost:18888).

## Deployment (Docker Compose)

This app supports deployment via Docker Compose with a Caddy reverse proxy.

### 1. Generate Artifacts

Generate the `docker-compose.yaml` and `.env` files:

```powershell
aspire publish --output-path artifacts --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj
```

### 2. Run with Docker Compose

Deploy the application stack:

```bash
cd artifacts
docker compose up -d --build
```

### 3. Configure Reverse Proxy

If running behind a reverse proxy (like Caddy), configure it to forward traffic to the webfrontend service on port 8080. See `deploy/README.md` for detailed instructions.

## Documentation

- [Deployment Guide](deploy/README.md) - Detailed deployment instructions
- [Caddy Configuration](deploy/Caddyfile.aspire) - Reverse proxy configuration snippet
