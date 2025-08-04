# API Specification

## Overview

RESTful API for the Whey Protein Price Comparison Platform. All endpoints are optimized for sub-50ms response times with comprehensive caching and error handling.

**Base URL**: `https://api.proteinprices.com/v1`  
**Content-Type**: `application/json`  
**Authentication**: None required for public endpoints

## Core Principles

- **Performance First**: <50ms response times for cached data
- **Contract Stability**: Backward compatibility guaranteed within major versions
- **Error Consistency**: Standardized error response format
- **Caching**: Aggressive caching with appropriate TTL values
- **Rate Limiting**: 1000 requests/hour per IP for public endpoints

## Data Models

### Product
```json
{
  "id": "prod_123",
  "name": "Optimum Nutrition Gold Standard 100% Whey",
  "brand": "Optimum Nutrition",
  "flavor": "Double Rich Chocolate",
  "weight_grams": 2270,
  "servings": 74,
  "protein_per_serving": 24.0,
  "image_url": "https://cdn.proteinprices.com/products/on-gold-standard.jpg",
  "category": "whey_protein",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### Price
```json
{
  "retailer_id": "amazon",
  "retailer_name": "Amazon India",
  "price": 3299.00,
  "original_price": 3999.00,
  "discount_percent": 17.5,
  "currency": "INR",
  "in_stock": true,
  "affiliate_url": "https://amazon.in/dp/B000QSNYGI?tag=proteinprices-21",
  "last_updated": "2024-01-15T14:30:00Z"
}
```

### Price Comparison Response
```json
{
  "product": {
    "id": "prod_123",
    "name": "Optimum Nutrition Gold Standard 100% Whey",
    "brand": "Optimum Nutrition",
    "flavor": "Double Rich Chocolate"
  },
  "prices": [
    {
      "retailer_id": "amazon",
      "retailer_name": "Amazon India",
      "price": 3299.00,
      "original_price": 3999.00,
      "discount_percent": 17.5,
      "in_stock": true,
      "affiliate_url": "https://amazon.in/dp/B000QSNYGI?tag=proteinprices-21",
      "last_updated": "2024-01-15T14:30:00Z"
    }
  ],
  "best_price": {
    "retailer_id": "flipkart",
    "price": 3199.00,
    "savings": 100.00
  },
  "cache_timestamp": "2024-01-15T14:35:00Z"
}
```

### Search Result
```json
{
  "products": [
    {
      "id": "prod_123",
      "name": "Optimum Nutrition Gold Standard 100% Whey",
      "brand": "Optimum Nutrition",
      "flavor": "Double Rich Chocolate",
      "image_url": "https://cdn.proteinprices.com/products/on-gold-standard.jpg",
      "min_price": 3199.00,
      "max_price": 3999.00,
      "retailer_count": 4,
      "best_deal": {
        "retailer": "Flipkart",
        "price": 3199.00,
        "discount_percent": 20.0
      }
    }
  ],
  "total_count": 127,
  "page": 1,
  "per_page": 20,
  "total_pages": 7
}
```

### Error Response
```json
{
  "error": {
    "code": "PRODUCT_NOT_FOUND",
    "message": "Product with ID 'prod_invalid' not found",
    "details": {
      "product_id": "prod_invalid",
      "valid_format": "prod_[0-9a-z]+"
    },
    "timestamp": "2024-01-15T14:30:00Z",
    "request_id": "req_abc123def456"
  }
}
```

## Authentication

Currently, all endpoints are public and require no authentication. Future versions will include:
- API key authentication for B2B partners
- Rate limiting based on API keys
- Premium endpoints for advanced features

## Endpoints

### 1. Search Products

**Endpoint**: `GET /products/search`

**Description**: Search for whey protein products with filtering options

**Parameters**:
- `q` (string, required): Search query
- `brand` (string, optional): Filter by brand name
- `flavor` (string, optional): Filter by flavor
- `min_price` (number, optional): Minimum price filter
- `max_price` (number, optional): Maximum price filter
- `min_protein` (number, optional): Minimum protein per serving
- `sort` (string, optional): Sort order (`price_asc`, `price_desc`, `name_asc`, `protein_desc`)
- `page` (integer, optional, default=1): Page number
- `per_page` (integer, optional, default=20, max=100): Results per page

**Response**: `200 OK`
```json
{
  "products": [...],
  "pagination": {
    "total_count": 127,
    "page": 1,
    "per_page": 20,
    "total_pages": 7,
    "has_next": true,
    "has_prev": false
  },
  "filters_applied": {
    "query": "optimum nutrition",
    "brand": "Optimum Nutrition",
    "sort": "price_asc"
  },
  "cache_info": {
    "cached": true,
    "cache_key": "search_hash_abc123",
    "ttl_seconds": 3600
  }
}
```

**Error Responses**:
- `400 Bad Request`: Invalid query parameters
- `422 Unprocessable Entity`: Invalid filter values
- `429 Too Many Requests`: Rate limit exceeded

**Example**:
```bash
GET /products/search?q=whey%20protein&brand=optimum%20nutrition&sort=price_asc&page=1&per_page=10
```

### 2. Get Product Details

**Endpoint**: `GET /products/{product_id}`

**Description**: Get detailed information about a specific product

**Parameters**:
- `product_id` (string, required): Unique product identifier

**Response**: `200 OK`
```json
{
  "product": {
    "id": "prod_123",
    "name": "Optimum Nutrition Gold Standard 100% Whey",
    "brand": "Optimum Nutrition",
    "flavor": "Double Rich Chocolate",
    "weight_grams": 2270,
    "servings": 74,
    "protein_per_serving": 24.0,
    "carbs_per_serving": 3.0,
    "fat_per_serving": 1.0,
    "calories_per_serving": 120,
    "ingredients": ["Whey Protein Isolate", "Whey Protein Concentrate", "Natural Flavors"],
    "image_url": "https://cdn.proteinprices.com/products/on-gold-standard.jpg",
    "description": "The world's best-selling whey protein powder...",
    "category": "whey_protein",
    "created_at": "2024-01-15T10:30:00Z"
  },
  "specifications": {
    "protein_percent": 80.0,
    "bcaa_per_serving": 5.5,
    "glutamine_per_serving": 4.0,
    "digestibility": "fast"
  }
}
```

**Error Responses**:
- `404 Not Found`: Product not found
- `400 Bad Request`: Invalid product ID format

### 3. Get Product Prices

**Endpoint**: `GET /products/{product_id}/prices`

**Description**: Get current prices for a product across all retailers

**Parameters**:
- `product_id` (string, required): Unique product identifier
- `include_out_of_stock` (boolean, optional, default=false): Include out of stock prices

**Response**: `200 OK`
```json
{
  "product": {
    "id": "prod_123",
    "name": "Optimum Nutrition Gold Standard 100% Whey",
    "flavor": "Double Rich Chocolate"
  },
  "prices": [
    {
      "retailer_id": "amazon",
      "retailer_name": "Amazon India",
      "price": 3299.00,
      "original_price": 3999.00,
      "discount_percent": 17.5,
      "currency": "INR",
      "in_stock": true,
      "affiliate_url": "https://amazon.in/dp/B000QSNYGI?tag=proteinprices-21",
      "delivery_time": "1-2 days",
      "last_updated": "2024-01-15T14:30:00Z"
    }
  ],
  "price_stats": {
    "lowest_price": 3199.00,
    "highest_price": 3999.00,
    "average_price": 3465.50,
    "price_range": 800.00,
    "retailers_in_stock": 3,
    "total_retailers": 4
  },
  "best_deal": {
    "retailer_id": "flipkart",
    "retailer_name": "Flipkart",
    "price": 3199.00,
    "savings_amount": 100.00,
    "savings_percent": 3.0
  },
  "last_updated": "2024-01-15T14:30:00Z"
}
```

**Cache Headers**:
- `Cache-Control: public, max-age=300` (5 minutes)
- `ETag: "prices_prod_123_20240115143000"`

### 4. Get Price History

**Endpoint**: `GET /products/{product_id}/price-history`

**Description**: Get historical price data for a product

**Parameters**:
- `product_id` (string, required): Unique product identifier
- `retailer_id` (string, optional): Filter by specific retailer
- `days` (integer, optional, default=30, max=365): Number of days of history
- `interval` (string, optional, default=daily): Data interval (`hourly`, `daily`, `weekly`)

**Response**: `200 OK`
```json
{
  "product_id": "prod_123",
  "retailer_id": "amazon",
  "price_history": [
    {
      "date": "2024-01-15",
      "price": 3299.00,
      "original_price": 3999.00,
      "in_stock": true
    },
    {
      "date": "2024-01-14", 
      "price": 3399.00,
      "original_price": 3999.00,
      "in_stock": true
    }
  ],
  "statistics": {
    "min_price": 3199.00,
    "max_price": 3999.00,
    "avg_price": 3465.50,
    "price_changes": 12,
    "days_tracked": 30
  }
}
```

### 5. Get Brands

**Endpoint**: `GET /brands`

**Description**: Get list of all available brands

**Parameters**:
- `page` (integer, optional, default=1): Page number
- `per_page` (integer, optional, default=50, max=100): Results per page

**Response**: `200 OK`
```json
{
  "brands": [
    {
      "id": "optimum-nutrition",
      "name": "Optimum Nutrition",
      "logo_url": "https://cdn.proteinprices.com/brands/on.jpg",
      "product_count": 24,
      "avg_price": 3299.00,
      "country": "USA"
    }
  ],
  "total_count": 45
}
```

### 6. Get Retailers

**Endpoint**: `GET /retailers`

**Description**: Get list of supported retailers

**Response**: `200 OK`
```json
{
  "retailers": [
    {
      "id": "amazon",
      "name": "Amazon India",
      "domain": "amazon.in",
      "logo_url": "https://cdn.proteinprices.com/retailers/amazon.jpg",
      "active": true,
      "product_count": 1247,
      "avg_delivery_days": 2,
      "free_shipping_threshold": 499.00,
      "supported_payment_methods": ["card", "upi", "cod", "emi"],
      "affiliate_program": "amazon_associates",
      "commission_rate": "4-8%"
    },
    {
      "id": "flipkart",
      "name": "Flipkart",
      "domain": "flipkart.com",
      "logo_url": "https://cdn.proteinprices.com/retailers/flipkart.jpg",
      "active": true,
      "product_count": 892,
      "avg_delivery_days": 3,
      "free_shipping_threshold": 500.00,
      "supported_payment_methods": ["card", "upi", "cod", "emi"],
      "affiliate_program": "flipkart_affiliate",
      "commission_rate": "2-6%"
    },
    {
      "id": "healthkart",
      "name": "HealthKart",
      "domain": "healthkart.com",
      "logo_url": "https://cdn.proteinprices.com/retailers/healthkart.jpg",
      "active": true,
      "product_count": 456,
      "avg_delivery_days": 4,
      "free_shipping_threshold": 399.00,
      "supported_payment_methods": ["card", "upi", "cod"],
      "affiliate_program": "healthkart_partners",
      "commission_rate": "3-7%"
    },
    {
      "id": "nutrabay",
      "name": "Nutrabay",
      "domain": "nutrabay.com",
      "logo_url": "https://cdn.proteinprices.com/retailers/nutrabay.jpg",
      "active": true,
      "product_count": 234,
      "avg_delivery_days": 5,
      "free_shipping_threshold": 449.00,
      "supported_payment_methods": ["card", "upi", "cod"],
      "affiliate_program": "nutrabay_affiliate",
      "commission_rate": "5-10%"
    }
  ],
  "total_count": 4,
  "last_updated": "2024-01-15T14:30:00Z"
}
```

### 7. Get Popular Products

**Endpoint**: `GET /products/popular`

**Description**: Get list of most popular/trending whey protein products

**Parameters**:
- `category` (string, optional): Filter by category (default: all)
- `timeframe` (string, optional): Popularity timeframe (`7d`, `30d`, `90d`, default=`30d`)
- `limit` (integer, optional, default=20, max=50): Number of products to return

**Response**: `200 OK`
```json
{
  "popular_products": [
    {
      "id": "prod_123",
      "name": "Optimum Nutrition Gold Standard 100% Whey",
      "brand": "Optimum Nutrition",
      "flavor": "Double Rich Chocolate",
      "image_url": "https://cdn.proteinprices.com/products/on-gold-standard.jpg",
      "popularity_score": 98.5,
      "view_count_30d": 15420,
      "click_count_30d": 2340,
      "min_price": 3199.00,
      "price_trend": "down",
      "price_change_percent": -5.2,
      "in_stock_retailers": 4,
      "total_retailers": 4
    }
  ],
  "timeframe": "30d",
  "last_updated": "2024-01-15T14:30:00Z"
}
```

### 8. Get Deal Alerts

**Endpoint**: `GET /deals`

**Description**: Get current deals and price drops across all products

**Parameters**:
- `min_discount` (number, optional, default=10): Minimum discount percentage
- `retailer` (string, optional): Filter by specific retailer
- `brand` (string, optional): Filter by brand
- `sort` (string, optional): Sort order (`discount_desc`, `price_asc`, `recent`)
- `page` (integer, optional, default=1): Page number
- `per_page` (integer, optional, default=20, max=50): Results per page

**Response**: `200 OK`
```json
{
  "deals": [
    {
      "product": {
        "id": "prod_123",
        "name": "Optimum Nutrition Gold Standard 100% Whey",
        "brand": "Optimum Nutrition",
        "flavor": "Double Rich Chocolate",
        "image_url": "https://cdn.proteinprices.com/products/on-gold-standard.jpg"
      },
      "deal": {
        "retailer_id": "amazon",
        "retailer_name": "Amazon India",
        "current_price": 3199.00,
        "original_price": 3999.00,
        "discount_percent": 20.0,
        "savings_amount": 800.00,
        "deal_type": "limited_time",
        "expires_at": "2024-01-20T23:59:59Z",
        "affiliate_url": "https://amazon.in/dp/B000QSNYGI?tag=proteinprices-21"
      },
      "price_history": {
        "lowest_30d": 3199.00,
        "highest_30d": 3999.00,
        "avg_30d": 3599.00
      }
    }
  ],
  "pagination": {
    "total_count": 45,
    "page": 1,
    "per_page": 20,
    "total_pages": 3
  },
  "filters_applied": {
    "min_discount": 15,
    "sort": "discount_desc"
  }
}
```

### 9. Health Check

**Endpoint**: `GET /health`

**Description**: Service health check endpoint

**Response**: `200 OK`
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T14:30:00Z",
  "version": "1.0.0",
  "environment": "production",
  "uptime_seconds": 86400,
  "services": {
    "database": {
      "status": "healthy",
      "response_time_ms": 2.3,
      "connections_active": 12,
      "connections_max": 100,
      "last_migration": "2024-01-15T10:00:00Z"
    },
    "cache": {
      "status": "healthy",
      "response_time_ms": 0.8,
      "memory_used_mb": 245,
      "memory_max_mb": 512,
      "hit_rate_percent": 94.2
    },
    "scraper": {
      "status": "healthy",
      "last_run": "2024-01-15T14:00:00Z",
      "success_rate_24h": 98.5,
      "active_jobs": 3,
      "next_scheduled_run": "2024-01-15T14:30:00Z"
    },
    "search": {
      "status": "healthy",
      "index_size": 1247,
      "last_indexed": "2024-01-15T14:15:00Z"
    }
  },
  "system": {
    "memory_usage_percent": 45.2,
    "cpu_usage_percent": 12.8,
    "disk_usage_percent": 23.1
  },
  "build_info": {
    "git_commit": "abc123def456",
    "build_time": "2024-01-15T08:00:00Z",
    "go_version": "1.21.5"
  }
}
```

