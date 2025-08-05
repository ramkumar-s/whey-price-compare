# Local Development Setup

## Prerequisites

### Required Software
- **Go 1.21+**: Latest version recommended
- **SQLite3**: For local development database
- **Docker**: For containerized services (optional)
- **VSCode**: Recommended IDE with Go extensions
- **Git**: Version control

### Recommended VSCode Extensions
```json
{
  "recommendations": [
    "golang.go",
    "ms-vscode.vscode-json", 
    "bradlc.vscode-tailwindcss",
    "ms-vscode.vscode-docker",
    "redhat.vscode-yaml"
  ]
}
```

## Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd whey-price-compare

# Install Go dependencies
go mod download

# Setup SQLite development database
make setup-sqlite

# Verify setup
make env-check
```

### 2. Database Options

#### Option A: SQLite (Recommended for Local Dev)
```bash
# Create SQLite database with test data
make setup-sqlite

# Verify database
make sqlite-shell
# In SQLite shell:
.tables
SELECT COUNT(*) FROM products;
.quit
```

#### Option B: Docker PostgreSQL
```bash
# Start containerized PostgreSQL + Redis
make dev

# Run migrations
make migrate-up

# Seed with test data
make seed
```

### 3. Start Development Servers

#### API Server
```bash
# Set environment variables
export DATABASE_TYPE=sqlite
export DATABASE_URL=data/sqlite/dev.db
export REDIS_URL=redis://localhost:6379
export LOG_LEVEL=debug

# Run API server
make run-api
# Server will start on http://localhost:8080
```

#### Scraper Service (Optional)
```bash
# Set scraper environment
export SCRAPER_MODE=development
export ENABLE_MOCK_SCRAPING=true

# Run scraper service
make run-scraper
```

#### MCP Server (Optional)
```bash
# Run MCP server for AI integration
make run-mcp
# Server will start on configured port
```

## Development Configuration

### Environment Variables
Create `.env.development` file:
```bash
# Database
DATABASE_TYPE=sqlite
DATABASE_URL=data/sqlite/dev.db

# Redis (optional for local dev)
REDIS_URL=redis://localhost:6379

# Logging
LOG_LEVEL=debug
LOG_FORMAT=console

# Scraper
SCRAPER_MODE=development
ENABLE_MOCK_SCRAPING=true
SCRAPER_DELAY_MS=100

# Authentication (for testing)
JWT_SECRET=your-development-secret-key
OAUTH_GOOGLE_CLIENT_ID=your-google-client-id
OAUTH_GOOGLE_CLIENT_SECRET=your-google-client-secret

# External Services
ENABLE_EXTERNAL_SERVICES=false
MOCK_EMAIL_DELIVERY=true
```

### SQLite vs PostgreSQL Compatibility

The codebase uses GORM with database-agnostic queries to ensure compatibility:

```go
// Compatible with both SQLite and PostgreSQL
type Product struct {
    ID        string    `gorm:"primaryKey;type:uuid;default:uuid_generate_v4()"` // PostgreSQL
    ID        string    `gorm:"primaryKey"`                                        // SQLite
    CreatedAt time.Time `gorm:"autoCreateTime"`
    UpdatedAt time.Time `gorm:"autoUpdateTime"`
}

// Use GORM's database-agnostic features
db.Where("is_active = ?", true).Find(&products)
```

## Test Data

### Initial Brands and Products
The SQLite schema includes test data for:
- **Brands**: Optimum Nutrition, MuscleBlaze, Dymatize, BSN, The Whole Truth
- **Categories**: Whey Protein, Whey Isolate, Whey Concentrate, etc.
- **Sample Products**: 
  - Gold Standard 100% Whey (Optimum Nutrition)
  - Biozyme Performance Whey (MuscleBlaze)
  - Slow Coffee & Bold Chocolate Protein (The Whole Truth)

### Adding More Test Data
```bash
# Add custom test products via SQL
make sqlite-shell

-- Insert new product
INSERT INTO products (brand_id, category_id, name, slug, protein_per_serving) 
SELECT b.id, c.id, 'Test Product', 'test-product', 25.0
FROM brands b, categories c 
WHERE b.slug = 'optimum-nutrition' AND c.slug = 'whey-protein';
```

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/new-scraper-retailer

# Make changes
# ...

# Run tests
make test-critical
make test-unit

# Format and lint
make fmt
make lint

# Commit changes
git add .
git commit -m "Add support for new retailer"
```

