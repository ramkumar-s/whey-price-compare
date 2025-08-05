package testhelpers

import (
	"testing"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// SetupTestLogger creates a test logger that outputs to stdout for Claude Code visibility
// This function MUST be used in all test files to ensure logs are visible to AI assistants
func SetupTestLogger(t *testing.T) *zap.Logger {
	config := zap.NewDevelopmentConfig()
	
	// Always use debug level for comprehensive test logging
	config.Level = zap.NewAtomicLevelAt(zap.DebugLevel)
	
	// Output to stdout for Claude Code visibility (CRITICAL)
	config.OutputPaths = []string{"stdout"}
	config.ErrorOutputPaths = []string{"stderr"}
	
	// Use console encoding for human-readable logs in tests
	config.Encoding = "console"
	config.EncoderConfig.TimeKey = "time"
	config.EncoderConfig.LevelKey = "level"
	config.EncoderConfig.MessageKey = "msg"
	config.EncoderConfig.CallerKey = "caller"
	
	// Enable caller information for debugging
	config.DisableCaller = false
	config.DisableStacktrace = false
	
	logger, err := config.Build()
	if err != nil {
		t.Fatalf("Failed to create test logger: %v", err)
	}
	
	// Ensure logs are flushed when test completes
	t.Cleanup(func() {
		logger.Sync()
	})
	
	return logger
}

// SetupTestLoggerWithLevel creates a test logger with a specific log level
func SetupTestLoggerWithLevel(t *testing.T, level zapcore.Level) *zap.Logger {
	config := zap.NewDevelopmentConfig()
	config.Level = zap.NewAtomicLevelAt(level)
	config.OutputPaths = []string{"stdout"}
	config.ErrorOutputPaths = []string{"stderr"}
	config.Encoding = "console"
	
	logger, err := config.Build()
	if err != nil {
		t.Fatalf("Failed to create test logger: %v", err)
	}
	
	t.Cleanup(func() {
		logger.Sync()
	})
	
	return logger
}

// LogTestStart logs the beginning of a test with standard fields
func LogTestStart(logger *zap.Logger, testName, packageName string) {
	logger.Info("🧪 Test started",
		zap.String("test", testName),
		zap.String("package", packageName),
	)
}

// LogTestComplete logs successful test completion
func LogTestComplete(logger *zap.Logger, testName string, passed bool) {
	if passed {
		logger.Info("✅ Test completed successfully",
			zap.String("test", testName),
			zap.Bool("passed", passed),
		)
	} else {
		logger.Error("❌ Test failed",
			zap.String("test", testName),
			zap.Bool("passed", passed),
		)
	}
}

// LogTestStep logs individual test steps for better traceability
func LogTestStep(logger *zap.Logger, step, description string) {
	logger.Debug("🔄 Test step",
		zap.String("step", step),
		zap.String("description", description),
	)
}

// LogTestSetup logs test setup phase
func LogTestSetup(logger *zap.Logger, setup map[string]interface{}) {
	logger.Debug("⚙️ Test setup",
		zap.Any("setup", setup),
	)
}

// LogTestAssertion logs test assertions for debugging
func LogTestAssertion(logger *zap.Logger, assertion string, expected, actual interface{}) {
	logger.Debug("🔍 Test assertion",
		zap.String("assertion", assertion),
		zap.Any("expected", expected),
		zap.Any("actual", actual),
	)
}

// LogBundleSizeCheck logs frontend bundle size validation (critical for <14KB requirement)
func LogBundleSizeCheck(logger *zap.Logger, totalSizeKB float64, limit float64, passed bool) {
	if passed {
		logger.Info("📦 Bundle size check passed",
			zap.Float64("size_kb", totalSizeKB),
			zap.Float64("limit_kb", limit),
			zap.Float64("remaining_kb", limit-totalSizeKB),
			zap.Bool("within_limit", passed),
		)
	} else {
		logger.Error("📦 Bundle size exceeds limit",
			zap.Float64("size_kb", totalSizeKB),
			zap.Float64("limit_kb", limit),
			zap.Float64("overage_kb", totalSizeKB-limit),
			zap.Bool("within_limit", passed),
		)
	}
}

// LogPerformanceMetric logs performance-related test metrics
func LogPerformanceMetric(logger *zap.Logger, metric string, value interface{}, unit string, passed bool) {
	status := "✅"
	if !passed {
		status = "❌"
	}
	
	logger.Info("⚡ Performance metric",
		zap.String("status", status),
		zap.String("metric", metric),
		zap.Any("value", value),
		zap.String("unit", unit),
		zap.Bool("passed", passed),
	)
}

// LogDatabaseOperation logs database operations in tests
func LogDatabaseOperation(logger *zap.Logger, operation, table string, params map[string]interface{}) {
	logger.Debug("🗄️ Database operation",
		zap.String("operation", operation),
		zap.String("table", table),
		zap.Any("params", params),
	)
}

// LogHTTPRequest logs HTTP requests in integration/E2E tests
func LogHTTPRequest(logger *zap.Logger, method, url string, statusCode int, duration string) {
	logger.Debug("🌐 HTTP request",
		zap.String("method", method),
		zap.String("url", url),
		zap.Int("status_code", statusCode),
		zap.String("duration", duration),
	)
}

// LogScraperOperation logs scraper operations in tests
func LogScraperOperation(logger *zap.Logger, retailer, productID string, success bool, price float64) {
	status := "✅"
	if !success {
		status = "❌"
	}
	
	logger.Debug("🕷️ Scraper operation",
		zap.String("status", status),
		zap.String("retailer", retailer),
		zap.String("product_id", productID),
		zap.Bool("success", success),
		zap.Float64("price", price),
	)
}

// Example usage pattern for tests:
/*
func TestExample(t *testing.T) {
    logger := testhelpers.SetupTestLogger(t)
    testhelpers.LogTestStart(logger, "TestExample", "internal/service")
    
    // Test setup
    testhelpers.LogTestSetup(logger, map[string]interface{}{
        "mock_data": "product_123",
        "database": "sqlite",
    })
    
    // Test steps
    testhelpers.LogTestStep(logger, "arrange", "Setting up mocks and test data")
    // ... test logic
    
    testhelpers.LogTestStep(logger, "act", "Executing service method")
    // ... test execution
    
    testhelpers.LogTestStep(logger, "assert", "Validating results")
    // ... assertions
    
    testhelpers.LogTestComplete(logger, "TestExample", true)
}
*/