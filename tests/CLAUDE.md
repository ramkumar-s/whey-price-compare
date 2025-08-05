# Testing Strategy - AI Assistant Context

## Testing Philosophy

The whey protein price comparison platform uses a comprehensive 4-tier testing strategy designed for fast feedback and comprehensive coverage while maintaining the critical <14KB bundle size requirement.

### Testing Pyramid
```
           E2E Tests (15 min)
       ─────────────────────────
      Integration Tests (10 min)
    ─────────────────────────────────
   Comprehensive Tests (15 min)
  ───────────────────────────────────────
        Critical Tests (2 min)
```

## Testing Tiers

### Tier 1: Critical Tests (<2 minutes)
**Purpose**: Fast feedback for basic functionality
**Trigger**: Every commit, pre-commit hooks
**Target**: Core business logic, critical paths

**Test Categories**:
- Unit tests for core business logic
- Bundle size validation (<14KB)
- API endpoint smoke tests
- Database connection tests
- Essential configuration validation

**Example Structure**:
```
tests/critical/
├── api/
│   ├── health_test.go
│   └── bundle_size_test.go
├── database/
│   └── connection_test.go
├── scraper/
│   └── validation_test.go
└── frontend/
    └── bundle_size_test.go
```

### Tier 2: Comprehensive Tests (<15 minutes)
**Purpose**: Full unit test coverage with detailed validation
**Trigger**: Pull requests, main branch pushes
**Target**: 80%+ code coverage, all service functionality

**Test Categories**:
- Complete unit test suite
- Service layer testing
- Repository pattern testing
- Authentication flow testing
- Error handling validation

### Tier 3: Integration Tests (<10 minutes) 
**Purpose**: Service interactions and external dependencies
**Trigger**: Pull requests, staging deployment
**Target**: Service boundaries, database operations, external APIs

**Test Categories**:
- Database integration with TestContainers
- Redis cache integration
- External API mocking
- Service-to-service communication
- Configuration integration

### Tier 4: End-to-End Tests (<15 minutes)
**Purpose**: Complete user journeys and business workflows
**Trigger**: Staging deployment, production deployment
**Target**: User experience, business critical paths

**Test Categories**:
- User registration and authentication
- Product search and comparison
- Price alert workflows
- Admin functionality
- Mobile responsiveness

## Testing Tools and Frameworks

### Go Testing Stack
- **Testing Framework**: Go standard library + testify
- **Mocking**: testify/mock for interface mocking
- **Database Testing**: TestContainers for real database tests
- **HTTP Testing**: httptest for API endpoint testing
- **Assertion Library**: testify/assert for readable assertions

### Integration Testing
- **TestContainers**: Docker containers for real database/Redis testing
- **Test Fixtures**: Consistent test data across test suites
- **Environment Isolation**: Each test gets clean environment
- **Parallel Execution**: Tests run concurrently where possible

### Frontend Testing
- **Bundle Size Validation**: Automated size checking in CI
- **Browser Testing**: Playwright for E2E browser testing
- **Performance Testing**: Lighthouse CI for performance validation
- **Accessibility Testing**: Automated a11y testing

### Load Testing
- **Tool**: k6 for performance and load testing
- **Scenarios**: User search, product comparison, API endpoints
- **Targets**: 1000 concurrent users, <500ms response times
- **Integration**: Automated load testing in staging

## Test Organization

### Directory Structure
```
tests/
├── critical/           # Tier 1: <2 min fast tests
├── unit/              # Tier 2: Comprehensive unit tests
├── integration/       # Tier 3: Service integration tests  
├── e2e/               # Tier 4: End-to-end user journeys
├── load/              # Performance and load tests
├── fixtures/          # Test data and fixtures
└── helpers/           # Test utilities and helpers
```

### Test Data Management
- **Fixtures**: JSON/YAML files with test data
- **Factories**: Go functions to create test objects
- **Database Seeding**: Consistent test database state
- **Cleanup**: Automatic cleanup after each test

## Testing Patterns

### Unit Testing Pattern
```go
func TestProductService_GetProduct(t *testing.T) {
    // Arrange
    mockRepo := &mocks.ProductRepository{}
    service := NewProductService(mockRepo)
    expectedProduct := &Product{ID: "123", Name: "Test Protein"}
    mockRepo.On("FindByID", "123").Return(expectedProduct, nil)
    
    // Act
    result, err := service.GetProduct("123")
    
    // Assert
    assert.NoError(t, err)
    assert.Equal(t, expectedProduct, result)
    mockRepo.AssertExpectations(t)
}
```

### Integration Testing Pattern
```go
func TestProductRepository_Integration(t *testing.T) {
    // Setup TestContainer
    container := setupPostgreSQLContainer(t)
    defer container.Terminate(context.Background())
    
    db := connectToTestDB(t, container)
    repo := NewProductRepository(db)
    
    // Test database operations
    product := &Product{Name: "Test Protein"}
    err := repo.Create(product)
    assert.NoError(t, err)
    
    found, err := repo.FindByID(product.ID)
    assert.NoError(t, err)
    assert.Equal(t, product.Name, found.Name)
}
```

