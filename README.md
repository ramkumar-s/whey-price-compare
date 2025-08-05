# Whey Protein Price Comparison Platform

A ultra-fast, lightweight price comparison platform for whey protein products across major Indian e-commerce retailers. Built with Go backend and vanilla JavaScript frontend optimized for affiliate revenue conversion.

## 🎯 Key Features

- **Lightning Fast**: <14KB initial page load, <500ms load time on 3G
- **Comprehensive Coverage**: Price comparison across Amazon, Flipkart, HealthKart, Nutrabay
- **Real-time Updates**: Automated price scraping every 30 minutes
- **Smart Search**: Full-text search with brand, flavor, and weight filtering
- **Affiliate Optimized**: Fast loading maximizes click-through rates to retailer sites
- **MCP Integration**: Model Context Protocol server for AI assistant integrations
- **User Features**: Price alerts, favorites, personalized recommendations (requires account)
- **Multi-Auth**: Email/password + social login (Google, GitHub, Facebook)
- **API Access**: Freemium B2B API with rate limiting and analytics
- **GDPR Compliant**: Encrypted PII storage, data export/deletion, consent management

## 🚀 Quick Start

### Prerequisites
- Go 1.21+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose

### Local Development
```bash
# Clone repository
git clone https://github.com/yourusername/whey-price-compare.git
cd whey-price-compare

# Start dependencies
docker-compose -f docker-compose.dev.yml up -d

# Run database migrations
make migrate-up

# Start API server
make run-api

# Start scraper service
make run-scraper

# Start MCP server (optional)
make run-mcp

# Visit http://localhost:8080
```

## 🏗️ Architecture

### Tech Stack
- **Backend**: Go with Gin framework
- **Frontend**: Vanilla JavaScript (<14KB bundle)
- **Database**: PostgreSQL + Redis
- **Scraping**: Go with Colly
- **Monitoring**: Prometheus + Grafana + Jaeger
- **Deployment**: Docker + K3s

### Performance Targets
- **Bundle Size**: <14KB initial load (HTML + CSS + JS)
- **API Response**: <50ms cached, <200ms database queries  
- **Page Load**: <500ms on 3G connections
- **Uptime**: 99.9% availability
- **Scraping**: >95% success rate

## 📁 Project Structure

```
├── cmd/
│   ├── api/                    # API server
│   ├── scraper/               # Price scraper service
│   └── mcp/                   # MCP server for AI integrations
├── internal/
│   ├── domain/                # Business logic
│   ├── handlers/              # HTTP handlers
│   ├── repositories/          # Data access
│   ├── services/              # Business services
│   ├── scrapers/              # Extensible scraper framework
│   └── mcp/                   # MCP protocol implementation
├── pkg/
│   ├── logger/                # Structured logging
│   ├── telemetry/             # OpenTelemetry setup
│   └── testutils/             # Test utilities
├── web/
│   ├── static/                # Static assets (<14KB total)
│   └── templates/             # Go templates
├── tests/
│   ├── unit/                  # Unit tests
│   ├── integration/           # Integration tests
│   ├── contracts/             # Contract tests
│   └── e2e/                   # End-to-end tests
├── deployments/
│   ├── docker/                # Docker configurations
│   ├── k8s/                   # Kubernetes manifests
│   ├── nginx/                 # NGINX configuration
│   ├── postgres/              # Database setup
│   ├── prometheus/            # Monitoring setup
│   └── grafana/               # Dashboard configs
├── scripts/                   # Build and deployment scripts
├── docs/                      # Documentation
│   ├── api/                   # API specification
│   ├── architecture/          # System architecture
│   ├── deployment/            # Deployment guides
│   └── development/           # Development guides (includes CI/CD strategy)
├── .github/
│   └── workflows/             # GitHub Actions CI/CD pipelines
│       ├── ci.yml             # Continuous Integration
│       ├── cd-staging.yml     # Staging deployment  
│       ├── cd-production.yml  # Production deployment
│       └── pre-commit.yml     # Pre-commit validation
└── scripts/                   # Deployment and automation scripts
```

## 🧪 Testing Strategy

