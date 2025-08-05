# System Architecture

## Overview

The Whey Protein Price Comparison Platform is designed as a microservices architecture optimized for performance, scalability, and maintainability. The system prioritizes ultra-fast page loads (<14KB, <500ms) to maximize affiliate conversion rates while maintaining enterprise-grade reliability.

## High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │────│   NGINX Proxy   │────│   Go API Server │
│   (<14KB load)  │    │  (SSL/Compress) │    │   (Gin + GORM)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
┌─────────────────┐    ┌─────────────────┐             │
│  AI Assistants  │────│   MCP Server    │─────────────┤
│ (Claude/ChatGPT)│    │ (Go + API Keys) │             │
└─────────────────┘    └─────────────────┘             │
                                                        │
┌─────────────────┐    ┌─────────────────┐             │
│ OAuth Providers │────│   Auth Service  │─────────────┤
│(Google/GitHub/FB)│    │ (JWT + OAuth2)  │             │
└─────────────────┘    └─────────────────┘             │
                                                        │
                       ┌─────────────────┐             │
                       │  Scraper Service│─────────────┤
                       │  (Go + Colly)   │             │
                       └─────────────────┘             │
                                                        │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │────│     Redis       │────│  Observability │
│ (User Data +    │    │(Sessions/Cache) │    │ (Prom/Graf/Jag) │
│  Product Data)  │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Components

### 1. API Server (Go + Gin)

**Purpose**: Main application server handling HTTP requests

**Responsibilities**:
- Serve server-side rendered HTML pages (<14KB)
- Provide REST API for price data
- Handle user search and filtering
- Manage affiliate link generation
- Implement rate limiting and caching

**Key Features**:
- Sub-50ms response times for cached data
- Structured logging with trace IDs
- Comprehensive metrics collection
- Graceful degradation under load

**Interfaces**:
```go
type PriceService interface {
    GetProductPrices(ctx context.Context, productID string) ([]Price, error)
    SearchProducts(ctx context.Context, query SearchQuery) ([]Product, error)
}

type ProductRepository interface {
    FindByID(ctx context.Context, id string) (*Product, error)
    Search(ctx context.Context, query string) ([]Product, error)
}
```

### 2. Authentication Service (Go + JWT + OAuth2)

**Purpose**: Comprehensive user authentication and authorization

**Responsibilities**:
- Multi-provider OAuth2 integration (Google, GitHub, Facebook)
- JWT token generation and validation
- User registration and profile management
- Role-based access control (RBAC)
- API key management for B2B customers
- GDPR compliance and data protection

**Key Features**:
- Social login with account linking
- Encrypted PII storage (AES-256)
- Rate limiting per user tier
- Session management with Redis
- Multi-factor authentication for admins
- Comprehensive audit logging

**Authentication Tiers**:
```go
type UserTier string

const (
    TierPublic     UserTier = "public"      // No auth required
    TierUser       UserTier = "user"        // Basic features
    TierPremium    UserTier = "premium"     // High API limits
    TierAdmin      UserTier = "admin"       // Platform management
    TierSuperAdmin UserTier = "super_admin" // Full access
)
```

**JWT Token Structure**:
- Access tokens: 15 minutes (stateless)
- Refresh tokens: 7 days (stored in Redis)
- Role and permission claims
- Automatic token rotation

### 3. MCP Server (Go + JSON-RPC)

**Purpose**: Model Context Protocol server for AI assistant integrations

**Responsibilities**:
- Provide standardized interface for AI assistants (Claude, ChatGPT, etc.)
- Expose price comparison tools and data access methods
- Handle complex price analysis queries from AI systems
- Maintain session context for multi-turn conversations
- Validate and sanitize AI-generated requests

**Key Features**:
- JSON-RPC 2.0 protocol implementation
- Tool discovery and capability advertisement
- Real-time price data access for AI queries
- Product recommendation and comparison tools
- Historical price analysis capabilities