**Unhealthy Response**: `503 Service Unavailable`
```json
{
  "status": "unhealthy",
  "timestamp": "2024-01-15T14:30:00Z",
  "errors": [
    {
      "service": "database",
      "error": "Connection timeout after 5 seconds",
      "since": "2024-01-15T14:25:00Z"
    }
  ],
  "partial_services": ["cache", "search"]
}
```

### 10. API Metrics

**Endpoint**: `GET /metrics`

**Description**: Prometheus metrics endpoint (restricted access)

**Access**: Internal only (127.0.0.1)

**Response**: `200 OK` (Prometheus format)
```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/api/products/search",status="200"} 1234

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",route="/api/products/search",le="0.01"} 800
http_request_duration_seconds_bucket{method="GET",route="/api/products/search",le="0.05"} 1200

# HELP price_updates_total Total number of price updates
# TYPE price_updates_total counter
price_updates_total{retailer="amazon",status="success"} 15420

# HELP scraper_success_rate Current scraper success rate
# TYPE scraper_success_rate gauge
scraper_success_rate{retailer="amazon"} 0.982
```

## Rate Limiting

### Current Limits
- **Public Endpoints**: 1000 requests/hour per IP
- **Search Endpoint**: 100 requests/minute per IP  
- **Price Endpoints**: 500 requests/hour per IP
- **Health Check**: No limit
- **Metrics**: Internal access only

