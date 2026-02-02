# .NET Aspire Application

This is a .NET Aspire distributed application targeting .NET 10.0 with Blazor web UI and API services.

## Build and Test Commands

```powershell
# Build entire solution
dotnet build AspireApp/AspireApp.sln

# Run the AppHost (starts all services)
dotnet run --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj

# Run tests
dotnet test AspireApp/AspireApp.Tests/AspireApp.Tests.csproj

# Run a single test
dotnet test AspireApp/AspireApp.Tests/AspireApp.Tests.csproj --filter "FullyQualifiedName~GetWebResourceRootReturnsOkStatusCode"
```

## Publish and Deploy Commands

```powershell
# Publish to Docker Compose (generates artifacts/ directory)
aspire publish --output-path artifacts --project AspireApp/AspireApp.AppHost/AspireApp.AppHost.csproj

# Deploy with Docker Compose (on target machine)
cd artifacts
docker compose up -d --build
```

See `deploy/README.md` for full deployment instructions including Caddy reverse proxy setup.

## Architecture

This is a .NET Aspire distributed application with the following structure:

### AppHost (`AspireApp.AppHost`)
- Entry point for the distributed application
- Orchestrates service startup and configuration
- Defines service dependencies and health checks
- Services run with dependency injection: `apiservice` must be healthy before `webfrontend` starts
- Uses `AppHost.cs` file instead of Program.cs for orchestration logic

### ServiceDefaults (`AspireApp.ServiceDefaults`)
- Shared library referenced by all service projects
- Configures: OpenTelemetry (metrics, tracing, logging), service discovery, HTTP resilience handlers, health checks
- Extension methods in `Extensions.cs` provide `AddServiceDefaults()` to bootstrap common functionality
- Health endpoints exposed at `/health` (all checks) and `/alive` (liveness only) in development mode

### Web Frontend (`AspireApp.Web`)
- Blazor Server application with interactive components
- Uses service discovery to communicate with API: `https+http://apiservice` (prefers HTTPS, falls back to HTTP)
- Blazor component structure: Pages in `Components/Pages/`, Layout in `Components/Layout/`
- Uses `WeatherApiClient` for typed HTTP calls to backend

### API Service (`AspireApp.ApiService`)
- Minimal API with OpenAPI/Swagger (dev mode only)
- Provides `/weatherforecast` endpoint with sample data
- Uses record types for DTOs

### Tests (`AspireApp.Tests`)
- Uses NUnit with Aspire.Hosting.Testing
- Tests create full distributed application using `DistributedApplicationTestingBuilder`
- Integration tests verify end-to-end service communication
- Uses `ResourceNotifications.WaitForResourceHealthyAsync()` to ensure services are ready before testing

## Key Conventions

- **Health checks**: All services expose `/health` and `/alive` endpoints via `MapDefaultEndpoints()`
- **Service defaults**: Every service calls `builder.AddServiceDefaults()` early in Program.cs to configure telemetry and discovery
- **Service naming**: Service names in AppHost (e.g., "apiservice", "webfrontend") match the names used for service discovery
- **Scheme resolution**: Use `https+http://` prefix in service URLs to prefer HTTPS with HTTP fallback
- **Project references**: AppHost references service projects; services reference ServiceDefaults; avoid circular references
- **Test timeouts**: Integration tests use 30-second default timeout with cancellation tokens
- **Primary constructors**: API clients and services use C# 12 primary constructors (e.g., `public class WeatherApiClient(HttpClient httpClient)`)
