<#
.SYNOPSIS
    Deploy Aspire application to Ubuntu server via SSH

.DESCRIPTION
    This script deploys the Aspire application to a remote Ubuntu server by:
    1. Copying docker-compose.production.yaml and .env to the remote server
    2. Pulling latest Docker images from Docker Hub
    3. Starting services with docker compose
    4. Verifying deployment health

.PARAMETER Host
    Target Ubuntu server hostname or IP address (default: 192.168.1.11)

.PARAMETER Port
    SSH port (default: 22)

.PARAMETER User
    SSH username (default: phil)

.PARAMETER DeployPath
    Remote deployment directory (default: ~/aspire-app)

.PARAMETER SshKeyPath
    Path to SSH private key file (optional, uses default SSH config if not specified)

.PARAMETER ImageTag
    Docker image tag to deploy (default: latest)

.EXAMPLE
    .\Deploy-ToUbuntu.ps1
    Deploys to default host 192.168.1.11 with latest images

.EXAMPLE
    .\Deploy-ToUbuntu.ps1 -Host 192.168.1.15 -User admin -ImageTag v1.0.0
    Deploys to custom host with specific image version
#>

[CmdletBinding()]
param(
    [string]$TargetHost = "192.168.1.11",
    [int]$Port = 22,
    [string]$User = "phil",
    [string]$DeployPath = "~/aspire-app",
    [string]$SshKeyPath = "",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "→ $Message" -ForegroundColor Cyan }
function Write-Warn { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Fail { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }

# Get repository root
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ProductionComposeFile = Join-Path $RepoRoot "docker-compose.production.yaml"
$EnvExampleFile = Join-Path $RepoRoot ".env.example"

Write-Info "Starting deployment to $User@$TargetHost`:$Port"
Write-Info "Deploy path: $DeployPath"
Write-Info "Image tag: $ImageTag"

# Step 1: Validate prerequisites
Write-Info "Validating prerequisites..."

if (-not (Test-Path $ProductionComposeFile)) {
    Write-Fail "docker-compose.production.yaml not found at $ProductionComposeFile"
    exit 1
}

if (-not (Test-Path $EnvExampleFile)) {
    Write-Fail ".env.example not found at $EnvExampleFile"
    exit 1
}

# Check SSH connectivity
$SshArgs = @("-p", $Port)
if ($SshKeyPath) {
    if (-not (Test-Path $SshKeyPath)) {
        Write-Fail "SSH key not found at $SshKeyPath"
        exit 1
    }
    $SshArgs += @("-i", $SshKeyPath)
}

Write-Info "Testing SSH connectivity..."
$TestCmd = "exit 0"
$SshCommand = "ssh $($SshArgs -join ' ') $User@$TargetHost `"$TestCmd`""
try {
    Invoke-Expression $SshCommand | Out-Null
    Write-Success "SSH connection successful"
} catch {
    Write-Fail "SSH connection failed. Check credentials and network connectivity."
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Create remote directory
Write-Info "Creating remote deployment directory..."
$CreateDirCmd = "mkdir -p $DeployPath"
$SshCommand = "ssh $($SshArgs -join ' ') $User@$TargetHost `"$CreateDirCmd`""
Invoke-Expression $SshCommand | Out-Null
Write-Success "Remote directory ready"

# Step 3: Create .env file with specified image tag
Write-Info "Preparing .env configuration..."
$EnvContent = Get-Content $EnvExampleFile -Raw
$EnvContent = $EnvContent -replace 'pngan/aspireapp-apiservice:latest', "pngan/aspireapp-apiservice:$ImageTag"
$EnvContent = $EnvContent -replace 'pngan/aspireapp-webfrontend:latest', "pngan/aspireapp-webfrontend:$ImageTag"

$TempEnvFile = Join-Path $env:TEMP ".env"
$EnvContent | Out-File -FilePath $TempEnvFile -Encoding UTF8 -NoNewline
Write-Success ".env file created with tag: $ImageTag"

# Step 4: Copy files to remote server
Write-Info "Copying docker-compose.production.yaml to remote server..."
$ScpArgs = @("-P", $Port)
if ($SshKeyPath) {
    $ScpArgs += @("-i", $SshKeyPath)
}

$ScpCommand = "scp $($ScpArgs -join ' ') `"$ProductionComposeFile`" $User@$TargetHost`:$DeployPath/docker-compose.yaml"
Invoke-Expression $ScpCommand | Out-Null
Write-Success "docker-compose.yaml copied"

Write-Info "Copying .env to remote server..."
$ScpCommand = "scp $($ScpArgs -join ' ') `"$TempEnvFile`" $User@$TargetHost`:$DeployPath/.env"
Invoke-Expression $ScpCommand | Out-Null
Write-Success ".env copied"

Remove-Item $TempEnvFile -Force

# Step 5: Pull Docker images and start services
Write-Info "Pulling Docker images on remote server..."
$PullCmd = "cd $DeployPath && docker compose pull"
$SshCommand = "ssh $($SshArgs -join ' ') $User@$TargetHost `"$PullCmd`""
Invoke-Expression $SshCommand
Write-Success "Images pulled"

Write-Info "Starting Docker Compose services..."
$UpCmd = "cd $DeployPath && docker compose up -d"
$SshCommand = "ssh $($SshArgs -join ' ') $User@$TargetHost `"$UpCmd`""
Invoke-Expression $SshCommand
Write-Success "Services started"

# Step 6: Wait for health checks
Write-Info "Waiting for services to become healthy (30 seconds)..."
Start-Sleep -Seconds 30

# Step 7: Verify deployment
Write-Info "Verifying deployment status..."
$StatusCmd = "cd $DeployPath && docker compose ps"
$SshCommand = "ssh $($SshArgs -join ' ') $User@$TargetHost `"$StatusCmd`""
$Status = Invoke-Expression $SshCommand

Write-Host ""
Write-Host "Deployment Status:" -ForegroundColor Cyan
Write-Host $Status

# Check if webfrontend is healthy
if ($Status -match "webfrontend.*\(healthy\)") {
    Write-Success "Deployment successful! Application is healthy."
    Write-Host ""
    Write-Info "Access the application at: http://$TargetHost:8080"
    Write-Info "Or via reverse proxy: https://app.nganfamily.com (if configured)"
    exit 0
} else {
    Write-Warn "Deployment completed but health check status unclear."
    Write-Info "Check logs with: ssh $User@$TargetHost 'cd $DeployPath && docker compose logs'"
    exit 0
}