### Headers
All responses include rate limiting headers:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1642234800
X-RateLimit-Window: 3600
X-RateLimit-Policy: sliding-window
```

### Rate Limit Exceeded Response

**Response**: `429 Too Many Requests`
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 45 minutes.",
    "details": {
      "limit": 1000,
      "window_seconds": 3600,
      "retry_after_seconds": 2700,
      "current_usage": 1001,
      "reset_time": "2024-01-15T15:30:00Z"
    },
    "timestamp": "2024-01-15T14:30:00Z",
    "request_id": "req_abc123def456"
  }
}
```

### Rate Limiting by Endpoint

| Endpoint | Limit | Window | Burst |
|----------|-------|--------|--------|
| `/products/search` | 100/min | 1 minute | 10 |
| `/products/{id}` | 200/min | 1 minute | 20 |
| `/products/{id}/prices` | 150/min | 1 minute | 15 |
| `/products/{id}/price-history` | 50/min | 1 minute | 5 |
| `/brands` | 1000/hour | 1 hour | 50 |
| `/retailers` | 1000/hour | 1 hour | 50 |
| `/deals` | 100/min | 1 minute | 10 |
| `/health` | No limit | - | - |

## Caching Strategy

### Cache Headers by Endpoint

| Endpoint | Cache-Control | Max-Age | ETag | Varies |
|----------|---------------|---------|------|---------|
| `/products/search` | `public, max-age=3600` | 1 hour | Yes | Accept-Encoding |
| `/products/{id}` | `public, max-age=7200` | 2 hours | Yes | Accept-Encoding |
| `/products/{id}/prices` | `public, max-age=300` | 5 minutes | Yes | Accept-Encoding |
| `/products/{id}/price-history` | `public, max-age=1800` | 30 minutes | Yes | Accept-Encoding |
| `/brands` | `public, max-age=86400` | 24 hours | Yes | Accept-Encoding |
| `/retailers` | `public, max-age=43200` | 12 hours | Yes | Accept-Encoding |
| `/deals` | `public, max-age=600` | 10 minutes | Yes | Accept-Encoding |

