# Logging Strategy - Whey Protein Price Comparison Platform

## Overview

Comprehensive logging strategy using **Uber Zap** for high-performance structured logging across all services and tests, with special emphasis on Claude Code integration and debugging capabilities.

## Logging Architecture

### Core Logging Library: Uber Zap
```go
// Primary logger configuration
import "go.uber.org/zap"

// Production logger (JSON structured)
logger, _ := zap.NewProduction()

// Development logger (human-readable console)
logger, _ := zap.NewDevelopment()
```

### Log Levels and Usage

#### Level Hierarchy (Most to Least Verbose)
1. **DEBUG** - Detailed execution flow, variable values, internal state
2. **INFO** - General operational messages, request/response summaries
3. **WARN** - Potentially problematic situations, fallback mechanisms
4. **ERROR** - Error conditions that don't stop the application
5. **FATAL** - Severe errors that cause application termination

## Service-Level Logging

### API Server Logging
```go
type APILogger struct {
    logger *zap.Logger
}

// Request logging middleware
func (l *APILogger) RequestMiddleware() gin.HandlerFunc {
    return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
        l.logger.Info("API request",
            zap.String("method", param.Method),
            zap.String("path", param.Path),
            zap.Int("status", param.StatusCode),
            zap.Duration("latency", param.Latency),
            zap.String("client_ip", param.ClientIP),
            zap.String("user_agent", param.Request.UserAgent()),
            zap.String("request_id", param.Request.Header.Get("X-Request-ID")),
        )
        return ""
    })
}

// Business logic logging
func (s *ProductService) GetProduct(ctx context.Context, id string) (*Product, error) {
    logger := s.logger.With(
        zap.String("operation", "GetProduct"),
        zap.String("product_id", id),
        zap.String("request_id", GetRequestID(ctx)),
    )
    
    logger.Debug("Starting product retrieval")
    
    product, err := s.repo.FindByID(ctx, id)
    if err != nil {
        logger.Error("Failed to retrieve product",
            zap.Error(err),
            zap.String("error_type", "database_error"),
        )
        return nil, err
    }
    
    logger.Info("Product retrieved successfully",
        zap.String("product_name", product.Name),
        zap.String("brand", product.Brand),
        zap.Bool("is_active", product.IsActive),
    )
    
    return product, nil
}
```

### Scraper Service Logging
```go
func (s *Scraper) ScrapeProduct(ctx context.Context, listing *ProductListing) error {
    logger := s.logger.With(
        zap.String("operation", "ScrapeProduct"),
        zap.String("retailer", listing.Retailer.Name),
        zap.String("product_id", listing.ProductVariantID),
        zap.String("url", listing.RetailerURL),
        zap.String("scrape_id", GenerateID()),
    )
    
    logger.Debug("Starting product scraping",
        zap.String("user_agent", s.currentUserAgent),
        zap.String("proxy", s.currentProxy),
    )
    
    startTime := time.Now()
    
    price, err := s.extractPrice(ctx, listing.RetailerURL)
    if err != nil {
        logger.Error("Scraping failed",
            zap.Error(err),
            zap.Duration("duration", time.Since(startTime)),
            zap.String("error_type", "scraping_error"),
            zap.Bool("retry_needed", true),
        )
        return err
    }
    
    // Price validation
    if !s.validatePrice(price, listing.LastKnownPrice) {
        logger.Warn("Suspicious price detected",
            zap.Float64("new_price", price),
            zap.Float64("last_price", listing.LastKnownPrice),
            zap.Float64("change_percent", (price-listing.LastKnownPrice)/listing.LastKnownPrice*100),
            zap.Bool("manual_review_required", true),
        )
    }
    
    logger.Info("Scraping completed successfully",
        zap.Float64("price", price),
        zap.Duration("duration", time.Since(startTime)),
        zap.String("validation_status", "passed"),
    )
    
    return nil
}
```

### MCP Server Logging
```go
func (s *MCPServer) HandleToolCall(ctx context.Context, tool string, params map[string]interface{}) (interface{}, error) {
    logger := s.logger.With(
        zap.String("operation", "HandleToolCall"),
        zap.String("tool", tool),
        zap.String("session_id", GetSessionID(ctx)),
        zap.String("ai_client", GetAIClient(ctx)), // "claude", "chatgpt", etc.
    )
    
    logger.Debug("AI tool call received",
        zap.Any("parameters", params),
        zap.Int("param_count", len(params)),
    )
    
    // Log tool execution
    result, err := s.executeTool(ctx, tool, params)
    if err != nil {
        logger.Error("Tool execution failed",
            zap.Error(err),
            zap.String("error_type", "tool_execution_error"),
        )
        return nil, err
    }
    
    logger.Info("Tool executed successfully",
        zap.String("result_type", fmt.Sprintf("%T", result)),
        zap.Int("result_size", getResultSize(result)),
    )
    
    return result, nil
}
```