### E2E Testing Pattern
```go
func TestUserJourney_SearchAndAlert(t *testing.T) {
    // Setup browser
    browser := playwright.NewBrowser()
    page := browser.NewPage()
    
    // Navigate to homepage
    page.Navigate("http://localhost:8080")
    
    // Search for product
    page.Fill("#search-input", "whey protein")
    page.Click("#search-button")
    
    // Verify results
    assert.True(t, page.IsVisible(".product-card"))
    
    // Create price alert
    page.Click(".create-alert-btn")
    page.Fill("#target-price", "2000")
    page.Click("#create-alert")
    
    // Verify alert created
    assert.True(t, page.IsVisible(".alert-success"))
}
```

## Performance Testing

### Bundle Size Testing
```go
func TestBundleSize(t *testing.T) {
    // Build frontend assets
    cmd := exec.Command("make", "build-frontend")
    err := cmd.Run()
    require.NoError(t, err)
    
    // Check total bundle size
    totalSize := calculateBundleSize("web/static/dist/")
    assert.Less(t, totalSize, 14*1024, "Bundle size exceeds 14KB limit")
}
```

### Load Testing with k6
```javascript
// tests/load/search_performance.js
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 1000 },
    { duration: '2m', target: 0 },
  ],
};

export default function() {
  let response = http.get('http://localhost:8080/api/v1/products/search?q=whey');
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has products': (r) => JSON.parse(r.body).products.length > 0,
  });
}
```

## Test Data and Fixtures

### Test Database Setup
- **SQLite**: Fast in-memory database for unit tests
- **PostgreSQL**: TestContainers for integration tests
- **Test Data**: Realistic protein products, brands, prices
- **Isolation**: Each test gets clean database state

### Mock Data Patterns
```go
// Test fixtures
func CreateTestProduct() *Product {
    return &Product{
        ID:          "test-product-1",
        Name:        "Gold Standard Whey",
        Brand:       "Optimum Nutrition",
        Category:    "Whey Protein",
        Protein:     24.0,
        Servings:    74,
        IsActive:    true,
    }
}

func CreateTestUser() *User {
    return &User{
        ID:           "test-user-1", 
        Email:        "test@example.com",
        Name:         "Test User",
        IsActive:     true,
        Tier:         TierUser,
    }
}
```

## CI/CD Integration

### GitHub Actions Integration
```yaml
# Test execution in CI
- name: Run Critical Tests
  run: make test-critical
  timeout-minutes: 3

- name: Run Comprehensive Tests  
  run: make test-unit
  timeout-minutes: 20

- name: Run Integration Tests
  run: make test-integration
  timeout-minutes: 15

- name: Run E2E Tests
  run: make test-e2e
  timeout-minutes: 20
```

### Test Coverage Requirements
- **Critical Paths**: 90%+ coverage
- **Overall Coverage**: 80%+ coverage
- **New Code**: 85%+ coverage
- **Coverage Reports**: Generated and stored in CI

## Testing Best Practices

### Test Organization
1. **Descriptive Names**: Test names describe what they test
2. **AAA Pattern**: Arrange, Act, Assert structure
3. **Single Responsibility**: Each test tests one thing
4. **Fast Execution**: Tests run quickly and reliably

### Test Data Management
1. **Isolated Data**: Each test uses its own data
2. **Realistic Data**: Test data resembles production data
3. **Cleanup**: Tests clean up after themselves
4. **Factories**: Use factories for test object creation

### Mock Usage
1. **Interface Mocking**: Mock interfaces, not concrete types
2. **Behavior Verification**: Verify interactions, not just returns
3. **Realistic Mocks**: Mock behavior should match real implementations
4. **Mock Isolation**: Don't share mocks between tests

## Performance Considerations

### Test Performance
- **Parallel Execution**: Run tests concurrently where safe
- **Database Optimization**: Use transactions for test isolation
- **Caching**: Cache expensive setup operations
- **Resource Management**: Properly cleanup resources

### CI/CD Performance
- **Selective Testing**: Only run relevant tests for changes
- **Test Caching**: Cache test dependencies and results
- **Parallel Jobs**: Run test tiers in parallel when possible
- **Resource Limits**: Monitor CI resource usage

## Quality Metrics

### Test Quality KPIs
- **Test Coverage**: >80% overall, >90% critical paths
- **Test Success Rate**: >99% on main branch
- **Test Execution Time**: Meet tier time targets
- **Flaky Test Rate**: <1% of test executions

### Bug Detection Metrics
- **Bugs Found in Testing**: Track bugs caught by each tier
- **Production Bugs**: Track bugs that escape to production
- **Regression Rate**: Track rate of regression bugs
- **Time to Detection**: Time from bug introduction to detection

## Troubleshooting Common Issues

### Test Failures
1. **Flaky Tests**: Identify and fix non-deterministic tests
2. **Environment Issues**: Ensure consistent test environments
3. **Data Dependencies**: Check for test data conflicts
4. **Timing Issues**: Fix race conditions and timing dependencies

### Performance Issues
1. **Slow Tests**: Identify and optimize expensive tests
2. **Resource Leaks**: Check for unclosed connections/files
3. **Database Performance**: Optimize test database queries
4. **CI Timeouts**: Adjust timeout settings or optimize tests