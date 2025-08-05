# Deployments Directory - AI Assistant Context

## Deployment Strategy Overview

This directory contains all deployment configurations, database migrations, and infrastructure-as-code for the whey protein price comparison platform.

### Directory Structure
```
deployments/
├── postgres/
│   ├── migrations/           # PostgreSQL schema migrations
│   └── init-dev.sql         # Development database initialization
├── sqlite/
│   └── schema.sql           # SQLite development schema
├── grafana/
│   ├── provisioning/        # Grafana configuration
│   └── dashboards/          # Custom dashboards
├── prometheus/
│   └── prometheus-dev.yml   # Prometheus configuration
└── k3s/                     # Kubernetes manifests (future)
```

## Database Strategy

### Two-Database Approach
- **PostgreSQL**: Production database with advanced features
- **SQLite**: Development database for fast local setup
- **Compatibility**: All queries written to work on both databases using GORM

### Migration Strategy
**Expand-Migrate-Contract Pattern**:
1. **Expand**: Add new columns/tables without breaking existing code
2. **Migrate**: Update application code to use new schema
3. **Contract**: Remove old columns/tables after deployment

### Key Schema Files

#### PostgreSQL Migrations (`postgres/migrations/`)
- **`001_auth_schema.sql`**: Complete authentication system (609 lines)
  - Multi-tier users (Public, User, Premium, Admin, Super Admin)
  - OAuth providers (Google, GitHub, Facebook)
  - GDPR-compliant encrypted PII storage
  - Audit logging and session management
  
- **`002_product_catalog_schema.sql`**: Product catalog system (415 lines)
  - Brand → Category → Product → Variants hierarchy
  - The Whole Truth brand with truthified testing field
  - Retailer configurations with scraping parameters
  - Price history with datetime tracking
  - User-driven discovery and scraping queues

#### SQLite Schema (`sqlite/schema.sql`)
- **Compatible version** of PostgreSQL schema for development
- **Adaptations**: UUID as TEXT, BOOLEAN as INTEGER, JSON as TEXT
- **Test Data**: Sample brands, categories, products included

## Container Strategy

### Docker Compose Environments
- **`docker-compose.dev.yml`**: Development stack with all services
- **`docker-compose.staging.yml`**: Staging environment (future)
- **`docker-compose.prod.yml`**: Production deployment (future)

### Service Dependencies
```
API Server → PostgreSQL + Redis
Scraper → Redis (job queue) + PostgreSQL (results)
MCP Server → PostgreSQL (read-only)
Monitoring → Prometheus + Grafana + Jaeger
```

## Infrastructure Patterns

### Health Check Strategy
Every service implements:
- Application health endpoint (`/health`)
- Dependency health checks (database, Redis, external APIs)
- Graceful degradation under partial failures

### Resource Management
- **Connection Pooling**: Database connections shared across requests
- **Memory Limits**: Container memory limits to prevent OOM
- **CPU Limits**: Prevent resource starvation
- **Storage**: Persistent volumes for data, ephemeral for logs

### Security Hardening
- **Non-root containers**: All services run as non-privileged users
- **Network policies**: Restricted inter-service communication
- **Secrets management**: Environment variables, not embedded secrets
- **SSL/TLS**: All external communication encrypted

## Configuration Management

### Environment-Based Configuration
```bash
# Database
DATABASE_TYPE=postgres|sqlite
DATABASE_URL=connection_string
DATABASE_MAX_CONNECTIONS=20

# Cache
REDIS_URL=redis://localhost:6379
REDIS_MAX_CONNECTIONS=10

# Authentication
JWT_SECRET=secret_key
OAUTH_GOOGLE_CLIENT_ID=client_id
OAUTH_GOOGLE_CLIENT_SECRET=client_secret

# Scraping
SCRAPER_MODE=production|development
ENABLE_PROXY_ROTATION=true
DEFAULT_SCRAPE_INTERVAL_HOURS=24

# Monitoring
PROMETHEUS_URL=http://prometheus:9090
JAEGER_ENDPOINT=http://jaeger:14268/api/traces
```

### Feature Flags
- **Performance**: Enable/disable expensive features
- **Rollout**: Gradual feature rollout to user segments
- **Emergency**: Quick disable of problematic features