## Test Logging Strategy

### Test Logger Configuration
```go
// Global test logger for all test files
func NewTestLogger() *zap.Logger {
    config := zap.NewDevelopmentConfig()
    config.Level = zap.NewAtomicLevelAt(zap.DebugLevel) // Always verbose in tests
    config.OutputPaths = []string{"stdout", "tests.log"}
    config.ErrorOutputPaths = []string{"stderr", "tests.log"}
    
    logger, _ := config.Build()
    return logger
}

// Test helper to ensure logs are always visible
func SetupTestLogger(t *testing.T) *zap.Logger {
    logger := NewTestLogger()
    
    // Ensure logs are flushed at test completion
    t.Cleanup(func() {
        logger.Sync()
    })
    
    return logger
}
```

### Unit Test Logging
```go
func TestProductService_GetProduct(t *testing.T) {
    logger := SetupTestLogger(t)
    
    // Test setup logging
    logger.Info("Starting unit test",
        zap.String("test", "TestProductService_GetProduct"),
        zap.String("package", "internal/services"),
    )
    
    // Arrange
    mockRepo := &mocks.ProductRepository{}
    service := NewProductService(mockRepo, logger)
    expectedProduct := &Product{ID: "123", Name: "Test Protein"}
    
    logger.Debug("Test setup complete",
        zap.String("mock_product_id", expectedProduct.ID),
        zap.String("service_type", "ProductService"),
    )
    
    mockRepo.On("FindByID", "123").Return(expectedProduct, nil)
    
    // Act
    logger.Debug("Executing service method")
    result, err := service.GetProduct(context.Background(), "123")
    
    // Assert
    assert.NoError(t, err)
    assert.Equal(t, expectedProduct, result)
    mockRepo.AssertExpectations(t)
    
    logger.Info("Unit test completed successfully",
        zap.Bool("test_passed", err == nil),
        zap.String("result_product_name", result.Name),
    )
}
```

### Integration Test Logging
```go
func TestProductRepository_Integration(t *testing.T) {
    logger := SetupTestLogger(t)
    
    logger.Info("Starting integration test",
        zap.String("test", "TestProductRepository_Integration"),
        zap.String("database", "postgresql"),
        zap.Bool("uses_testcontainers", true),
    )
    
    // Setup TestContainer with logging
    container := setupPostgreSQLContainer(t)
    defer container.Terminate(context.Background())
    
    logger.Debug("Test container started",
        zap.String("container_id", container.GetContainerID()),
        zap.String("database_url", container.GetConnectionString()),
    )
    
    db := connectToTestDB(t, container)
    repo := NewProductRepository(db, logger)
    
    // Test database operations with detailed logging
    product := &Product{Name: "Test Protein", Brand: "Test Brand"}
    
    logger.Debug("Creating test product",
        zap.String("product_name", product.Name),
        zap.String("brand", product.Brand),
    )
    
    err := repo.Create(product)
    assert.NoError(t, err)
    
    logger.Debug("Product created, testing retrieval",
        zap.String("product_id", product.ID),
    )
    
    found, err := repo.FindByID(product.ID)
    assert.NoError(t, err)
    assert.Equal(t, product.Name, found.Name)
    
    logger.Info("Integration test completed successfully",
        zap.String("final_product_id", found.ID),
        zap.Bool("data_matches", product.Name == found.Name),
    )
}
```

### E2E Test Logging
```go
func TestUserJourney_SearchAndAlert(t *testing.T) {
    logger := SetupTestLogger(t)
    
    logger.Info("Starting E2E test",
        zap.String("test", "TestUserJourney_SearchAndAlert"),
        zap.String("browser", "chromium"),
        zap.String("url", "http://localhost:8080"),
    )
    
    // Browser setup
    browser := playwright.NewBrowser()
    page := browser.NewPage()
    
    // Add request/response logging
    page.On("request", func(request playwright.Request) {
        logger.Debug("Browser request",
            zap.String("method", request.Method()),
            zap.String("url", request.URL()),
        )
    })
    
    page.On("response", func(response playwright.Response) {
        logger.Debug("Browser response",
            zap.String("url", response.URL()),
            zap.Int("status", response.Status()),
        )
    })
    
    // Test steps with logging
    logger.Debug("Navigating to homepage")
    page.Navigate("http://localhost:8080")
    
    logger.Debug("Performing product search")
    page.Fill("#search-input", "whey protein")
    page.Click("#search-button")
    
    // Verify and log results
    productCount := page.Locator(".product-card").Count()
    logger.Info("Search results received",
        zap.Int("product_count", productCount),
        zap.Bool("has_results", productCount > 0),
    )
    
    assert.True(t, page.IsVisible(".product-card"))
    
    logger.Info("E2E test completed successfully",
        zap.Bool("test_passed", true),
    )
}
```