### Test-Driven Development (TDD)
- **Unit Tests**: 80%+ code coverage with Go testing + testify
- **Integration Tests**: Real database testing with testcontainers
- **Contract Tests**: API contract validation with pact-go
- **E2E Tests**: Complete user journeys with playwright-go
- **Load Tests**: Performance validation with k6

### Running Tests
```bash
# Unit tests
make test-unit

# Integration tests  
make test-integration

# E2E tests
make test-e2e

# All tests with coverage
make test-all

# Load testing
make test-load
```

## 📊 Observability

### Structured Logging
- **Library**: zap with JSON output
- **Trace IDs**: Automatic correlation across services
- **Context**: Request tracing with OpenTelemetry

### Metrics & Monitoring
- **Metrics**: Prometheus with custom business metrics
- **Tracing**: Jaeger for distributed tracing
- **Dashboards**: Grafana for visualization
- **Alerting**: AlertManager for critical issues

### Key Metrics Tracked
- API response times and error rates
- Price scraping success rates
- User engagement and affiliate clicks
- Infrastructure resource utilization

## 🔧 Development

### Prerequisites Setup
```bash
# Install Go dependencies
go mod download

# Install development tools
make install-tools

# Setup pre-commit hooks
make setup-hooks
```

### AI-Assisted Development
This project is optimized for AI-assisted development:
- Clear interfaces for easy mock generation
- Comprehensive test coverage for safe refactoring
- Structured logging for debugging
- Contract-first API design

### Code Quality & CI/CD
- **Linting**: golangci-lint with comprehensive rules
- **Formatting**: gofmt + goimports  
- **Security**: gosec vulnerability scanning, SonarQube integration
- **Documentation**: godoc for all public APIs
- **CI/CD**: GitHub Actions with automated staging, manual production deployment
- **Testing**: Critical tests (<2min), comprehensive tests, integration & E2E
- **Deployment**: Rolling updates with blue-green capability

## 🚀 Deployment

### Staging Environment
```bash
# Deploy to staging
make deploy-staging

# Run integration tests
make test-staging
```

### Production Deployment
```bash
# Build production images
make build-prod

# Deploy with zero-downtime
make deploy-prod

# Health check
make health-check
```

### Infrastructure
- **Hosting**: Self-hosted on Hetzner/DigitalOcean VPS
- **Orchestration**: K3s for container management
- **SSL**: Let's Encrypt automated certificates
- **Monitoring**: Self-hosted Prometheus stack

## 🛡️ Security

- **HTTPS Everywhere**: All communications encrypted
- **Input Validation**: Comprehensive request validation
- **Rate Limiting**: API abuse protection
- **Dependency Scanning**: Automated vulnerability checks
- **Audit Logging**: Complete audit trail

## 📈 Scalability

### Current Capacity
- **Traffic**: 10k+ requests/second on single VPS
- **Storage**: Millions of price data points
- **Scraping**: 4 retailers, 1000+ products

### Scaling Strategy
- **Horizontal**: Stateless services with load balancing
- **Database**: Read replicas and connection pooling
- **Cache**: Redis clustering for high availability
- **CDN**: Static asset distribution

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Write failing tests (TDD approach)
3. Implement minimal code to pass tests
4. Refactor while keeping tests green
5. Submit PR with test coverage

### Code Review Process
- Automated checks (linting, testing, security)
- Manual review for logic and architecture
- Performance impact assessment
- Contract compatibility verification

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [docs/](docs/)
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Monitoring**: Grafana dashboards at `/monitoring`

## 🎯 Roadmap

### Month 1: MVP
- [x] Core API with 4 retailers
- [x] Basic web interface
- [x] Automated scraping
- [x] Production deployment

### Month 2-3: Enhancement  
- [ ] Advanced filtering and search
- [ ] Price history and alerts
- [ ] Performance optimization
- [ ] Additional retailers

### Month 4+: Scale
- [ ] Mobile app (React Native)
- [ ] Price prediction ML models  
- [ ] B2B API monetization
- [ ] Multi-category expansion
- [ ] Enhanced MCP tools for complex price analysis
- [ ] AI-powered product recommendations via MCP

---

Built with ❤️ for the Indian fitness community. Optimized for speed, reliability, and affiliate revenue conversion.