# Whey Protein Price Comparison Platform - AI Assistant Context

## Project Overview
Ultra-fast (<14KB, <500ms) whey protein price comparison platform built with Go backend and vanilla JavaScript frontend, optimized for affiliate revenue conversion across Indian e-commerce retailers.

## Critical Performance Requirements
- **Bundle Size**: <14KB total (HTML + CSS + JS) - HARD REQUIREMENT
- **Page Load**: <500ms on 3G connections
- **API Response**: <50ms cached, <200ms database queries
- **Uptime**: 99.9% availability target
- **Scraping Success**: >95% across all retailers

## Architecture Overview
- **Backend**: Go + Gin framework + GORM + PostgreSQL + Redis
- **Frontend**: Server-side rendered HTML + vanilla JavaScript
- **Scraping**: Go + Colly with anti-detection (proxy rotation, rate limiting)
- **Authentication**: JWT + OAuth2 (Google, GitHub, Facebook) + GDPR compliant
- **Deployment**: Docker + K3s + NGINX + Let's Encrypt
- **Monitoring**: Prometheus + Grafana + Jaeger + AlertManager

## Key Business Logic
- **User-Driven Scraping**: Users search → products discovered → scraping queue
- **Configurable Rate Limits**: Per retailer (Amazon 15/min, Flipkart 12/min, etc.)
- **Price Validation**: 0.1x-10x ranges, confidence scoring, manual review queue
- **Multi-Tier Users**: Public, User, Premium, Admin, Super Admin
- **Affiliate Optimization**: Click tracking, A/B testing ready

## Development Approach
- **Database**: PostgreSQL production, SQLite development (compatible queries)
- **Testing**: 4-tier (Critical <2min, Comprehensive <15min, Integration <10min, E2E <15min)
- **CI/CD**: GitHub Actions with automated staging, manual production
- **Code Quality**: 80% test coverage, golangci-lint, gosec, SonarCloud

## Current Sprint Status
**Active Workflow**: `ci-sprint-1.yml` (Foundation MVP)

Check `docs/project/project_plan.md` for detailed sprint breakdown:
- **Sprint 1** (Active): Foundation MVP (database, API, scraping, <14KB frontend)
- **Sprint 2**: Authentication & enhanced scraping (4 retailers, price alerts)
- **Sprint 3**: User features (favorites, recommendations, data quality)
- **Sprint 4**: API excellence & MCP integration (B2B API, AI tools)
- **Sprint 5-6**: Monitoring, CI/CD, production deployment
- **Sprint 7-8**: Optimization, advanced features, launch prep

### Progressive CI/CD System
The project uses sprint-based CI workflows that only test implemented components:
- `ci-sprint-1.yml` - Foundation testing (currently active)
- `ci-sprint-2.yml` - Authentication & enhanced features  
- `ci-sprint-3.yml` - User experience & data quality
- `ci-sprint-4.yml` - API excellence & MCP integration
- `ci-new.yml` - Full production workflow (Sprint 5+)

**Workflow Activation**: See `.github/CLAUDE.md` for step-by-step activation guide

## Important File Locations
- **Database Schemas**: `deployments/postgres/migrations/` and `deployments/sqlite/`
- **Documentation**: `docs/` (architecture, development guides, API specs)
- **CI/CD**: `.github/workflows/` (ci-new.yml, cd-staging.yml, cd-production.yml)
- **Configuration**: `Makefile`, `go.mod`, `docker-compose.*.yml`

## Common Commands
```bash
# Development setup
make setup-sqlite          # Create SQLite dev database
make dev                   # Start Docker development stack
make run-api               # Run API server locally

# Testing
make test-critical         # Fast tests (<2min)
make test-all             # Full test suite
make validate-bundle-size  # Check <14KB requirement

# Database
make sqlite-shell         # Open SQLite console
make migrate-up           # Apply PostgreSQL migrations
```

## AI Assistant Guidelines
1. **Performance First**: Always consider <14KB bundle size impact
2. **GORM Compatible**: Use database-agnostic queries for SQLite/PostgreSQL
3. **Security Conscious**: Never log secrets, use encrypted PII storage
4. **Test-Driven**: Write tests for new functionality
5. **Documentation**: Update relevant docs when making changes
6. **Sprint Awareness**: Check current sprint goals in project plan
7. **Comprehensive Logging**: Use Uber Zap for all services and tests

## Logging Requirements for Claude Code
- **Library**: Use `go.uber.org/zap` for all logging (already in go.mod)
- **Test Visibility**: All tests MUST log to stdout for Claude Code visibility
- **Structured Logs**: Use JSON in production, console format in development/tests
- **Log Levels**: DEBUG for detailed flow, INFO for operations, ERROR for failures
- **Required Fields**: operation, request_id, service_name, timestamp
- **Bundle Size**: Log bundle size validation (<14KB requirement)

### Logging Patterns for Claude Code
```go
// Service logging pattern
func (s *Service) Method(ctx context.Context) error {
    logger := s.logger.With(
        zap.String("operation", "Method"),
        zap.String("request_id", GetRequestID(ctx)),
    )
    logger.Debug("Starting operation")
    // ... business logic
    logger.Info("Operation completed successfully")
    return nil
}

// Test logging pattern  
func TestMethod(t *testing.T) {
    logger := SetupTestLogger(t) // Always outputs to stdout
    logger.Info("Starting test", zap.String("test", "TestMethod"))
    // ... test logic
    logger.Info("Test completed", zap.Bool("passed", true))
}
```

## Quick Reference Links
- **Project Plan**: `docs/project/project_plan.md`
- **Architecture**: `docs/architecture/architecture_doc.md`
- **API Spec**: `docs/api/api_specification_complete.md`
- **Auth Strategy**: `docs/development/authentication_strategy.md`
- **Scraper Framework**: `docs/development/scraper_framework.md`
- **Local Setup**: `docs/development/local_setup.md`