## Claude Code Integration

### Log Output for AI Analysis
```go
// Special logger for Claude Code sessions
func NewClaudeCodeLogger() *zap.Logger {
    config := zap.NewDevelopmentConfig()
    config.EncoderConfig.TimeKey = "timestamp"
    config.EncoderConfig.LevelKey = "level"
    config.EncoderConfig.MessageKey = "message"
    config.EncoderConfig.CallerKey = "caller"
    config.EncoderConfig.StacktraceKey = "stacktrace"
    
    // Always output to stdout for Claude Code visibility
    config.OutputPaths = []string{"stdout"}
    config.ErrorOutputPaths = []string{"stderr"}
    
    // Use console encoder for better readability
    config.Encoding = "console"
    config.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
    
    logger, _ := config.Build()
    return logger
}
```

### Test Execution with Claude Code
```bash
# Test commands that ensure log visibility
go test -v -race ./... 2>&1 | tee test_output.log

# Critical tests with verbose output
go test -v -race -short -tags=critical ./internal/... ./pkg/... 2>&1

# Integration tests with container logs
go test -v -tags=integration ./tests/integration/... 2>&1

# E2E tests with browser logs
go test -v -tags=e2e ./tests/e2e/... 2>&1
```

## Environment-Based Logging Configuration

### Development Environment
```go
func NewDevelopmentLogger() *zap.Logger {
    config := zap.NewDevelopmentConfig()
    config.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
    config.Development = true
    config.Encoding = "console" // Human-readable
    config.OutputPaths = []string{"stdout"}
    
    logger, _ := config.Build()
    return logger
}
```

### Production Environment
```go
func NewProductionLogger() *zap.Logger {
    config := zap.NewProductionConfig()
    config.Level = zap.NewAtomicLevelAt(zap.InfoLevel)
    config.Encoding = "json" // Structured for log aggregation
    config.OutputPaths = []string{"stdout", "/var/log/whey-price-compare/app.log"}
    config.ErrorOutputPaths = []string{"stderr", "/var/log/whey-price-compare/error.log"}
    
    logger, _ := config.Build()
    return logger
}
```

### Test Environment
```go
func NewTestLogger() *zap.Logger {
    config := zap.NewDevelopmentConfig()
    config.Level = zap.NewAtomicLevelAt(zap.DebugLevel) // Always verbose
    config.Encoding = "console"
    config.OutputPaths = []string{"stdout", "tests.log"}
    config.DisableCaller = false // Show file/line info
    config.DisableStacktrace = false // Show stack traces
    
    logger, _ := config.Build()
    return logger
}
```

## Structured Logging Fields

### Standard Fields (All Services)
```go
type StandardFields struct {
    Timestamp   time.Time `json:"timestamp"`
    Level       string    `json:"level"`
    Message     string    `json:"message"`
    Service     string    `json:"service"`     // "api", "scraper", "mcp"
    Operation   string    `json:"operation"`   // function/method name
    RequestID   string    `json:"request_id"`  // correlation ID
    UserID      string    `json:"user_id,omitempty"`
    TraceID     string    `json:"trace_id,omitempty"`
    Error       string    `json:"error,omitempty"`
}
```

### Business Context Fields
```go
// Product-related operations
zap.String("product_id", productID)
zap.String("product_name", product.Name)
zap.String("brand", product.Brand)
zap.String("category", product.Category)

// Price-related operations
zap.Float64("price", price)
zap.Float64("previous_price", previousPrice)
zap.Float64("price_change_percent", changePercent)
zap.String("retailer", retailer.Name)

// User-related operations
zap.String("user_id", userID)
zap.String("user_tier", string(user.Tier))
zap.String("auth_method", "oauth2_google")

// Scraping-related operations
zap.String("scraper_id", scraperID)
zap.String("proxy", proxyURL)
zap.String("user_agent", userAgent)
zap.Duration("scrape_duration", duration)
zap.Bool("success", success)
```