**MCP Tools Exposed**:
```go
type MCPTools interface {
    SearchProducts(query string, filters ProductFilters) ([]Product, error)
    CompareProducts(productIDs []string) (*ProductComparison, error)
    GetPriceHistory(productID string, days int) (*PriceHistory, error)
    FindBestDeals(criteria DealCriteria) ([]Deal, error)
    AnalyzePriceTrends(productID string) (*TrendAnalysis, error)
    GetNutritionComparison(productIDs []string) (*NutritionComparison, error)
}
```

**Protocol Features**:
- Server initialization and capability negotiation
- Tool discovery with parameter schemas
- Progress notifications for long-running operations
- Error handling with detailed diagnostics
- Resource access with proper permission controls

### 4. Scraper Service (Go + Colly)

**Purpose**: User-driven, configurable price collection from retailer websites

**Responsibilities**:
- User-driven product discovery through search requests
- Queue-based scraping with configurable intervals per retailer/category
- Anti-detection measures with proxy and user-agent rotation
- Price validation and quality assurance
- Configurable rate limiting respecting retailer constraints
- Handle anti-bot measures (rate limiting, proxy rotation)
- Validate and normalize extracted data
- Queue failed scrapes for retry
- Monitor scraping success rates

**Extensible Design**:
```go
type ProductScraper interface {
    ScrapeProduct(ctx context.Context, url string) (*ScrapedProduct, error)
    GetRetailerInfo() RetailerInfo
    ValidateURL(url string) bool
    GetRateLimit() time.Duration
}
```

**Supported Retailers**:
- Amazon India
- Flipkart
- HealthKart
- Nutrabay

**Key Features**:
- User-driven product discovery queue
- Configurable scraping intervals per retailer and category
- Anti-detection with proxy rotation and user-agent spoofing
- Price validation rules (configurable 0.1x-10x ranges)
- 15% failure rate tolerance (configurable per retailer)
- Queue-based processing with priority scheduling

**Scraper Workflow**:
```go
type ScrapingWorkflow interface {
    // User-driven discovery
    RequestProductDiscovery(ctx context.Context, request DiscoveryRequest) error
    ProcessDiscoveryQueue(ctx context.Context) error
    
    // Regular scraping
    ScheduleScrapingTasks(ctx context.Context) error
    ProcessScrapingQueue(ctx context.Context) error
    
    // Anti-detection
    RotateProxies() error
    RotateUserAgents() error
    RespectRateLimit(retailerID string) error
}
```

**Configuration Per Retailer**:
- **Amazon India**: 15 req/min, 600 req/hour, proxy rotation enabled
- **Flipkart**: 12 req/min, 500 req/hour, proxy rotation enabled  
- **HealthKart**: 10 req/min, 400 req/hour, proxy rotation enabled
- **Nutrabay**: 8 req/min, 300 req/hour, proxy rotation enabled

**Data Quality Measures**:
- Price validation against historical averages
- Outlier detection and flagging
- Confidence scoring (0.0-1.0) 
- Manual review queue for suspicious data

### 5. Frontend (Vanilla JavaScript)

**Purpose**: Ultra-lightweight web interface optimized for conversion

**Bundle Size Breakdown**:
- HTML (server-rendered): ~2KB compressed
- Critical CSS (inlined): ~3KB compressed  
- JavaScript (vanilla): ~8KB compressed
- **Total**: 13KB (1KB safety margin)

**Key Features**:
- Progressive enhancement (works without JS)
- Real-time search with debouncing
- Responsive design for mobile/desktop
- Optimized affiliate link handling
- Service worker for offline caching

**Performance Optimizations**:
- Critical CSS inlined in HTML
- Non-critical resources loaded asynchronously
- Image lazy loading
- DNS prefetching for retailer domains

### 6. Database Layer