### ETags and Conditional Requests

All cacheable responses include ETags:
```
ETag: "W/\"search_results_hash_abc123\""
Last-Modified: Mon, 15 Jan 2024 14:30:00 GMT
```

**Conditional Request Support**:
```bash
GET /products/search?q=whey
If-None-Match: "W/\"search_results_hash_abc123\""
If-Modified-Since: Mon, 15 Jan 2024 14:30:00 GMT

# Response: 304 Not Modified (if unchanged)
```

### Cache Invalidation

Cache invalidation triggers:
- **Price Updates**: Invalidate product prices and search results
- **Product Changes**: Invalidate product details and search results  
- **New Products**: Invalidate search results and popular products
- **Retailer Changes**: Invalidate retailer list and related data

## Error Handling

### Standard Error Codes

| HTTP Status | Error Code | Description | Retry Strategy |
|-------------|------------|-------------|----------------|
| 400 | `BAD_REQUEST` | Invalid request parameters | Fix request, don't retry |
| 401 | `UNAUTHORIZED` | Authentication required | Provide valid credentials |
| 403 | `FORBIDDEN` | Access denied | Check permissions |
| 404 | `NOT_FOUND` | Resource not found | Verify resource exists |
| 422 | `UNPROCESSABLE_ENTITY` | Valid request, invalid data | Fix data, don't retry |
| 429 | `RATE_LIMIT_EXCEEDED` | Too many requests | Retry after delay |
| 500 | `INTERNAL_ERROR` | Server error | Retry with exponential backoff |
| 502 | `BAD_GATEWAY` | Upstream service error | Retry with backoff |
| 503 | `SERVICE_UNAVAILABLE` | Service temporarily down | Retry after delay |
| 504 | `GATEWAY_TIMEOUT` | Request timeout | Retry with longer timeout |