## Performance Monitoring Through Logs

### Response Time Logging
```go
func LogExecutionTime(logger *zap.Logger, operation string, fn func() error) error {
    start := time.Now()
    err := fn()
    duration := time.Since(start)
    
    if err != nil {
        logger.Error("Operation failed",
            zap.String("operation", operation),
            zap.Duration("duration", duration),
            zap.Error(err),
        )
    } else {
        logger.Info("Operation completed",
            zap.String("operation", operation),
            zap.Duration("duration", duration),
        )
    }
    
    return err
}
```

### Bundle Size Logging (Critical for <14KB requirement)
```go
func LogBundleSize(logger *zap.Logger, assets []Asset) {
    totalSize := 0
    for _, asset := range assets {
        totalSize += asset.Size
        logger.Debug("Asset size",
            zap.String("asset", asset.Name),
            zap.Int("size_bytes", asset.Size),
            zap.String("size_human", humanize.Bytes(uint64(asset.Size))),
        )
    }
    
    sizeKB := float64(totalSize) / 1024
    withinLimit := sizeKB < 14.0
    
    if withinLimit {
        logger.Info("Bundle size check passed",
            zap.Float64("total_size_kb", sizeKB),
            zap.Float64("limit_kb", 14.0),
            zap.Float64("remaining_kb", 14.0-sizeKB),
        )
    } else {
        logger.Error("Bundle size exceeds limit",
            zap.Float64("total_size_kb", sizeKB),
            zap.Float64("limit_kb", 14.0),
            zap.Float64("overage_kb", sizeKB-14.0),
            zap.Bool("build_should_fail", true),
        )
    }
}
```

## Error Handling and Recovery Logging

### Structured Error Logging
```go
type LoggedError struct {
    Err         error             `json:"error"`
    ErrorType   string            `json:"error_type"`
    Operation   string            `json:"operation"`
    Context     map[string]interface{} `json:"context"`
    Recoverable bool              `json:"recoverable"`
}

func (s *Service) LogError(err error, errorType, operation string, context map[string]interface{}) {
    s.logger.Error("Service error occurred",
        zap.Error(err),
        zap.String("error_type", errorType),
        zap.String("operation", operation),
        zap.Any("context", context),
        zap.Bool("recoverable", IsRecoverable(err)),
        zap.String("stack_trace", string(debug.Stack())),
    )
}
```

## Log Aggregation and Analysis

### Log File Rotation
```go
func NewRotatingFileLogger(filename string) *zap.Logger {
    hook := lumberjack.Logger{
        Filename:   filename,
        MaxSize:    500, // megabytes
        MaxBackups: 3,
        MaxAge:     28, // days
        Compress:   true,
    }
    
    core := zapcore.NewCore(
        zapcore.NewJSONEncoder(zap.NewProductionEncoderConfig()),
        zapcore.AddSync(&hook),
        zap.InfoLevel,
    )
    
    return zap.New(core)
}
```

### Metrics from Logs
```go
func (s *Service) LogWithMetrics(level zapcore.Level, msg string, fields ...zap.Field) {
    // Log normally
    s.logger.Log(level, msg, fields...)
    
    // Extract metrics
    for _, field := range fields {
        switch field.Key {
        case "response_time":
            responseTimeHistogram.Observe(field.Interface.(time.Duration).Seconds())
        case "error_type":
            errorCounter.WithLabelValues(field.String).Inc()
        case "operation":
            operationCounter.WithLabelValues(field.String).Inc()
        }
    }
}
```

## Testing Log Output Validation

### Log Capture for Testing
```go
func TestLoggingOutput(t *testing.T) {
    // Capture logs for validation
    core, logs := observer.New(zap.DebugLevel)
    logger := zap.New(core)
    
    service := NewProductService(mockRepo, logger)
    
    // Execute operation
    service.GetProduct(context.Background(), "test-id")
    
    // Validate log output
    assert.Equal(t, 2, logs.Len()) // Expect 2 log entries
    
    entries := logs.All()
    assert.Equal(t, "Starting product retrieval", entries[0].Message)
    assert.Equal(t, "Product retrieved successfully", entries[1].Message)
    
    // Validate structured fields
    assert.Equal(t, "GetProduct", entries[0].ContextMap()["operation"])
    assert.Equal(t, "test-id", entries[0].ContextMap()["product_id"])
}
```

This comprehensive logging strategy ensures that all services and tests generate detailed, structured logs that are visible to Claude Code and provide excellent debugging and monitoring capabilities.