-- SQLite Schema for Development Environment
-- Compatible with PostgreSQL production schema
-- Note: SQLite limitations require some adaptations

-- Enable foreign key support
PRAGMA foreign_keys = ON;

-- Users table (simplified for SQLite)
CREATE TABLE users (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    email_hash TEXT UNIQUE NOT NULL,
    email_encrypted TEXT NOT NULL,
    name_encrypted TEXT,
    avatar_url TEXT,
    email_verified INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME,
    gdpr_consent_at DATETIME,
    gdpr_consent_version TEXT DEFAULT '1.0',
    data_retention_until DATETIME DEFAULT (datetime('now', '+7 years')),
    consent_marketing INTEGER DEFAULT 0,
    consent_analytics INTEGER DEFAULT 0,
    created_by TEXT,
    updated_by TEXT
);

-- Brands table
CREATE TABLE brands (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    official_website TEXT,
    country_origin TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Categories table (hierarchical)
CREATE TABLE categories (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    parent_id TEXT REFERENCES categories(id),
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Products table
CREATE TABLE products (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    brand_id TEXT NOT NULL REFERENCES brands(id),
    category_id TEXT NOT NULL REFERENCES categories(id),
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    protein_per_serving REAL,
    servings_per_container INTEGER,
    serving_size TEXT,
    ingredients TEXT,
    fssai_license TEXT,
    truthified_channel_testing INTEGER DEFAULT 0,
    image_url TEXT,
    manufacturer TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Product variants table
CREATE TABLE product_variants (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    flavor TEXT,
    size TEXT,
    size_normalized_grams INTEGER,
    sku TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Retailers table
CREATE TABLE retailers (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    website_url TEXT NOT NULL,
    logo_url TEXT,
    base_search_url TEXT,
    product_url_pattern TEXT,
    requests_per_minute INTEGER DEFAULT 10,
    requests_per_hour INTEGER DEFAULT 300,
    delay_between_requests_ms INTEGER DEFAULT 2000,
    default_scrape_interval_hours INTEGER DEFAULT 24,
    sale_period_interval_hours INTEGER DEFAULT 6,
    use_proxy_rotation INTEGER DEFAULT 1,
    use_user_agent_rotation INTEGER DEFAULT 1,
    max_failure_rate_percent REAL DEFAULT 15.0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Product listings at retailers
CREATE TABLE product_listings (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    product_variant_id TEXT NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
    retailer_id TEXT NOT NULL REFERENCES retailers(id),
    retailer_product_id TEXT,
    retailer_url TEXT NOT NULL,
    retailer_sku TEXT,
    current_price REAL,
    currency TEXT DEFAULT 'INR',
    is_available INTEGER DEFAULT 1,
    stock_status TEXT,
    last_scraped_at DATETIME,
    scrape_success INTEGER DEFAULT 1,
    scrape_error_message TEXT,
    scrape_attempts_count INTEGER DEFAULT 0,
    price_validation_status TEXT DEFAULT 'valid',
    price_validation_reason TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Price history table
CREATE TABLE price_history (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    product_listing_id TEXT NOT NULL REFERENCES product_listings(id) ON DELETE CASCADE,
    price REAL NOT NULL,
    previous_price REAL,
    currency TEXT DEFAULT 'INR',
    price_change_amount REAL,
    price_change_percent REAL,
    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    effective_from DATETIME DEFAULT CURRENT_TIMESTAMP,
    source TEXT DEFAULT 'scraper',
    confidence_score REAL DEFAULT 1.0
);

-- User-driven product discovery queue
CREATE TABLE product_discovery_queue (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT REFERENCES users(id) ON DELETE SET NULL,
    search_query TEXT NOT NULL,
    brand_name TEXT,
    category_hint TEXT,
    target_retailers TEXT, -- JSON array as TEXT in SQLite
    products_found INTEGER DEFAULT 0,
    discovery_completed INTEGER DEFAULT 0,
    status TEXT DEFAULT 'pending',
    priority INTEGER DEFAULT 5,
    requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_processing_at DATETIME,
    completed_at DATETIME,
    error_message TEXT,
    discovered_products TEXT -- JSON as TEXT in SQLite
);

-- Scraping queue
CREATE TABLE scraping_queue (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    product_listing_id TEXT NOT NULL REFERENCES product_listings(id),
    priority INTEGER DEFAULT 5,
    source TEXT DEFAULT 'scheduled',
    scheduled_for DATETIME DEFAULT CURRENT_TIMESTAMP,
    category_id TEXT REFERENCES categories(id),
    status TEXT DEFAULT 'pending',
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_processing_at DATETIME,
    completed_at DATETIME,
    success INTEGER,
    error_message TEXT,
    response_time_ms INTEGER
);

-- Price alerts table
CREATE TABLE price_alerts (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    target_price REAL NOT NULL,
    retailer_ids TEXT, -- JSON array as TEXT
    notification_methods TEXT DEFAULT '["email"]', -- JSON array
    notification_frequency TEXT DEFAULT 'immediate',
    is_active INTEGER DEFAULT 1,
    last_triggered_at DATETIME,
    trigger_count INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- User favorites table
CREATE TABLE user_favorites (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    added_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    category TEXT,
    notes TEXT
);

-- Category-specific scraping intervals
CREATE TABLE category_scraping_config (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    category_id TEXT NOT NULL REFERENCES categories(id) UNIQUE,
    default_interval_hours INTEGER DEFAULT 24,
    sale_period_interval_hours INTEGER DEFAULT 6,
    high_demand_interval_hours INTEGER DEFAULT 12,
    price_change_threshold_percent REAL DEFAULT 10.0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- User price alert thresholds
CREATE TABLE user_alert_thresholds (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_variant_id TEXT REFERENCES product_variants(id) ON DELETE CASCADE,
    price_drop_percentage REAL,
    price_drop_absolute REAL,
    target_price REAL,
    applies_to_all_products INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Price validation configuration
CREATE TABLE price_validation_config (
    id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
    category_id TEXT REFERENCES categories(id),
    min_price_multiplier REAL DEFAULT 0.1,
    max_price_multiplier REAL DEFAULT 10.0,
    min_price_per_gram REAL,
    max_price_per_gram REAL,
    max_price_change_percent_daily REAL DEFAULT 50.0,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_brands_slug ON brands(slug);
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_retailers_slug ON retailers(slug);
CREATE INDEX idx_listings_variant ON product_listings(product_variant_id);
CREATE INDEX idx_listings_retailer ON product_listings(retailer_id);
CREATE INDEX idx_listings_price ON product_listings(current_price);
CREATE INDEX idx_price_history_listing ON price_history(product_listing_id);
CREATE INDEX idx_price_history_recorded ON price_history(recorded_at);
CREATE INDEX idx_discovery_queue_status ON product_discovery_queue(status);
CREATE INDEX idx_scraping_queue_status ON scraping_queue(status);
CREATE INDEX idx_scraping_queue_scheduled ON scraping_queue(scheduled_for);
CREATE INDEX idx_alert_thresholds_user ON user_alert_thresholds(user_id);

-- Insert initial test data
INSERT INTO brands (name, slug, country_origin, is_active) VALUES
('Optimum Nutrition', 'optimum-nutrition', 'USA', 1),
('MuscleBlaze', 'muscleblaze', 'India', 1),
('Dymatize', 'dymatize', 'USA', 1),
('BSN', 'bsn', 'USA', 1),
('The Whole Truth', 'the-whole-truth', 'India', 1);

INSERT INTO categories (name, slug, description, sort_order) VALUES
('Protein Supplements', 'protein-supplements', 'All protein supplement products', 1),
('Whey Protein', 'whey-protein', 'Whey protein powders and supplements', 2),
('Whey Isolate', 'whey-isolate', 'Whey protein isolate products', 3),
('Whey Concentrate', 'whey-concentrate', 'Whey protein concentrate products', 4),
('Casein Protein', 'casein-protein', 'Casein protein supplements', 5),
('Plant Protein', 'plant-protein', 'Plant-based protein supplements', 6);

INSERT INTO retailers (name, slug, website_url, requests_per_minute, requests_per_hour, is_active) VALUES
('Amazon', 'amazon', 'https://www.amazon.in', 15, 600, 1),
('Flipkart', 'flipkart', 'https://www.flipkart.com', 12, 500, 1),
('HealthKart', 'healthkart', 'https://www.healthkart.com', 10, 400, 1),
('Nutrabay', 'nutrabay', 'https://www.nutrabay.com', 8, 300, 1);

-- Sample test products for development
INSERT INTO products (brand_id, category_id, name, slug, protein_per_serving, servings_per_container, serving_size, truthified_channel_testing) 
SELECT 
    b.id, 
    c.id, 
    'Gold Standard 100% Whey', 
    'gold-standard-100-whey',
    24.0,
    74,
    '30g',
    0
FROM brands b, categories c 
WHERE b.slug = 'optimum-nutrition' AND c.slug = 'whey-protein';

INSERT INTO products (brand_id, category_id, name, slug, protein_per_serving, servings_per_container, serving_size, truthified_channel_testing) 
SELECT 
    b.id, 
    c.id, 
    'Biozyme Performance Whey', 
    'biozyme-performance-whey',
    25.0,
    44,
    '33g',
    0
FROM brands b, categories c 
WHERE b.slug = 'muscleblaze' AND c.slug = 'whey-protein';

INSERT INTO products (brand_id, category_id, name, slug, protein_per_serving, servings_per_container, serving_size, truthified_channel_testing) 
SELECT 
    b.id, 
    c.id, 
    'Slow Coffee & Bold Chocolate Protein', 
    'slow-coffee-bold-chocolate-protein',
    26.0,
    30,
    '30g',
    1
FROM brands b, categories c 
WHERE b.slug = 'the-whole-truth' AND c.slug = 'whey-protein';