#### PostgreSQL (Primary Database)
**Product Catalog**:
- **Brands**: The Whole Truth, Optimum Nutrition, MuscleBlaze, Dymatize, etc.
- **Categories**: Hierarchical structure (Protein → Whey → Isolate/Concentrate)
- **Products**: Base products with nutritional info and truthified testing field
- **Product Variants**: Flavor and size combinations with normalized weights
- **Retailers**: Configuration for scraping intervals, rate limits, anti-detection
- **Product Listings**: Product availability and current prices per retailer
- **Price History**: Complete price change tracking with datetime stamps

**User Management**:
- **Users**: Encrypted user accounts with GDPR compliance
- **Authentication**: OAuth providers, API keys, roles, sessions
- **User Features**: Configurable price alerts, favorites, search history (anonymized)
- **User Preferences**: Thresholds, notifications, privacy settings

**Scraping System**:
- **Discovery Queue**: User-driven product search requests
- **Scraping Queue**: Aggregated scraping tasks with priority scheduling
- **Category Config**: Per-category scraping intervals and thresholds
- **Price Validation**: Configurable validation rules per category

**Compliance & Operations**:
- **GDPR Requests**: Data processing, export, deletion tracking
- **Audit Logs**: Security and compliance audit trail
- **Rate Limiting**: API usage tracking per user/IP/key
- **Notifications**: Email, push, SMS delivery queue

#### Redis (Cache + Message Queue + Sessions)
- **Caching**: API responses, search results, price data
- **Session Management**: JWT refresh tokens, user sessions
- **Message Queue**: Scraping jobs and notifications
- **Rate Limiting**: API rate limiting counters per user/IP/API key
- **Authentication**: Token blacklisting, OAuth state

**Data Flow**:
```
API Request → Redis Cache Check → PostgreSQL Query → Cache Update → Response
```

## Service Communication

### Synchronous Communication
- **API ↔ Database**: Direct GORM queries with connection pooling
- **API ↔ Cache**: Redis client with connection reuse
- **Frontend ↔ API**: HTTP/1.1 with keep-alive + JWT authentication
- **MCP ↔ API**: Internal Go function calls and shared services
- **AI Assistants ↔ MCP**: JSON-RPC 2.0 over stdio/TCP with API key auth
- **OAuth Providers ↔ Auth Service**: HTTPS OAuth2 flows
- **Admin Dashboard ↔ API**: Authenticated API calls with enhanced security

### Asynchronous Communication  
- **Scraper Jobs**: Redis Streams for job queuing
- **Price Updates**: Event-driven updates via Redis pub/sub
- **Notifications**: Background processing for user alerts

## Data Architecture

### Database Schema

```sql
-- Core entities
CREATE TABLE brands (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    logo_url VARCHAR(255)
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    brand_id INTEGER REFERENCES brands(id),
    name VARCHAR(200) NOT NULL,
    flavor VARCHAR(100),
    weight_grams INTEGER,
    protein_per_serving DECIMAL(5,2)
);

CREATE TABLE retailers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    domain VARCHAR(255),
    affiliate_tag VARCHAR(50)
);

-- Price tracking
CREATE TABLE product_prices (
    id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(id),
    retailer_id INTEGER REFERENCES retailers(id),
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    in_stock BOOLEAN DEFAULT true,
    product_url VARCHAR(500),
    scraped_at TIMESTAMP DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX idx_prices_product_retailer ON product_prices(product_id, retailer_id);
CREATE INDEX idx_prices_scraped_at ON product_prices(scraped_at DESC);
CREATE INDEX idx_products_search ON products USING gin(to_tsvector('english', name));
```

### Caching Strategy

**Cache Layers**:
1. **L1 - API Response Cache**: 5-15 minutes TTL
2. **L2 - Database Query Cache**: 30-60 minutes TTL  
3. **L3 - Search Results Cache**: 1-2 hours TTL
4. **L4 - Static Content Cache**: 24 hours TTL

**Cache Keys Pattern**:
```
prices:{product_id}                 # Product price list
search:{query_hash}                 # Search results
product:{product_id}                # Product details
retailer:{retailer_id}:products     # Retailer catalog
```

## Observability Architecture