### Error Response Format

All errors follow consistent structure:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "Additional context",
      "suggestion": "How to fix this error"
    },
    "timestamp": "2024-01-15T14:30:00Z",
    "request_id": "req_abc123def456",
    "trace_id": "trace_789xyz012",
    "documentation_url": "https://docs.proteinprices.com/errors#ERROR_CODE"
  }
}
```

### Validation Errors

For requests with multiple validation errors:
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Request validation failed",
    "details": {
      "validation_errors": [
        {
          "field": "min_price",
          "code": "INVALID_TYPE",
          "message": "Must be a number",
          "received": "abc",
          "expected": "number"
        },
        {
          "field": "per_page",
          "code": "OUT_OF_RANGE",
          "message": "Must be between 1 and 100",
          "received": 150,
          "min": 1,
          "max": 100
        }
      ]
    },
    "timestamp": "2024-01-15T14:30:00Z",
    "request_id": "req_abc123def456"
  }
}
```

### Error Recovery Recommendations

Each error includes recovery suggestions:
```json
{
  "error": {
    "code": "PRODUCT_NOT_FOUND",
    "message": "Product with ID 'prod_invalid' not found",
    "details": {
      "product_id": "prod_invalid",
      "suggestions": [
        "Check if product ID format is correct (prod_[alphanumeric])",
        "Use /products/search to find available products",
        "Verify product hasn't been discontinued"
      ],
      "similar_products": [
        {
          "id": "prod_124",
          "name": "Similar Whey Protein Product",
          "similarity_score": 0.89
        }
      ]
    }
  }
}
```

