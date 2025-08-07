# GitHub Workflows - AI Assistant Context

## Cost-Effective CI/CD Strategy Overview

This directory contains GitHub Actions workflows implementing a **cost-effective CI/CD strategy** that emphasizes **fast validation** in GitHub Actions (FREE for public repos) combined with comprehensive testing in local and staging environments.

### Workflow Architecture
```
Cost-Effective CI/CD Pipeline:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Actions│    │   Local Dev     │    │   Staging       │
│   (Fast & FREE) │    │   (Complete)    │    │   (Production)  │
│   Validation    │────│   Testing       │────│   Validation    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Active Workflow Files

### `ci-fast.yml` - Fast CI Validation Pipeline
**Trigger**: Every push and pull request  
**Duration**: <5 minutes total
**Cost**: FREE (unlimited minutes for public repositories)  
**Strategy**: Parallel execution for maximum speed
**Go Version**: 1.22+ (updated to fix govulncheck vulnerabilities)

#### Validation Jobs (Parallel)
1. **Code Validation** (2-3 minutes):
   - Go formatting check (`gofmt`, `goimports`)
   - Static analysis (`go vet`)
   - Fast unit tests (mocked dependencies, `-short` flag)
   - Build compilation verification (gracefully handles missing main.go files)

2. **Security & Quality** (3-5 minutes):
   - golangci-lint analysis
   - gosec security scanning (using github.com/securego/gosec)
   - govulncheck vulnerability checking (requires Go 1.22+)

3. **Bundle Size Validation** (1-2 minutes):
   - <14KB frontend bundle enforcement (enforced when implemented)
   - Asset optimization validation (gracefully handles missing frontend)

4. **Validation Summary**:
   - Consolidated results reporting
   - Next steps guidance for developers
   - Integration testing readiness notification

### `cd-staging.yml` - Staging Deployment
**Trigger**: Successful CI on main branch (automatic)
**Duration**: ~10 minutes
**Purpose**: Automated deployment to staging environment

#### Deployment Steps
1. **Build Production Images**: Multi-stage Docker builds
2. **Deploy to Staging**: K3s or Docker Compose deployment
3. **Health Checks**: Verify all services operational
4. **Smoke Tests**: Basic functionality validation
5. **Performance Tests**: k6 load testing
6. **Notification**: Slack/email deployment status

#### Staging Environment
- **Isolation**: Separate from production
- **Data**: Realistic test data, not production data  
- **Services**: All production services with monitoring
- **Access**: Internal team access for testing

### `cd-production.yml` - Production Deployment
**Trigger**: Manual approval after successful staging
**Duration**: ~15 minutes
**Purpose**: Safe, controlled production releases

#### Deployment Strategy
1. **Manual Approval**: Required human approval gate
2. **Database Migrations**: Expand-migrate-contract pattern
3. **Blue-Green Deployment**: Zero-downtime switching
4. **Health Validation**: Comprehensive health checks
5. **Rollback Capability**: Automatic rollback on failure

#### Production Safety
- **Approval Required**: No automatic production deployments
- **Backup Creation**: Database backup before deployment
- **Monitoring**: Real-time metrics during deployment
- **Circuit Breaker**: Automatic rollback on health check failure

### `pre-commit.yml` - Code Quality Pipeline  
**Trigger**: Pre-commit hooks (local) and PR validation
**Duration**: ~3 minutes
**Purpose**: Fast quality feedback before code review
**Go Version**: 1.22+ (updated to fix govulncheck vulnerabilities)

#### Quality Checks
- **Code Formatting**: gofmt, goimports
- **Linting**: golangci-lint with custom rules
- **Security**: gosec security vulnerability scanning (github.com/securego/gosec)
- **Build Verification**: Gracefully handles missing main.go files
- **Frontend Validation**: Optional checks (only runs if package.json exists)
- **Tests**: Critical test suite only (fast feedback)

## Workflow Implementation Notes

### Go Version Upgrade (January 2025)
- **Previous**: Go 1.21.13 
- **Current**: Go 1.22+
- **Reason**: Fix govulncheck vulnerabilities (GO-2025-3750, GO-2025-3447, GO-2025-3373)
- **Impact**: Both local development and CI/CD require Go 1.22+ for security compliance

### Missing Implementation Handling
The workflows are designed to gracefully handle missing implementations:

#### Backend Services (`cmd/` directories)
- **API**: `cmd/api/main.go` - Skipped if not found
- **Scraper**: `cmd/scraper/main.go` - Skipped if not found  
- **MCP Server**: `cmd/mcp/main.go` - Skipped if not found
- **Strategy**: Workflows check for main.go existence before build attempts

#### Frontend Assets (`web/static/`)
- **Package.json**: Workflows check for `web/static/package.json` before Node.js setup
- **Bundle Size**: Validation skipped if no frontend assets exist
- **Strategy**: <14KB enforcement deferred until frontend implementation

### Security Tool Corrections
- **Previous**: `securecodewarrior/github-action-gosec@master` (non-existent)
- **Current**: Manual `github.com/securego/gosec` installation
- **Benefit**: Uses official, free, open-source gosec tool
- **Note**: This is the correct repository for the gosec security scanner

## GitHub Actions Best Practices

### Workflow Configuration
```yaml
# Use specific action versions (not @main)
- uses: actions/checkout@v4
- uses: actions/setup-go@v4
  with:
    go-version: '1.21'

