# Command Line Applications - AI Assistant Context

## Service Architecture
Three main Go services with distinct responsibilities:

### API Server (`cmd/api/`)
**Purpose**: Main HTTP server handling web requests and REST API
**Port**: 8080
**Key Features**:
- Server-side rendered HTML (part of <14KB bundle requirement)
- REST API endpoints for product search, price comparison
- User authentication (JWT + OAuth2)
- Rate limiting per user tier
- Affiliate link generation and tracking

**Dependencies**:
- PostgreSQL/SQLite for data persistence
- Redis for caching and sessions
- External OAuth providers (Google, GitHub, Facebook)

**Environment Variables**:
```bash
DATABASE_TYPE=sqlite|postgres
DATABASE_URL=data/sqlite/dev.db|postgres://...
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key
OAUTH_GOOGLE_CLIENT_ID=...
LOG_LEVEL=debug|info|warn|error
```

### Scraper Service (`cmd/scraper/`)
**Purpose**: Price data collection from e-commerce retailers
**Key Features**:
- User-driven product discovery (search requests → scraping queue)
- Configurable rate limiting per retailer
- Anti-detection: proxy rotation, user-agent spoofing
- Price validation and confidence scoring
- Queue-based processing with Redis

**Supported Retailers**:
- Amazon India (15 req/min, 600 req/hour)
- Flipkart (12 req/min, 500 req/hour)
- HealthKart (10 req/min, 400 req/hour)
- Nutrabay (8 req/min, 300 req/hour)

**Dependencies**:
- Redis for job queues (discovery + scraping)
- Proxy service for anti-detection
- Database for storing scraped prices

### MCP Server (`cmd/mcp/`)
**Purpose**: Model Context Protocol server for AI assistant integration
**Protocol**: JSON-RPC 2.0
**Key Features**:
- Product search tools for AI assistants
- Price comparison and analysis tools
- Historical price data access
- Nutritional information comparison

**MCP Tools Available**:
- `search_products`: Search with filters
- `compare_products`: Multi-product comparison
- `get_price_history`: Historical price data
- `find_best_deals`: Deal discovery
- `analyze_price_trends`: Trend analysis
- `get_nutrition_comparison`: Nutritional comparison

## Development Patterns

### Service Communication
- **API ↔ Database**: GORM with connection pooling
- **API ↔ Cache**: Redis for sessions, caching
- **Scraper ↔ Queue**: Redis Streams for job processing
- **MCP ↔ API**: Internal HTTP calls or shared database

### Configuration Management
- Environment variables for runtime config
- Feature flags for gradual rollout
- Database configuration per service
- Logging configuration (structured JSON)

### Error Handling & Logging
- **Structured error responses** with HTTP status codes
- **Request correlation IDs** for tracing across services
- **Comprehensive Uber Zap logging** with structured context
- **Graceful degradation** under load with proper error logging
- **Test logging** always outputs to stdout for Claude Code visibility

#### Service Logging Requirements
```go
// Required logger initialization in each service
func NewService(logger *zap.Logger) *Service {
    return &Service{
        logger: logger.With(zap.String("service", "service_name")),
    }
}

// Required logging in all operations
func (s *Service) Operation(ctx context.Context, params ...interface{}) error {
    logger := s.logger.With(
        zap.String("operation", "Operation"),
        zap.String("request_id", GetRequestID(ctx)),
    )
    
    logger.Debug("Operation started", zap.Any("params", params))
    
    // Business logic with error logging
    if err := s.doWork(); err != nil {
        logger.Error("Operation failed", 
            zap.Error(err),
            zap.String("error_type", "business_logic_error"),
        )
        return err
    }
    
    logger.Info("Operation completed successfully")
    return nil
}
```

### Testing Approach
- Unit tests with testify
- Integration tests with TestContainers
- Service-specific test fixtures
- Mocked external dependencies

## Common Implementation Patterns

### Database Access
```go
// Use GORM for database-agnostic queries
db.Where("is_active = ?", true).Find(&products)
// Avoid raw SQL that might break SQLite compatibility
```

### HTTP Handlers
```go
// Consistent error handling
func (h *Handler) GetProduct(c *gin.Context) {
    productID := c.Param("id")
    if productID == "" {
        c.JSON(400, gin.H{"error": "product_id required"})
        return
    }
    // ... implementation
}
```

### Configuration
```go
// Environment-based configuration
type Config struct {
    DatabaseType string `env:"DATABASE_TYPE" envDefault:"sqlite"`
    DatabaseURL  string `env:"DATABASE_URL"`
    RedisURL     string `env:"REDIS_URL" envDefault:"redis://localhost:6379"`
}
```

## Build and Deployment

### Local Development
```bash
# Run individual services
make run-api      # Start API server
make run-scraper  # Start scraper service
make run-mcp      # Start MCP server

# Build all services
make build        # Creates bin/api, bin/scraper, bin/mcp
```

### Production Build
```bash
# Multi-stage Docker builds
make build-prod   # Creates production Docker images
```

### Health Checks
Each service should implement:
- `/health` endpoint (API server)
- Health check functions for scraper/MCP
- Dependency health validation (database, Redis, external services)

## Performance Considerations

### API Server
- Response caching with Redis
- Database query optimization
- Connection pooling
- Graceful shutdown handling

### Scraper Service
- Concurrent request processing
- Rate limiting compliance
- Error retry with exponential backoff
- Resource cleanup (connections, goroutines)

### MCP Server
- Stateless request handling
- Efficient data serialization
- Request timeout management
- Connection lifecycle management

## Security Guidelines
- Never log sensitive data (passwords, tokens, PII)
- Use structured logging with request correlation
- Implement proper input validation
- Follow OWASP security guidelines
- Use secure HTTP headers