## Deployment Patterns

### Database Migration Workflow
```bash
# 1. Backup current database
make backup

# 2. Run migrations in test environment
make migrate-up-test

# 3. Validate application compatibility
make test-integration

# 4. Apply to production with rollback plan
make migrate-up
# If issues: make migrate-down
```

### Service Deployment Workflow
1. **Build**: Create Docker images with version tags
2. **Test**: Run full test suite against new images
3. **Deploy Staging**: Automatic deployment for testing
4. **Deploy Production**: Manual approval required
5. **Health Check**: Verify all services healthy
6. **Rollback Plan**: Previous version ready for quick rollback

### Zero-Downtime Deployment
- **Blue-Green Strategy**: Maintain two identical environments
- **Load Balancer**: Traffic switching between environments
- **Health Checks**: Automated traffic routing based on health
- **Database Compatibility**: Forward-compatible schema changes

## Monitoring and Observability

### Metrics Collection (Prometheus)
- **System Metrics**: CPU, memory, disk, network
- **Application Metrics**: Request rates, response times, error rates
- **Business Metrics**: User signups, searches, affiliate clicks
- **Infrastructure Metrics**: Database connections, cache hit rates

### Alerting Rules
```yaml
# Critical alerts (immediate response)
- High error rate (>1% for 5 minutes)
- Response time >500ms for 10 minutes
- Database connection failures
- Scraper success rate <80%

# Warning alerts (next business day)
- Disk usage >80%
- Memory usage >85%
- Cache hit rate <90%
- User signup rate decline
```

### Log Aggregation
- **Structured Logging**: JSON format with consistent fields
- **Correlation IDs**: Track requests across services
- **Log Levels**: Debug, Info, Warn, Error with appropriate filtering
- **Retention**: 30 days for application logs, 1 year for audit logs

## Security Considerations

### Network Security
- **Firewalls**: Only necessary ports exposed
- **VPC/Network Isolation**: Services in private networks
- **SSL Certificates**: Let's Encrypt with automatic renewal
- **Rate Limiting**: API rate limiting to prevent abuse

### Data Security
- **Encryption at Rest**: Database encryption for PII
- **Encryption in Transit**: TLS for all communications
- **Access Control**: Role-based access to production systems
- **Audit Logging**: All system access and changes logged

### GDPR Compliance
- **Data Minimization**: Only collect necessary data
- **Right to Access**: User data export functionality
- **Right to Erasure**: Account deletion with data anonymization
- **Data Retention**: Automatic cleanup of expired data

## Performance Optimization

### Caching Strategy
- **Application Cache**: Redis for API responses
- **Database Query Cache**: PostgreSQL query plan caching
- **CDN**: Static asset distribution (future)
- **Browser Cache**: Appropriate cache headers for static content

### Database Optimization
- **Indexing**: Strategic indexes for common queries
- **Connection Pooling**: Reuse database connections
- **Read Replicas**: Distribute read queries (future scaling)
- **Query Optimization**: Regular query performance analysis

## Disaster Recovery

### Backup Strategy
- **Database Backups**: Daily full backups, hourly incrementals
- **Configuration Backups**: Version-controlled infrastructure code
- **Application Backups**: Docker images with version tags
- **Testing**: Monthly backup restoration tests

### Recovery Procedures
- **RTO (Recovery Time Objective)**: 30 minutes for complete system recovery
- **RPO (Recovery Point Objective)**: Maximum 1 hour data loss
- **Failover**: Automated failover for critical services
- **Communication**: Status page and user notification procedures

## Development vs Production Differences

### Development Environment
- **SQLite Database**: Fast local development
- **Mock Services**: Email, payment processing mocked
- **Debug Logging**: Verbose logging for troubleshooting
- **Hot Reload**: Automatic service restart on code changes

### Production Environment
- **PostgreSQL Database**: Full-featured production database
- **External Services**: Real email, payment, monitoring services
- **Optimized Logging**: Structured logging with appropriate levels
- **Health Monitoring**: Comprehensive health checks and alerting

### Staging Environment
- **Production-like**: Same services and configuration as production
- **Test Data**: Realistic but not real user data
- **Performance Testing**: Load testing with k6
- **Security Testing**: Automated security scanning