# Cache dependencies for faster builds
- uses: actions/cache@v3
  with:
    path: ~/go/pkg/mod
    key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
```

### Secret Management
- **GitHub Secrets**: Store sensitive values (API keys, tokens)
- **Environment Separation**: Different secrets for staging/production
- **Rotation**: Regular secret rotation with automation
- **Least Privilege**: Minimal required permissions

### Performance Optimization
- **Parallel Jobs**: Run independent jobs concurrently
- **Dependency Caching**: Cache Go modules, Docker layers
- **Selective Triggers**: Only run workflows when relevant files change
- **Resource Limits**: Appropriate timeout and resource allocation

## Integration Points

### External Services
- **SonarCloud**: Code quality and security analysis
- **Dependabot**: Automated dependency updates
- **Slack/Email**: Deployment notifications
- **Status Checks**: PR merge requirements

### Monitoring Integration
- **Deployment Tracking**: Tag releases in monitoring systems
- **Performance Baseline**: Compare performance before/after deployment
- **Error Monitoring**: Alert on deployment-related errors
- **Rollback Triggers**: Automated rollback on metric thresholds

## Security Considerations

### Code Security
- **SAST**: Static application security testing with gosec
- **Dependency Scanning**: Vulnerable dependency detection
- **Secret Scanning**: Prevent secret commits
- **License Compliance**: Open source license validation

### Deployment Security
- **Image Scanning**: Docker image vulnerability scanning
- **Supply Chain**: Verify build artifact integrity
- **Access Control**: Restrict production deployment permissions
- **Audit Logging**: All deployment actions logged

## Performance Targets

### CI Pipeline Performance
- **Critical Tests**: <2 minutes (fast feedback)
- **Full CI Pipeline**: <20 minutes total
- **Cache Hit Rate**: >90% for dependencies
- **Resource Usage**: Optimize for GitHub Actions limits

### Deployment Performance
- **Staging Deployment**: <10 minutes
- **Production Deployment**: <15 minutes (including approvals)
- **Rollback Time**: <5 minutes to previous version
- **Zero Downtime**: No user-facing service interruption

## Monitoring and Alerting

### Workflow Monitoring
- **Success Rate**: Track CI/CD success rates
- **Performance Trends**: Monitor build and deployment times
- **Failure Analysis**: Categorize and analyze failures
- **Resource Usage**: GitHub Actions minute consumption

### Deployment Health
- **Application Metrics**: Monitor key application metrics post-deployment
- **Error Rates**: Track error rate changes after deployment
- **Performance Impact**: Response time and throughput validation
- **User Impact**: Monitor user-facing metrics

## Troubleshooting Common Issues

### CI Pipeline Failures
1. **Test Failures**: Check test logs and potential flaky tests
2. **Build Failures**: Verify dependencies and Go version compatibility
3. **Timeout Issues**: Adjust timeout settings or optimize slow tests
4. **Resource Limits**: Check GitHub Actions resource consumption

### Deployment Failures
1. **Health Check Failures**: Verify service startup and dependencies
2. **Database Migration Issues**: Check migration compatibility
3. **Configuration Errors**: Validate environment variables and secrets
4. **Network Issues**: Verify service connectivity and DNS resolution

### Performance Issues
1. **Slow Builds**: Analyze cache hit rates and dependency resolution
2. **Slow Tests**: Identify and optimize expensive test cases
3. **Resource Exhaustion**: Monitor and optimize resource usage
4. **Deployment Delays**: Identify bottlenecks in deployment pipeline

## Comprehensive Testing Strategy

### Local Development Testing
For comprehensive validation, run locally where you have full control:

```bash
# Complete testing workflow
make test-critical         # Fast tests (<2min)
make test-integration      # Real database tests (5-10min)
make test-e2e             # Full stack tests (10-15min)
make test-performance     # Load testing with k6
make validate-bundle-size # Frontend optimization

