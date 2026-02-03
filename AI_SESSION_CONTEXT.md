# AI Session Context & Architecture Summary
> Created: 2026-02-03
> Purpose: Context recall for future AI sessions regarding this project's specific setup.

## Project Overview
This is a **.NET Aspire** distributed application targeting .NET 10.0. It consists of:
- **Web Frontend**: Blazor Server (`AspireApp.Web`)
- **API Service**: Minimal API (`AspireApp.ApiService`)
- **Service Defaults**: Shared configuration (`AspireApp.ServiceDefaults`)

## Deployment Architecture (Custom)
Unlike standard Aspire deployments, this project is configured for a specific **Home Lab Docker Compose** setup.

### Infrastructure
- **Target Machine**: 192.168.1.11 (Runs Docker Compose)
- **Reverse Proxy**: 192.168.1.2 (Runs Caddy)
- **Domain**: `app.nganfamily.com` (SSL via Let's Encrypt on Caddy)

### Traffic Flow
```
Internet -> Router -> Caddy (192.168.1.2:443) -> WebFrontend (192.168.1.11:8080) -> ApiService (Internal Docker Network)
```
*Note: ApiService is NOT exposed externally or to the host network, only to WebFrontend.*

## Key Workflows

### 1. Generating Deployment Artifacts
The `docker-compose.yaml` is **generated** by Aspire but modified by the `.env` configuration.
```powershell
aspire publish --output-path artifacts --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj
```

### 2. Running the Application
```bash
cd artifacts
docker compose up -d --build
```

## Critical Customizations
1.  **AppHost.cs**: Modified to include `builder.AddDockerComposeEnvironment("docker-compose");` requiring `Aspire.Hosting.Docker` package.
2.  **Dockerfiles**: Manually created in project roots (`AspireApp.Web/Dockerfile`, `AspireApp.ApiService/Dockerfile`) to support the build process.
3.  **Docker Compose**:
    *   Health checks adjusted to use `curl` and correct ports.
    *   WebFrontend binds to host port `8080`.
    *   ApiService is internal-only.

## File Map
- `deploy/README.md`: Comprehensive deployment instructions.
- `deploy/Caddyfile.aspire`: Caddy configuration snippet.
- `artifacts/`: Output directory for `aspire publish` (contains `docker-compose.yaml` and `.env`).
- `.github/copilot-instructions.md`: Updated with CLI commands for this project.

## Active Work
**Current Plan**: `deploy/DEPLOYMENT_PLAN.md` (Created: 2026-02-03)
- ✅ **Phase 0 Complete**: Playwright test suite with 20 passing E2E tests
- 🚧 **Next**: Phase 1 - Docker Hub publishing with GitHub Actions
- Adding PowerShell and Bash helper scripts for deployment to 192.168.1.11
- Creating dual docker-compose setup (dev vs production)

## Playwright Test Configuration
- **Local**: `https://localhost:7024` (development, accepts self-signed certs)
- **Ubuntu**: `http://192.168.1.11:8080` (direct deployment)
- **Production**: `https://apps.nganfamily.com` (public domain with SSL)
- Test suite: 20 E2E tests covering home, weather, counter, and health endpoints
- Run with: `npm run test:local`, `npm run test:ubuntu`, `npm run test:production`

## Future Context
When resuming work, read `deploy/README.md` to understand the operational constraints. The system assumes a Linux-like environment for Docker (using `curl` for health checks).