### Structured Logging
- **Format**: JSON with consistent field naming
- **Trace IDs**: Distributed tracing correlation
- **Log Levels**: Debug, Info, Warn, Error
- **Context**: Request metadata and user context

### Metrics Collection
```go
// Key metrics tracked
var (
    requestDuration = prometheus.NewHistogramVec(...)
    priceUpdates = prometheus.NewCounterVec(...)
    scrapeSuccess = prometheus.NewGaugeVec(...)
    activeUsers = prometheus.NewGauge(...)
)
```

### Distributed Tracing
- **Tracer**: OpenTelemetry with Jaeger backend
- **Spans**: HTTP requests, database queries, external calls
- **Context Propagation**: Trace context across service boundaries
- **Sampling**: 100% for errors, 10% for success in production

## Security Architecture

### Transport Security
- **HTTPS Everywhere**: TLS 1.3 with strong cipher suites
- **HSTS**: HTTP Strict Transport Security headers
- **Certificate Management**: Let's Encrypt with auto-renewal

### Application Security
- **Input Validation**: Comprehensive request validation
- **SQL Injection**: Parameterized queries only
- **XSS Protection**: Content Security Policy headers
- **Rate Limiting**: Per-IP and per-user limits

### Infrastructure Security
- **Network**: VPC with security groups
- **Secrets Management**: Environment variables + secret rotation
- **Container Security**: Non-root containers, minimal base images
- **Monitoring**: Security event logging and alerting

## Scalability Design

### Horizontal Scaling
- **Stateless Services**: No server-side sessions
- **Load Balancing**: NGINX with round-robin/least-connections
- **Database Scaling**: Read replicas for query scaling
- **Cache Scaling**: Redis Cluster for distributed caching

### Performance Optimizations
- **Connection Pooling**: Database and Redis connection reuse
- **Query Optimization**: Proper indexing and query analysis
- **Compression**: Gzip compression for all responses
- **CDN**: Static asset distribution (future enhancement)

### Resource Limits
```yaml
# Container resource limits
api:
  memory: 512Mi
  cpu: 500m
mcp:
  memory: 128Mi
  cpu: 100m
scraper:
  memory: 256Mi  
  cpu: 200m
postgres:
  memory: 1Gi
  cpu: 1000m
redis:
  memory: 512Mi
  cpu: 200m
```

## Deployment Architecture

### Infrastructure
- **Platform**: Self-hosted VPS (Hetzner/DigitalOcean)
- **Orchestration**: K3s (lightweight Kubernetes)
- **Reverse Proxy**: NGINX with SSL termination
- **Monitoring**: Self-hosted Prometheus stack

### CI/CD Pipeline
```
Code Push → Automated Tests → Build Images → Deploy Staging → Integration Tests → Deploy Production
```

### Blue-Green Deployment
- **Zero Downtime**: Rolling updates with health checks
- **Rollback Strategy**: Automatic rollback on health check failures
- **Database Migrations**: Forward-compatible schema changes

## Disaster Recovery

### Backup Strategy
- **Database**: Daily automated backups with 30-day retention
- **Configuration**: Infrastructure as Code (Terraform/K8s manifests)
- **Monitoring Data**: 90-day retention for metrics and logs

### Recovery Procedures
- **RTO**: Recovery Time Objective < 30 minutes
- **RPO**: Recovery Point Objective < 5 minutes
- **Monitoring**: Automated health checks and alerting
- **Documentation**: Runbooks for common failure scenarios

## Future Architecture Considerations

### Microservices Evolution
- **User Service**: Authentication and user management
- **Notification Service**: Price alerts and communications  
- **Analytics Service**: Business intelligence and reporting
- **ML Service**: Price prediction and recommendation engine
- **Enhanced MCP Service**: Advanced AI tools and conversation management

### Technology Roadmap
- **Mobile App**: React Native with shared API
- **Real-time Updates**: WebSocket connections for live prices
- **Global CDN**: Geographic content distribution
- **Multi-region**: Active-active deployment across regions

---

This architecture provides a solid foundation for rapid development while supporting future scale and feature expansion.