## Pagination

### Standard Pagination

All list endpoints use cursor-based pagination:

**Request Parameters**:
- `page` (integer, 1-based): Page number
- `per_page` (integer): Items per page (max varies by endpoint)
- `cursor` (string, optional): Cursor for next page (more efficient)

**Response Format**:
```json
{
  "data": [...],
  "pagination": {
    "total_count": 1247,
    "page": 2,
    "per_page": 20,
    "total_pages": 63,
    "has_next": true,
    "has_prev": true,
    "next_cursor": "eyJpZCI6MTIzLCJ0cyI6MTY0MjIzNDgwMH0=",
    "prev_cursor": "eyJpZCI6MTAwLCJ0cyI6MTY0MjIzNDcwMH0=",
    "links": {
      "next": "/products/search?q=whey&page=3&per_page=20",
      "prev": "/products/search?q=whey&page=1&per_page=20",
      "first": "/products/search?q=whey&page=1&per_page=20",
      "last": "/products/search?q=whey&page=63&per_page=20"
    }
  },
  "meta": {
    "query_time_ms": 23.5,
    "cached": true,
    "cache_expires_at": "2024-01-15T15:30:00Z"
  }
}
```

### Cursor-Based Pagination (Recommended)

For better performance on large datasets:
```bash
# First request
GET /products/search?q=whey&per_page=20

# Subsequent requests using cursor
GET /products/search?q=whey&per_page=20&cursor=eyJpZCI6MTIzLCJ0cyI6MTY0MjIzNDgwMH0=
```

## Sorting and Filtering

### Available Sort Options by Endpoint

