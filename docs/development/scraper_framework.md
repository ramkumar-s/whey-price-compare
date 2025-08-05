# Scraper Framework Design

## Overview

The scraper framework implements a user-driven, configurable, and queue-based approach to price data collection. It emphasizes anti-detection, data quality, and extensibility.

## Architecture

### 1. User-Driven Discovery
- Users search for products they want to track
- System creates discovery tasks to find products on retailer sites
- Discovered products are added to the scraping queue
- Aggregates demand across all users to prioritize scraping

### 2. Queue-Based Processing
- **Discovery Queue**: User-initiated product searches
- **Scraping Queue**: Aggregated scraping tasks with priority and scheduling
- **Configurable Intervals**: Different scraping frequencies per category/retailer

### 3. Anti-Detection Strategy
- **Proxy Rotation**: Configurable per retailer
- **User Agent Rotation**: Randomized browser fingerprints
- **Rate Limiting**: Configurable requests per minute/hour per retailer
- **Failure Tolerance**: 15% default failure rate, configurable per retailer

## Configuration System

### Retailer Configuration
```sql
-- Each retailer has configurable scraping parameters
CREATE TABLE retailers (
    -- Rate limiting
    requests_per_minute INTEGER DEFAULT 10,
    requests_per_hour INTEGER DEFAULT 300,
    delay_between_requests_ms INTEGER DEFAULT 2000,
    
    -- Scraping intervals
    default_scrape_interval_hours INTEGER DEFAULT 24,
    sale_period_interval_hours INTEGER DEFAULT 6,
    
    -- Anti-detection
    use_proxy_rotation BOOLEAN DEFAULT TRUE,
    use_user_agent_rotation BOOLEAN DEFAULT TRUE,
    
    -- Failure tolerance
    max_failure_rate_percent DECIMAL(5,2) DEFAULT 15.0
);
```

### Category-Specific Intervals
```sql
-- Different scraping frequencies by product category
CREATE TABLE category_scraping_config (
    default_interval_hours INTEGER DEFAULT 24,
    sale_period_interval_hours INTEGER DEFAULT 6,
    high_demand_interval_hours INTEGER DEFAULT 12,
    price_change_threshold_percent DECIMAL(5,2) DEFAULT 10.0
);
```

### Price Validation Rules
```sql
-- Configurable price validation to filter bad data
CREATE TABLE price_validation_config (
    min_price_multiplier DECIMAL(3,2) DEFAULT 0.1, -- reject < 0.1x average
    max_price_multiplier DECIMAL(3,2) DEFAULT 10.0, -- reject > 10x average
    min_price_per_gram DECIMAL(6,2),
    max_price_per_gram DECIMAL(6,2),
    max_price_change_percent_daily DECIMAL(5,2) DEFAULT 50.0
);
```

## Workflow

### 1. Product Discovery Flow
```
User Search Request
    ↓
Discovery Queue (pending)
    ↓
Search retailer sites
    ↓
Extract product information
    ↓
Validate and normalize data
    ↓
Add to Product Catalog
    ↓
Schedule for regular scraping
```

### 2. Regular Scraping Flow
```
Scheduler (cron/timer)
    ↓
Check category configurations
    ↓
Generate scraping tasks
    ↓
Add to Scraping Queue with priority
    ↓
Process queue (FIFO with priority)
    ↓
Execute scraping with anti-detection
    ↓
Validate price data
    ↓
Store price history
    ↓
Trigger user alerts if needed
```

## Implementation Details

### Initial Retailers
- **Amazon India**: 15 req/min, 600 req/hour
- **Flipkart**: 12 req/min, 500 req/hour  
- **HealthKart**: 10 req/min, 400 req/hour
- **Nutrabay**: 8 req/min, 300 req/hour

### Error Handling
- **Temporary Spikes**: Ignore obvious data errors
- **Retailer Errors**: Log and skip, don't store invalid data
- **Network Issues**: Retry with exponential backoff
- **Rate Limiting**: Respect 429 responses, adjust intervals

### Data Quality
- **Price Validation**: Reject prices outside reasonable ranges
- **Confidence Scoring**: Track data reliability (0.0-1.0)
- **Change Detection**: Flag suspicious price movements
- **Manual Review**: Queue suspicious data for verification

## Anti-Detection Features

### 1. Request Distribution
- Spread requests across time to mimic human behavior
- Randomize intervals within configured bounds
- Avoid burst patterns that trigger rate limiting

### 2. Browser Emulation
- Rotate user agents from real browser pools
- Include standard headers (Accept, Accept-Language, etc.)
- Maintain session consistency where required

### 3. Proxy Management
- Rotate IP addresses from residential proxy pools
- Geographic distribution (India-focused)
- Health checking and automatic failover

### 4. Behavioral Patterns
- Random delays between requests (1-5 seconds)
- Occasional longer pauses (30-60 seconds)
- Weekend/holiday schedule adjustments

## Monitoring and Alerting

### Success Metrics
- **Scraping Success Rate**: Target >85% per retailer
- **Data Quality Score**: Target >95% valid prices
- **Coverage**: % of tracked products scraped daily
- **Latency**: Average time from request to data

### Alert Triggers
- Success rate drops below 80% for any retailer
- Queue backlog exceeds 6 hours
- Price validation failure rate >20%
- Anti-detection countermeasures detected

## Scalability Considerations

### Horizontal Scaling
- Stateless scraper workers
- Redis-based queue coordination
- Database connection pooling
- Distributed proxy management

### Performance Optimization
- Concurrent request processing
- Connection reuse and keep-alive
- Gzip compression support
- Response caching for static content

## Development Environment

### Local Setup with SQLite
- Use SQLite for local development and testing
- Mock external retailer requests
- Generate realistic test data with price fluctuations
- VSCode development environment with Go extensions

### Testing Strategy
- **Unit Tests**: Individual scraper components
- **Integration Tests**: End-to-end scraping workflows
- **Contract Tests**: Retailer site structure validation
- **Load Tests**: Queue processing and database performance

## Configuration Examples

### Amazon Configuration
```json
{
  "retailer": "amazon",
  "requests_per_minute": 15,
  "requests_per_hour": 600,
  "delay_between_requests_ms": 2000,
  "use_proxy_rotation": true,
  "use_user_agent_rotation": true,
  "max_failure_rate_percent": 15.0,
  "search_url_template": "https://www.amazon.in/s?k={query}&ref=sr_st_relevance",
  "price_selectors": [
    ".a-price-whole",
    ".a-offscreen"
  ]
}
```

### Category Configuration
```json
{
  "category": "whey-protein",
  "default_interval_hours": 24,
  "sale_period_interval_hours": 6,
  "high_demand_interval_hours": 12,
  "price_change_threshold_percent": 10.0
}
```

## Legal Compliance

### Robots.txt Compliance
- Check and respect robots.txt files
- Implement crawl-delay directives
- Honor disallow rules for specific paths

### Data Usage
- Only collect publicly available pricing data
- No copyrighted content (images, descriptions)
- Respect terms of service where possible
- Implement opt-out mechanisms

### Rate Limiting Respect
- Never exceed reasonable request rates
- Back off when receiving 429 responses
- Implement circuit breakers for problematic sites
- Monitor and adjust based on site responses

## Future Enhancements

### Phase 2 Features
- Machine learning for price prediction
- Dynamic rate adjustment based on success rates
- Advanced proxy rotation strategies
- Real-time alert system integration

### Phase 3 Features
- Multi-region scraping support
- Advanced anti-CAPTCHA solutions
- Retailer API integrations where available
- Predictive caching and pre-fetching