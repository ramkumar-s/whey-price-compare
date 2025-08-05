# Whey Price Comparison Platform - Makefile

.PHONY: help build test clean dev deploy

# Default target
help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Development
dev: ## Start development environment
	docker-compose -f docker-compose.dev.yml up -d

dev-down: ## Stop development environment
	docker-compose -f docker-compose.dev.yml down

dev-logs: ## Show development logs
	docker-compose -f docker-compose.dev.yml logs -f

# Build
build: ## Build all services
	go build -o bin/api ./cmd/api
	go build -o bin/scraper ./cmd/scraper
	go build -o bin/mcp ./cmd/mcp

build-prod: ## Build production Docker images
	docker-compose -f docker-compose.prod.yml build --no-cache

# Testing
test-critical: ## Run critical tests (fast feedback)
	go test -v -race -short -tags=critical ./internal/... ./pkg/...

test-unit: ## Run unit tests
	go test -v -race -coverprofile=coverage.out ./internal/...
	go test -v -race -coverprofile=coverage.out ./pkg/...

test-integration: ## Run integration tests
	go test -v -tags=integration ./tests/integration/...

test-contracts: ## Run contract tests
	go test -v -tags=contracts ./tests/contracts/...

test-e2e: ## Run end-to-end tests
	go test -v -tags=e2e ./tests/e2e/...

test-all: ## Run all tests with coverage
	go test -v -race -coverprofile=coverage.out -tags="unit integration contracts" ./...
	go tool cover -html=coverage.out -o coverage.html

test-load: ## Run load tests
	k6 run tests/load/search_performance.js
	k6 run tests/load/price_api_load.js

# Code Quality
lint: ## Run linters
	golangci-lint run ./...

fmt: ## Format code
	gofmt -s -w .
	goimports -w .

security: ## Run security checks
	gosec ./...

# Database
migrate-up: ## Run database migrations
	docker-compose -f docker-compose.dev.yml exec api /app/migrate up

migrate-up-test: ## Run database migrations for testing
	docker-compose -f docker-compose.test.yml exec api /app/migrate up

migrate-down: ## Rollback database migrations
	docker-compose -f docker-compose.dev.yml exec api /app/migrate down

migrate-create: ## Create new migration (usage: make migrate-create name=migration_name)
	docker-compose -f docker-compose.dev.yml exec api /app/migrate create $(name)

seed: ## Seed database with test data
	go run cmd/seed/main.go

# SQLite Development Database
setup-sqlite: ## Setup SQLite database for local development
	mkdir -p data/sqlite
	sqlite3 data/sqlite/dev.db < deployments/sqlite/schema.sql
	@echo "SQLite development database created at data/sqlite/dev.db"

sqlite-shell: ## Open SQLite shell for development database
	sqlite3 data/sqlite/dev.db

sqlite-backup: ## Backup SQLite development database
	cp data/sqlite/dev.db data/sqlite/dev_backup_$(shell date +%Y%m%d_%H%M%S).db

sqlite-reset: ## Reset SQLite development database
	rm -f data/sqlite/dev.db
	$(MAKE) setup-sqlite

# Services
run-api: ## Run API server
	go run cmd/api/main.go

run-scraper: ## Run scraper service
	go run cmd/scraper/main.go

run-mcp: ## Run MCP server
	go run cmd/mcp/main.go

# Deployment
deploy-staging: ## Deploy to staging
	docker-compose -f docker-compose.staging.yml up -d
	sleep 30
	$(MAKE) health-check

deploy-prod: ## Deploy to production
	docker-compose -f docker-compose.prod.yml down
	docker-compose -f docker-compose.prod.yml up -d
	sleep 30
	$(MAKE) health-check

health-check: ## Check service health
	@echo "Checking API health..."
	@curl -f http://localhost:8080/health || (echo "Health check failed" && exit 1)
	@echo "API is healthy"

# Monitoring
logs: ## Show production logs
	docker-compose -f docker-compose.prod.yml logs -f --tail=100

metrics: ## Open Prometheus metrics
	open http://localhost:9090

dashboards: ## Open Grafana dashboards
	open http://localhost:3000

tracing: ## Open Jaeger tracing
	open http://localhost:16686

# Backup & Restore
backup: ## Create database backup
	./scripts/backup.sh

restore: ## Restore from backup (usage: make restore backup=backup_file.sql.gz)
	./scripts/restore.sh $(backup)

# Dependencies
install-tools: ## Install development tools
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/securecodewarrior/sast-scan@latest
	go install github.com/testcontainers/testcontainers-go@latest

setup-hooks: ## Setup git pre-commit hooks
	cp scripts/hooks/pre-commit .git/hooks/
	chmod +x .git/hooks/pre-commit

# Docker Management
docker-clean: ## Clean Docker resources
	docker system prune -f
	docker volume prune -f

docker-reset: ## Reset Docker environment completely
	docker-compose -f docker-compose.dev.yml down -v
	docker-compose -f docker-compose.prod.yml down -v
	$(MAKE) docker-clean

# Performance
profile-cpu: ## Run CPU profiling
	go test -cpuprofile cpu.prof -bench . ./internal/services/...
	go tool pprof cpu.prof

profile-mem: ## Run memory profiling
	go test -memprofile mem.prof -bench . ./internal/services/...
	go tool pprof mem.prof

benchmark: ## Run benchmarks
	go test -bench=. -benchmem ./internal/...

# Clean
clean: ## Clean build artifacts
	rm -rf bin/
	rm -f coverage.out coverage.html
	rm -f *.prof
	go clean -cache
	go clean -testcache

# Frontend
build-frontend: ## Build frontend assets
	cd web/static && npm install && npm run build

watch-frontend: ## Watch frontend changes
	cd web/static && npm run watch

validate-bundle-size: ## Validate frontend bundle size (<14KB)
	@size=$$(du -b web/static/dist/*.js web/static/dist/*.css | awk '{sum += $$1} END {print sum}'); \
	if [ $$size -gt 14336 ]; then \
		echo "❌ Bundle size ($$size bytes) exceeds 14KB limit"; \
		exit 1; \
	else \
		echo "✅ Bundle size ($$size bytes) is within 14KB limit"; \
	fi

# Documentation
docs-serve: ## Serve documentation locally
	cd docs && python3 -m http.server 8000

docs-generate: ## Generate API documentation
	swagger generate spec -o docs/api/swagger.yaml --scan-models

# Release
release: ## Create release (usage: make release version=v1.0.0)
	git tag $(version)
	git push origin $(version)
	goreleaser release --clean

# Environment
env-check: ## Check environment setup
	@echo "Checking Go version..."
	@go version
	@echo "Checking Docker version..."
	@docker --version
	@echo "Checking Docker Compose version..."
	@docker-compose --version
	@echo "Checking required tools..."
	@which golangci-lint || echo "⚠ golangci-lint not found"
	@which goimports || echo "⚠ goimports not found"
	@which k6 || echo "⚠ k6 not found"

# Development workflow shortcuts
quick-test: fmt lint test-unit ## Quick development test cycle

full-check: fmt lint security test-all ## Full code quality check

dev-reset: dev-down docker-clean dev migrate-up seed ## Reset development environment

# Production maintenance
prod-restart: ## Restart production services
	docker-compose -f docker-compose.prod.yml restart api scraper

prod-update: ## Update production deployment
	git pull origin main
	$(MAKE) build-prod
	$(MAKE) deploy-prod

prod-rollback: ## Rollback production deployment
	git checkout HEAD~1
	$(MAKE) build-prod
	$(MAKE) deploy-prod