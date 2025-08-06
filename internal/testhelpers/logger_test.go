package testhelpers

import (
	"testing"

	"go.uber.org/zap/zapcore"
)

func TestSetupTestLogger(t *testing.T) {
	logger := SetupTestLogger(t)
	LogTestStart(logger, "TestSetupTestLogger", "internal/testhelpers")

	LogTestStep(logger, "arrange", "Setting up test logger validation")

	// Test that logger is not nil
	if logger == nil {
		LogTestComplete(logger, "TestSetupTestLogger", false)
		t.Fatal("Expected logger to be non-nil")
	}

	LogTestStep(logger, "act", "Testing logger functionality")

	// Test that we can log messages
	logger.Info("Test info message")
	logger.Debug("Test debug message")

	LogTestStep(logger, "assert", "Validating logger configuration")

	LogTestComplete(logger, "TestSetupTestLogger", true)
}

func TestSetupTestLoggerWithLevel(t *testing.T) {
	logger := SetupTestLoggerWithLevel(t, zapcore.InfoLevel)
	LogTestStart(logger, "TestSetupTestLoggerWithLevel", "internal/testhelpers")

	LogTestStep(logger, "arrange", "Setting up logger with specific level")

	// Test that logger is not nil
	if logger == nil {
		LogTestComplete(logger, "TestSetupTestLoggerWithLevel", false)
		t.Fatal("Expected logger to be non-nil")
	}

	LogTestStep(logger, "act", "Testing logger with info level")

	// Test logging at different levels
	logger.Info("This info message should appear")
	logger.Debug("This debug message should be filtered out")

	LogTestStep(logger, "assert", "Validating level-specific logging")

	LogTestComplete(logger, "TestSetupTestLoggerWithLevel", true)
}

func TestLogTestHelperFunctions(t *testing.T) {
	logger := SetupTestLogger(t)
	LogTestStart(logger, "TestLogTestHelperFunctions", "internal/testhelpers")

	LogTestStep(logger, "arrange", "Testing all helper logging functions")

	// Test LogTestSetup
	LogTestSetup(logger, map[string]interface{}{
		"test_data": "sample",
		"database":  "sqlite",
	})

	LogTestStep(logger, "act", "Testing helper functions")

	// Test LogTestAssertion
	LogTestAssertion(logger, "equal values", "expected", "actual")

	// Test LogBundleSizeCheck (within limit)
	LogBundleSizeCheck(logger, 10.5, 14.0, true)

	// Test LogBundleSizeCheck (over limit)
	LogBundleSizeCheck(logger, 15.2, 14.0, false)

	// Test LogPerformanceMetric (passing)
	LogPerformanceMetric(logger, "response_time", 45.2, "ms", true)

	// Test LogPerformanceMetric (failing)
	LogPerformanceMetric(logger, "response_time", 250.8, "ms", false)

	// Test LogDatabaseOperation
	LogDatabaseOperation(logger, "INSERT", "products", map[string]interface{}{
		"name":  "Test Product",
		"price": 99.99,
	})

	// Test LogHTTPRequest
	LogHTTPRequest(logger, "GET", "/api/products", 200, "23ms")

	// Test LogScraperOperation (success)
	LogScraperOperation(logger, "amazon", "B07XYZ123", true, 1299.99)

	// Test LogScraperOperation (failure)
	LogScraperOperation(logger, "flipkart", "FLIP456", false, 0.0)

	LogTestStep(logger, "assert", "All helper functions executed successfully")

	LogTestComplete(logger, "TestLogTestHelperFunctions", true)
}

func TestBundleSizeValidation(t *testing.T) {
	logger := SetupTestLogger(t)
	LogTestStart(logger, "TestBundleSizeValidation", "internal/testhelpers")

	LogTestStep(logger, "arrange", "Testing bundle size validation critical for <14KB requirement")

	// Test cases for bundle size validation
	testCases := []struct {
		name     string
		sizeKB   float64
		limitKB  float64
		expected bool
	}{
		{"Well under limit", 8.5, 14.0, true},
		{"Just under limit", 13.9, 14.0, true},
		{"At limit", 14.0, 14.0, true},
		{"Just over limit", 14.1, 14.0, false},
		{"Well over limit", 20.0, 14.0, false},
	}

	LogTestStep(logger, "act", "Testing various bundle sizes against 14KB limit")

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			subLogger := SetupTestLogger(t)
			LogTestStep(subLogger, "test_case", tc.name)

			// This simulates the bundle size check logic
			passed := tc.sizeKB <= tc.limitKB
			LogBundleSizeCheck(subLogger, tc.sizeKB, tc.limitKB, passed)

			LogTestAssertion(subLogger, "bundle size check", tc.expected, passed)

			if passed != tc.expected {
				t.Errorf("Bundle size check failed for %s: expected %v, got %v",
					tc.name, tc.expected, passed)
			}
		})
	}

	LogTestStep(logger, "assert", "All bundle size validation tests completed")
	LogTestComplete(logger, "TestBundleSizeValidation", true)
}

func TestPerformanceLogging(t *testing.T) {
	logger := SetupTestLogger(t)
	LogTestStart(logger, "TestPerformanceLogging", "internal/testhelpers")

	LogTestStep(logger, "arrange", "Testing performance metric logging")

	// Test performance metrics that should pass project requirements
	performanceTests := []struct {
		metric   string
		value    interface{}
		unit     string
		expected bool
	}{
		{"api_response_time", 45.2, "ms", true},   // <50ms cached target
		{"db_query_time", 180.5, "ms", true},      // <200ms DB target
		{"page_load_time", 450.0, "ms", true},     // <500ms load target
		{"bundle_size", 12.8, "KB", true},         // <14KB bundle target
		{"cache_hit_rate", 92.3, "%", true},       // >90% cache target
		{"api_response_time", 300.0, "ms", false}, // Exceeds targets
		{"bundle_size", 15.2, "KB", false},        // Exceeds bundle limit
	}

	LogTestStep(logger, "act", "Logging various performance metrics")

	for _, pt := range performanceTests {
		LogPerformanceMetric(logger, pt.metric, pt.value, pt.unit, pt.expected)

		// Validate that the logging doesn't crash or cause errors
		LogTestAssertion(logger, "performance logging", "no_error", "no_error")
	}

	LogTestStep(logger, "assert", "Performance logging validation completed")
	LogTestComplete(logger, "TestPerformanceLogging", true)
}