# Development workflow
make dev                  # Start local Docker stack
make test-all            # Run all local tests
make clean               # Clean up test artifacts
```

### GitHub Actions Limitations & Alternatives

#### What GitHub Actions SHOULD do:
✅ **Fast validation** (formatting, linting, security)  
✅ **Build verification** (compilation, basic tests)  
✅ **Bundle size enforcement** (<14KB requirement)  
✅ **Security scanning** (static analysis, vulnerabilities)

#### What to do LOCALLY instead:
🏠 **Integration testing** (real databases, Redis)  
🏠 **End-to-end testing** (browser automation, user workflows)  
🏠 **Performance testing** (load testing, optimization)  
🏠 **Scraper testing** (real external API calls)

#### Cost Comparison:
- **GitHub Actions (Public Repo)**: FREE unlimited minutes
- **GitHub Actions (Private Repo)**: $0.008/minute after 2,000 free minutes
- **Local Development**: Hardware costs only, full control

### Staging Environment Integration

#### Staging Deployment Trigger
When GitHub Actions validation passes:
```bash
# Automatic staging deployment (future)
curl -X POST "https://staging.whey-price-compare.com/api/deploy" \
  -H "Authorization: Bearer ${{ secrets.STAGING_API_KEY }}" \
  -d '{"commit": "${{ github.sha }}"}'
```

#### Staging Validation
- Real external service integration
- Production-like data volumes  
- Performance under realistic load
- Cross-service communication testing

## Best Practices for AI Assistants

### When Modifying Workflows
1. **Test Locally**: Use `act` or similar tools to test workflows locally
2. **Incremental Changes**: Make small, testable changes
3. **Documentation**: Update this file when making workflow changes
4. **Monitoring**: Monitor workflow performance after changes
5. **No Sleep Commands**: Never use `sleep` or `wait` commands for GitHub Actions or CI/CD processes

### Async Process Management
**❌ Don't do this:**
```bash
git push origin main
sleep 30 && gh run list  # BAD: Blocks execution
```

**✅ Do this instead:**
```bash
git push origin main
# Ask user to check workflow status in 2-3 minutes
```

**Proper Pattern:**
1. Trigger the async process (git push, deployment, etc.)
2. Inform user what was triggered
3. Ask user to request status check after appropriate time
4. Use direct status commands when user asks

### Development Guidelines
- **Only Test What Exists**: Don't test unimplemented components
- **Clear Status Reporting**: Show what's done vs. what's needed
- **Bundle Size Focus**: Always enforce <14KB requirement
- **Performance Validation**: Include performance benchmarks where appropriate

### Common Workflow Patterns
- **Environment Variables**: Use for configuration, not secrets
- **Conditional Steps**: Use `if` conditions for optional steps
- **Matrix Builds**: Use for testing multiple configurations
- **Artifact Management**: Store and share build artifacts appropriately

### Security Guidelines
- **Never Hardcode Secrets**: Always use GitHub Secrets
- **Minimal Permissions**: Use least privilege principle
- **Validate Inputs**: Sanitize any user inputs in workflows
- **Audit Trail**: Ensure all actions are logged and traceable