# Deployment Automation Plan

## Problem Statement
Create a deployment workflow that:
1. Publishes Docker images to Docker Hub via GitHub Actions (manual trigger)
2. Provides PowerShell scripts to deploy to Ubuntu machine at 192.168.1.11 using SSH
3. Provides Bash scripts to pull and run images on Ubuntu
4. Maintains separate docker-compose configurations for local dev (build from source) vs production (pull from Docker Hub)
5. **Uses Playwright for end-to-end verification throughout development and post-deployment**

## Proposed Approach
- Create GitHub Actions workflow for manual Docker Hub publishing
- Create PowerShell deployment script for Windows dev machine
- Create Bash helper scripts for Ubuntu target machine
- Create dual docker-compose configuration: development vs production
- Store Docker Hub credentials as GitHub secrets and use SSH key auth for deployment
- **Create Playwright test suite to verify app functionality in both local and deployed environments**
- **Use Playwright MCP for verification after each major phase**

## Workplan

### Phase 0: Playwright Test Suite Setup
- [x] Create Playwright test project structure
- [x] Create baseline Playwright tests
- [x] Configure environment-specific base URLs
- [x] **COMPLETE**: Verify baseline tests - All 20 tests passing against local environment!

### Phase 1: Docker Hub Publishing Setup
- [x] Create GitHub Actions workflow file (`.github/workflows/docker-publish.yml`)
  - Manual trigger (workflow_dispatch)
  - Build both webfrontend and apiservice images
  - Push to Docker Hub with version tags and `latest`
  - Use GitHub secrets for DOCKERHUB_USERNAME and DOCKERHUB_TOKEN
- [x] Update README.md with instructions for setting up GitHub secrets
- [x] **Playwright Verification**: No changes to app functionality, skip E2E tests

### Phase 2: Docker Compose Configurations
- [ ] Create `docker-compose.production.yaml` that pulls from Docker Hub
  - Remove build context
  - Use Docker Hub image references
  - Keep same environment variables and networking
- [ ] Keep existing `docker-compose.yaml` for local development/testing
- [ ] Create `.env.example` with documented configuration variables
- [ ] **Playwright Verification**: Test local docker-compose.yaml with `docker compose up`
  - Run full Playwright suite against localhost
  - Verify weather data loads correctly
  - Verify API connectivity

### Phase 3: PowerShell Deployment Scripts (Windows)
- [ ] Create `deploy/Deploy-ToUbuntu.ps1` script:
  - SSH key authentication to 192.168.1.11
  - Generate artifacts with `aspire publish`
  - SCP docker-compose.production.yaml and .env to Ubuntu
  - Execute remote docker compose pull and up commands
  - Verify deployment health
- [ ] Add error handling and validation (SSH connectivity, file existence)
- [ ] Add parameters for customization (host, port, user, path)
- [ ] **Playwright Verification**: Test deployment to 192.168.1.11
  - Run Playwright suite against http://192.168.1.11:8080
  - Verify all workflows function correctly
  - Compare results with local tests

### Phase 4: Bash Helper Scripts (Ubuntu)
- [ ] Create `deploy/ubuntu/pull-and-deploy.sh`:
  - Pull latest images from Docker Hub
  - Run docker compose up with production config
  - Show service status
- [ ] Create `deploy/ubuntu/stop-services.sh`:
  - Stop and remove containers
  - Optionally remove volumes
- [ ] Create `deploy/ubuntu/view-logs.sh`:
  - Tail logs for all services or specific service
- [ ] Make scripts executable with appropriate permissions
- [ ] **Playwright Verification**: Test Ubuntu helper scripts
  - Use stop-services.sh and pull-and-deploy.sh
  - Run Playwright tests after each operation
  - Verify graceful shutdown and startup

### Phase 5: Documentation
- [ ] Update `deploy/README.md`:
  - Add Docker Hub workflow section
  - Add PowerShell deployment script usage
  - Add Ubuntu script usage
  - Add troubleshooting for SSH and Docker Hub access
  - Add Playwright testing section
- [ ] Update root `README.md` with quick deployment commands
- [ ] Add `.github/copilot-instructions.md` updates for new deployment commands
- [ ] Create `tests/e2e/README.md` with Playwright test documentation
- [ ] **Playwright Verification**: Documentation only, no tests needed

### Phase 6: Testing & Validation
- [ ] Test GitHub Actions workflow (dry run or test push)
- [ ] Test PowerShell deployment script to 192.168.1.11
- [ ] Verify Docker Hub images are pulled correctly
- [ ] Verify services start and pass health checks
- [ ] Test rollback scenario
- [ ] **Playwright Full Suite Validation**:
  - Run against localhost (local build)
  - Run against 192.168.1.11:8080 (deployed Docker Hub images)
  - Run against app.nganfamily.com (via Caddy reverse proxy with SSL)
  - Document any differences in behavior
  - Create smoke test subset for quick validation

## Key Decisions
1. **GitHub Actions**: Manual `workflow_dispatch` trigger for controlled releases
2. **Authentication**: SSH key-based for Ubuntu deployment, stored Docker Hub credentials for CI
3. **Docker Compose Strategy**: Separate files for dev (build) vs production (pull)
4. **Scripts**: PowerShell for Windows dev machine, Bash for Ubuntu operations
5. **Image Naming**: Using environment variables in docker-compose for flexible image references
6. **Playwright Testing**: Create reusable test suite, verify after each major phase, test both local and deployed environments

## Notes & Considerations
- Docker Hub repository must exist (e.g., `username/aspireapp-webfrontend`, `username/aspireapp-apiservice`)
- SSH key must be set up between Windows dev machine and Ubuntu server
- User on Ubuntu machine (192.168.1.11) must have Docker permissions (in `docker` group)
- Existing Caddy reverse proxy setup (192.168.1.2) remains unchanged
- GitHub Actions will need DOCKERHUB_USERNAME and DOCKERHUB_TOKEN secrets configured
- The PowerShell script assumes SSH client is available (Windows 10+ includes OpenSSH)
- Production docker-compose will respect existing environment variables for customization
- **Playwright Testing**:
  - Tests will verify: page loads, weather API integration, health endpoints, navigation
  - Will test against multiple environments: localhost, 192.168.1.11:8080, app.nganfamily.com
  - Playwright MCP will be used for interactive verification during implementation
  - Test suite will be reusable for future CI/CD integration