**Products Search** (`/products/search`):
- `relevance` (default): Search relevance score
- `price_asc`: Price low to high
- `price_desc`: Price high to low  
- `name_asc`: Product name A-Z
- `name_desc`: Product name Z-A
- `protein_desc`: Protein content high to low
- `popular`: Popularity score
- `newest`: Recently added products
- `best_deal`: Best discount percentage

**Deals** (`/deals`):
- `discount_desc` (default): Highest discount first
- `discount_asc`: Lowest discount first
- `price_asc`: Cheapest deals first
- `expires_soon`: Deals expiring soonest
- `recent`: Recently added deals

### Complex Filtering Examples

**Multiple filters**:
```bash
GET /products/search?q=whey&brand=optimum%20nutrition&min_price=2000&max_price=5000&min_protein=20&flavor=chocolate&sort=price_asc
```

**Filter operators**:
- `brand` (exact match)
- `min_price`, `max_price` (range)
- `min_protein`, `max_protein` (range)
- `flavor` (partial match)
- `in_stock=true` (boolean)
- `retailers=amazon,flipkart` (array)

## API Versioning

### Current Version: v1

**Versioning Strategy**:
- **URL Versioning**: `/v1/`, `/v2/` in path
- **Header Versioning**: `Accept: application/vnd.proteinprices.v1+json`
- **Backward Compatibility**: Maintained within major versions
- **Deprecation Policy**: 12 months notice before removing endpoints

**Version Headers**:
```
API-Version: 1.0
API-Supported-Versions: 1.0, 1.1
API-Deprecated-Versions: 0.9
```

### Breaking vs Non-Breaking Changes

**Breaking Changes** (require new major version):
- Removing or renaming response fields
- Changing field data types
- Changing HTTP status codes
- Modifying error response format
- Adding required request parameters
- Changing authentication requirements

**Non-Breaking Changes** (same major version):
- Adding new optional request parameters
- Adding new response fields
- Adding new endpoints
- Adding new error codes
- Improving performance
- Bug fixes that don't change behavior

## Performance SLAs

### Response Time Targets (95th percentile)

| Endpoint Category | Target | Measurement |
|------------------|--------|-------------|
| Search | <100ms | Cache hit: <30ms, Cache miss: <100ms |
| Product Details | <50ms | Cache hit: <20ms, Cache miss: <50ms |
| Price Data | <50ms | Cache hit: <10ms, Cache miss: <50ms |
| Static Data | <20ms | Always cached |
| Health Check | <10ms | No external dependencies |

### Availability Targets

- **API Uptime**: 99.9% monthly (8.6 minutes downtime max)
- **Data Freshness**: Price updates within 30 minutes
- **Search Index**: Updated within 5 minutes of data changes
- **Error Rate**: <0.1% for successful responses
- **Cache Hit Rate**: >90% for price and product data

### Performance Monitoring Headers

All responses include performance information:
```
X-Response-Time-Ms: 23
X-Cache-Status: HIT
X-Request-ID: req_abc123def456
X-Rate-Limit-Remaining: 99
Server-Timing: db;dur=12.3, cache;dur=0.8, total;dur=23.1
```

## Security

### API Security Measures

**Transport Security**:
- **HTTPS Only**: All API endpoints require HTTPS
- **TLS 1.3**: Latest TLS version with strong cipher suites
- **HSTS**: HTTP Strict Transport Security enabled
- **Certificate Pinning**: Recommended for mobile apps

**Request Security**:
- **Input Validation**: All parameters validated and sanitized
- **SQL Injection Prevention**: Parameterized queries only
- **XSS Protection**: Content Security Policy headers
- **CSRF Protection**: SameSite cookies and CSRF tokens (future auth)

**Rate Limiting & Abuse Prevention**:
- **Progressive Rate Limiting**: Increasing delays for repeated violations
- **IP Blacklisting**: Automatic blocking of abusive IPs
- **Bot Detection**: Challenge suspicious traffic patterns
- **Geographic Restrictions**: Block traffic from specific regions if needed

## SDK Support (Planned)

### Official SDKs

**JavaScript/TypeScript**:
```bash
npm install @proteinprices/sdk
```

