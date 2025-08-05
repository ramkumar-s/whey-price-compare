# GitHub Workflows - AI Assistant Context

## CI/CD Strategy Overview

This directory contains GitHub Actions workflows implementing a comprehensive CI/CD pipeline with automated testing, security scanning, and deployment automation.

### Workflow Architecture
```
GitHub Actions Pipeline:
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Pre-commit    │    │   CI Pipeline   │    │ CD Pipelines    │
│   (Quality)     │────│   (Testing)     │────│ (Deployment)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Workflow Files

### `ci-new.yml` - Continuous Integration Pipeline
**Trigger**: Pull requests and pushes to main
**Duration**: ~15 minutes total
**Strategy**: 4-tier testing with service matrix

#### Testing Tiers (Sequential)
1. **Critical Tests** (2 minutes): Fast feedback for basic functionality
2. **Comprehensive Tests** (15 minutes): Full test suite with coverage
3. **Integration Tests** (10 minutes): Service interactions with TestContainers
4. **E2E Tests** (15 minutes): Complete user journey testing

#### Service Matrix Testing
- **API Service**: Core HTTP server and business logic
- **Scraper Service**: Price collection and anti-detection
- **MCP Service**: AI assistant integration server

#### Quality Gates
- **Code Coverage**: 80% minimum for critical paths
- **Security Scanning**: gosec for Go security issues
- **Linting**: golangci-lint with comprehensive rules
- **Bundle Size**: <14KB enforcement for frontend assets
- **Performance**: API response time validation

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

#### Quality Checks
- **Code Formatting**: gofmt, goimports
- **Linting**: golangci-lint with custom rules
- **Security**: gosec security vulnerability scanning
- **Dependencies**: Dependabot integration for updates
- **Tests**: Critical test suite only (fast feedback)

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

## Best Practices for AI Assistants

### When Modifying Workflows
1. **Test Locally**: Use `act` or similar tools to test workflows locally
2. **Incremental Changes**: Make small, testable changes
3. **Documentation**: Update this file when making workflow changes
4. **Monitoring**: Monitor workflow performance after changes

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