### 2. Database Changes
```bash
# For SQLite changes, edit schema file
vim deployments/sqlite/schema.sql

# Reset and recreate database
make sqlite-reset

# For PostgreSQL migrations
make migrate-create name=add_new_table
# Edit the generated migration file
# Apply migration
make migrate-up
```

### 3. Testing Scraper Locally
```bash
# Enable mock scraping mode
export ENABLE_MOCK_SCRAPING=true
export SCRAPER_DELAY_MS=100

# Run scraper tests
go test -v ./internal/scraper/...

# Test specific retailer
go test -v -run TestAmazonScraper ./internal/scraper/
```

## Debugging and Monitoring

### Local Observability Stack
```bash
# Start Prometheus, Grafana, Jaeger
make dev

# Access dashboards
make metrics    # Prometheus at localhost:9090
make dashboards # Grafana at localhost:3000 (admin/admin)
make tracing    # Jaeger at localhost:16686
```

### Debug API Responses
```bash
# Test API endpoints
curl -X GET "http://localhost:8080/api/v1/products/search?q=whey+protein"

# Check health
curl -X GET "http://localhost:8080/health"

# Test with authentication
curl -H "Authorization: Bearer <token>" "http://localhost:8080/api/v1/user/alerts"
```

### Database Debugging
```bash
# SQLite debugging
make sqlite-shell
.schema products
SELECT * FROM products LIMIT 5;

# PostgreSQL debugging (if using Docker)
docker exec -it whey_postgres_dev psql -U whey_user -d whey_price_dev
\dt
SELECT * FROM products LIMIT 5;
```

## Common Development Tasks

### 1. Add New Retailer
1. Update `retailers` table with configuration
2. Implement scraper in `internal/scraper/retailers/`
3. Add tests in `tests/scraper/`
4. Update configuration documentation

### 2. Add New Product Brand
1. Insert into `brands` table
2. Update test data in SQLite schema
3. Add brand-specific parsing logic if needed

### 3. Modify Database Schema
1. Update PostgreSQL migration files
2. Update SQLite schema file
3. Regenerate GORM models if needed
4. Update API endpoints and tests

### 4. Test Frontend Bundle Size
```bash
# Build frontend assets
make build-frontend

# Validate bundle size (<14KB)
make validate-bundle-size
```

## Performance Testing

### Local Load Testing
```bash
# Install k6 (if not already installed)
brew install k6  # macOS
# or download from https://k6.io/

# Run load tests against local API
make test-load
```

### Memory and CPU Profiling
```bash
# Run CPU profiling
make profile-cpu

# Run memory profiling  
make profile-mem

# Run benchmarks
make benchmark
```

## Troubleshooting

### Common Issues

#### SQLite Database Locked
```bash
# Reset SQLite database
make sqlite-reset
```

#### Go Module Issues
```bash
# Clean module cache
go clean -modcache
go mod download
```

#### Port Conflicts
```bash
# Check what's using port 8080
lsof -i :8080

# Kill process if needed
kill -9 <PID>
```

#### Docker Issues
```bash
# Reset Docker environment
make docker-reset

# Clean up Docker resources
make docker-clean
```

### Getting Help

1. Check existing documentation in `docs/`
2. Review test files for usage examples
3. Check GitHub issues for known problems
4. Run `make help` for available commands

## VSCode Configuration

### Recommended settings.json
```json
{
  "go.testFlags": ["-v", "-race"],
  "go.lintTool": "golangci-lint",
  "go.lintOnSave": "package",
  "go.formatTool": "goimports",
  "go.useLanguageServer": true,
  "go.testTimeout": "60s",
  "[go]": {
    "editor.insertSpaces": false,
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  }
}
```

### Debug Configuration (.vscode/launch.json)
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug API Server",
      "type": "go",
      "request": "launch",
      "mode": "debug",
      "program": "${workspaceFolder}/cmd/api/main.go",
      "env": {
        "DATABASE_TYPE": "sqlite",
        "DATABASE_URL": "data/sqlite/dev.db",
        "LOG_LEVEL": "debug"
      }
    },
    {
      "name": "Debug Scraper",
      "type": "go",
      "request": "launch",
      "mode": "debug", 
      "program": "${workspaceFolder}/cmd/scraper/main.go",
      "env": {
        "SCRAPER_MODE": "development",
        "ENABLE_MOCK_SCRAPING": "true"
      }
    }
  ]
}
```