```javascript
import { ProteinPricesClient } from '@proteinprices/sdk';

const client = new ProteinPricesClient({
  baseUrl: 'https://api.proteinprices.com/v1',
  timeout: 5000,
  retries: 3
});

// Search with TypeScript support
const results = await client.products.search({
  query: 'whey protein',
  brand: 'optimum-nutrition',
  sort: 'price_asc',
  page: 1,
  perPage: 20
});

// Get prices with automatic retry
const prices = await client.products.getPrices('prod_123');

// Handle errors
try {
  const product = await client.products.get('invalid_id');
} catch (error) {
  if (error.code === 'PRODUCT_NOT_FOUND') {
    console.log('Product not found:', error.details.suggestions);
  }
}
```

**Python**:
```bash
pip install proteinprices-sdk
```

```python
from proteinprices import ProteinPricesClient
from proteinprices.exceptions import ProductNotFound, RateLimitExceeded

client = ProteinPricesClient(
    base_url="https://api.proteinprices.com/v1",
    timeout=5.0,
    max_retries=3
)

# Search products
results = client.products.search(
    query="whey protein",
    brand="optimum-nutrition",
    sort="price_asc"
)

# Handle pagination
for product in client.products.search_iter(query="whey", per_page=50):
    print(f"{product.name}: ₹{product.min_price}")

# Error handling
try:
    prices = client.products.get_prices("prod_123")
except RateLimitExceeded as e:
    print(f"Rate limited. Retry after {e.retry_after} seconds")
except ProductNotFound as e:
    print(f"Product not found. Suggestions: {e.suggestions}")
```

**Go**:
```bash
go get github.com/proteinprices/go-sdk
```

```go
package main

import (
    "context"
    "github.com/proteinprices/go-sdk"
)

func main() {
    client := proteinprices.NewClient(&proteinprices.Config{
        BaseURL: "https://api.proteinprices.com/v1",
        Timeout: 5 * time.Second,
        Retries: 3,
    })
    
    // Search products
    results, err := client.Products.Search(context.Background(), &proteinprices.SearchRequest{
        Query: "whey protein",
        Brand: "optimum-nutrition",
        Sort:  "price_asc",
    })
    
    if err != nil {
        log.Fatal(err)
    }
    
    for _, product := range results.Products {
        fmt.Printf("%s: ₹%.2f\n", product.Name, product.MinPrice)
    }
}
```

## Contact & Support

### API Support Channels

- **Documentation**: https://docs.proteinprices.com/api
- **API Status Page**: https://status.proteinprices.com
- **Support Email**: api-support@proteinprices.com
- **Developer Community**: https://github.com/proteinprices/community
- **Rate Limit Increases**: enterprise@proteinprices.com

### Support Response Times

| Support Tier | Response Time | Channels |
|-------------|---------------|----------|
| Community | Best effort | GitHub Issues |
| Standard | 24-48 hours | Email |
| Premium | 4-8 hours | Email + Phone |
| Enterprise | 1-2 hours | Dedicated support |

### API Changelog

Track all API changes at: https://docs.proteinprices.com/changelog

**Recent Changes**:
- **v1.1.0** (2024-01-15): Added deal alerts endpoint, improved caching
- **v1.0.1** (2024-01-10): Improved error response format, added trace IDs
- **v1.0.0** (2024-01-01): Initial API release with core functionality

### Testing and Development

**Sandbox Environment**:
- **Base URL**: `https://sandbox-api.proteinprices.com/v1`
- **Rate Limits**: 10x higher than production
- **Test Data**: Synthetic product and price data
- **Reset Schedule**: Daily at 00:00 UTC

**Postman Collection**:
- **Collection URL**: https://docs.proteinprices.com/postman
- **Environment Variables**: Pre-configured for sandbox and production
- **Test Examples**: Complete request/response examples for all endpoints

---

**API Specification Version**: 1.1.0  
**Last Updated**: January 15, 2024  
**Document Maintainer**: API Team <api-team@proteinprices.com>  
**Review Schedule**: Monthly  
**Change Approval**: Technical Architecture Review Board

This comprehensive API specification serves as the definitive guide for integrating with the Whey Protein Price Comparison Platform API. For the most up-to-date information, always refer to the online documentation at https://docs.proteinprices.com.