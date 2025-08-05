-- Product Catalog Schema
-- Migration: 002_product_catalog_schema.sql
-- Created: 2024-01-16
-- Description: Product catalog with configurable scraping and user-driven discovery

-- Enable required extensions (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Brands table
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    logo_url VARCHAR(255),
    official_website VARCHAR(255),
    country_origin VARCHAR(50),
    
    -- Status and metadata
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table (hierarchical)
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    parent_id UUID REFERENCES categories(id),
    
    -- Category metadata
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT uq_category_slug_parent UNIQUE(slug, parent_id)
);

-- Products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES brands(id),
    category_id UUID NOT NULL REFERENCES categories(id),
    
    -- Basic product information
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Nutritional information
    protein_per_serving DECIMAL(5,2), -- grams
    servings_per_container INTEGER,
    serving_size VARCHAR(50), -- "30g", "1 scoop", etc.
    
    -- Additional attributes
    ingredients TEXT,
    fssai_license VARCHAR(50),
    
    -- The Whole Truth specific field
    truthified_channel_testing BOOLEAN DEFAULT FALSE,
    
    -- Product metadata
    image_url VARCHAR(255),
    manufacturer VARCHAR(255),
    
    -- Status and timestamps
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT uq_product_brand_slug UNIQUE(brand_id, slug)
);

-- Product variants table (flavor, size combinations)
CREATE TABLE product_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    
    -- Variant information
    flavor VARCHAR(100),
    size VARCHAR(50), -- "1kg", "2.27kg", "5lb", etc.
    size_normalized_grams INTEGER, -- normalized size for comparison
    
    -- Variant identifiers for retailers
    sku VARCHAR(100),
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT uq_variant_product_flavor_size UNIQUE(product_id, flavor, size)
);

-- Retailers table
CREATE TABLE retailers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    
    -- Retailer information
    website_url VARCHAR(255) NOT NULL,
    logo_url VARCHAR(255),
    
    -- Scraping configuration
    base_search_url VARCHAR(500),
    product_url_pattern VARCHAR(500),
    
    -- Rate limiting configuration (per retailer)
    requests_per_minute INTEGER DEFAULT 10,
    requests_per_hour INTEGER DEFAULT 300,
    delay_between_requests_ms INTEGER DEFAULT 2000,
    
    -- Scraping intervals (configurable)
    default_scrape_interval_hours INTEGER DEFAULT 24,
    sale_period_interval_hours INTEGER DEFAULT 6,
    
    -- User agent and proxy settings
    use_proxy_rotation BOOLEAN DEFAULT TRUE,
    use_user_agent_rotation BOOLEAN DEFAULT TRUE,
    
    -- Failure tolerance
    max_failure_rate_percent DECIMAL(5,2) DEFAULT 15.0,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Product listings at retailers
CREATE TABLE product_listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_variant_id UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
    retailer_id UUID NOT NULL REFERENCES retailers(id),
    
    -- Retailer-specific information
    retailer_product_id VARCHAR(255), -- retailer's internal product ID
    retailer_url VARCHAR(500) NOT NULL,
    retailer_sku VARCHAR(100),
    
    -- Current price information
    current_price DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'INR',
    
    -- Availability
    is_available BOOLEAN DEFAULT TRUE,
    stock_status VARCHAR(50), -- "in_stock", "out_of_stock", "limited", etc.
    
    -- Scraping metadata
    last_scraped_at TIMESTAMP WITH TIME ZONE,
    scrape_success BOOLEAN DEFAULT TRUE,
    scrape_error_message TEXT,
    scrape_attempts_count INTEGER DEFAULT 0,
    
    -- Price validation
    price_validation_status VARCHAR(50) DEFAULT 'valid', -- 'valid', 'suspicious', 'invalid'
    price_validation_reason TEXT,
    
    -- Status and timestamps
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT uq_listing_variant_retailer UNIQUE(product_variant_id, retailer_id)
);

-- Price history table (record all price changes with datetime)
CREATE TABLE price_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_listing_id UUID NOT NULL REFERENCES product_listings(id) ON DELETE CASCADE,
    
    -- Price information
    price DECIMAL(10,2) NOT NULL,
    previous_price DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'INR',
    
    -- Change metadata
    price_change_amount DECIMAL(10,2), -- calculated: price - previous_price
    price_change_percent DECIMAL(5,2), -- calculated percentage change
    
    -- Timestamps
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    effective_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Source of price change
    source VARCHAR(50) DEFAULT 'scraper', -- 'scraper', 'manual', 'api'
    confidence_score DECIMAL(3,2) DEFAULT 1.0 -- 0.0 to 1.0
);

-- User-driven product discovery queue
CREATE TABLE product_discovery_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Search information
    search_query VARCHAR(255) NOT NULL,
    brand_name VARCHAR(100),
    category_hint VARCHAR(100),
    
    -- Target retailers
    target_retailers UUID[], -- array of retailer IDs
    
    -- Discovery results
    products_found INTEGER DEFAULT 0,
    discovery_completed BOOLEAN DEFAULT FALSE,
    
    -- Status and priority
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    priority INTEGER DEFAULT 5, -- 1-10, higher numbers = higher priority
    
    -- Timestamps
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_processing_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Results
    error_message TEXT,
    discovered_products JSONB -- store found product information
);

-- Scraping queue (aggregated across all users)
CREATE TABLE scraping_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_listing_id UUID NOT NULL REFERENCES product_listings(id),
    
    -- Queue metadata
    priority INTEGER DEFAULT 5, -- 1-10, higher = more urgent
    source VARCHAR(50) DEFAULT 'scheduled', -- 'scheduled', 'user_request', 'discovery', 'retry'
    
    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    category_id UUID REFERENCES categories(id), -- for category-specific intervals
    
    -- Processing status
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed', 'skipped'
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_processing_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Results
    success BOOLEAN,
    error_message TEXT,
    response_time_ms INTEGER
);

-- Category-specific scraping intervals
CREATE TABLE category_scraping_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) UNIQUE,
    
    -- Interval configuration
    default_interval_hours INTEGER DEFAULT 24,
    sale_period_interval_hours INTEGER DEFAULT 6,
    high_demand_interval_hours INTEGER DEFAULT 12,
    
    -- Thresholds
    price_change_threshold_percent DECIMAL(5,2) DEFAULT 10.0,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User price alert thresholds (configurable per user)
CREATE TABLE user_alert_thresholds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
    
    -- Threshold configuration
    price_drop_percentage DECIMAL(5,2), -- alert when price drops by X%
    price_drop_absolute DECIMAL(10,2), -- alert when price drops by ₹X
    target_price DECIMAL(10,2), -- alert when price reaches ₹X
    
    -- Scope (NULL product_variant_id = global threshold for user)
    applies_to_all_products BOOLEAN DEFAULT FALSE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT uq_user_threshold_product UNIQUE(user_id, product_variant_id)
);

-- Price validation configuration
CREATE TABLE price_validation_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES categories(id),
    
    -- Validation rules (configurable)
    min_price_multiplier DECIMAL(3,2) DEFAULT 0.1, -- reject prices < 0.1x average
    max_price_multiplier DECIMAL(3,2) DEFAULT 10.0, -- reject prices > 10x average
    
    -- Price per gram validation
    min_price_per_gram DECIMAL(6,2),
    max_price_per_gram DECIMAL(6,2),
    
    -- Temporal validation
    max_price_change_percent_daily DECIMAL(5,2) DEFAULT 50.0,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_brands_slug ON brands(slug);
CREATE INDEX idx_brands_active ON brands(is_active);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_slug ON categories(slug);
CREATE INDEX idx_categories_active ON categories(is_active);

CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_truthified ON products(truthified_channel_testing);

CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_variants_active ON product_variants(is_active);
CREATE INDEX idx_variants_size_normalized ON product_variants(size_normalized_grams);

CREATE INDEX idx_retailers_slug ON retailers(slug);
CREATE INDEX idx_retailers_active ON retailers(is_active);

CREATE INDEX idx_listings_variant ON product_listings(product_variant_id);
CREATE INDEX idx_listings_retailer ON product_listings(retailer_id);
CREATE INDEX idx_listings_price ON product_listings(current_price);
CREATE INDEX idx_listings_available ON product_listings(is_available);
CREATE INDEX idx_listings_last_scraped ON product_listings(last_scraped_at);
CREATE INDEX idx_listings_active ON product_listings(is_active);

CREATE INDEX idx_price_history_listing ON price_history(product_listing_id);
CREATE INDEX idx_price_history_recorded ON price_history(recorded_at);
CREATE INDEX idx_price_history_price ON price_history(price);

CREATE INDEX idx_discovery_queue_status ON product_discovery_queue(status);
CREATE INDEX idx_discovery_queue_priority ON product_discovery_queue(priority DESC);
CREATE INDEX idx_discovery_queue_requested ON product_discovery_queue(requested_at);

CREATE INDEX idx_scraping_queue_status ON scraping_queue(status);
CREATE INDEX idx_scraping_queue_scheduled ON scraping_queue(scheduled_for);
CREATE INDEX idx_scraping_queue_priority ON scraping_queue(priority DESC, scheduled_for);
CREATE INDEX idx_scraping_queue_category ON scraping_queue(category_id);

CREATE INDEX idx_alert_thresholds_user ON user_alert_thresholds(user_id);
CREATE INDEX idx_alert_thresholds_product ON user_alert_thresholds(product_variant_id);
CREATE INDEX idx_alert_thresholds_active ON user_alert_thresholds(is_active);

-- Insert initial brands
INSERT INTO brands (name, slug, country_origin, is_active) VALUES
('Optimum Nutrition', 'optimum-nutrition', 'USA', true),
('MuscleBlaze', 'muscleblaze', 'India', true),
('Dymatize', 'dymatize', 'USA', true),
('BSN', 'bsn', 'USA', true),
('The Whole Truth', 'the-whole-truth', 'India', true);

-- Insert initial categories
INSERT INTO categories (name, slug, description, sort_order) VALUES
('Protein Supplements', 'protein-supplements', 'All protein supplement products', 1),
('Whey Protein', 'whey-protein', 'Whey protein powders and supplements', 2),
('Whey Isolate', 'whey-isolate', 'Whey protein isolate products', 3),
('Whey Concentrate', 'whey-concentrate', 'Whey protein concentrate products', 4),
('Casein Protein', 'casein-protein', 'Casein protein supplements', 5),
('Plant Protein', 'plant-protein', 'Plant-based protein supplements', 6);

-- Insert initial retailers
INSERT INTO retailers (name, slug, website_url, requests_per_minute, requests_per_hour, is_active) VALUES
('Amazon', 'amazon', 'https://www.amazon.in', 15, 600, true),
('Flipkart', 'flipkart', 'https://www.flipkart.com', 12, 500, true),
('HealthKart', 'healthkart', 'https://www.healthkart.com', 10, 400, true),
('Nutrabay', 'nutrabay', 'https://www.nutrabay.com', 8, 300, true);

-- Create updated_at triggers
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_variants_updated_at BEFORE UPDATE ON product_variants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_retailers_updated_at BEFORE UPDATE ON retailers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_listings_updated_at BEFORE UPDATE ON product_listings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_category_config_updated_at BEFORE UPDATE ON category_scraping_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_alert_thresholds_updated_at BEFORE UPDATE ON user_alert_thresholds FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_validation_config_updated_at BEFORE UPDATE ON price_validation_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comments for documentation
COMMENT ON TABLE brands IS 'Product brands including The Whole Truth';
COMMENT ON TABLE categories IS 'Hierarchical product categories';
COMMENT ON TABLE products IS 'Base products with nutritional information and truthified testing field';
COMMENT ON TABLE product_variants IS 'Product variants by flavor and size';
COMMENT ON TABLE retailers IS 'Retailers with configurable scraping parameters';
COMMENT ON TABLE product_listings IS 'Product availability at specific retailers';
COMMENT ON TABLE price_history IS 'Complete price change history with datetime tracking';
COMMENT ON TABLE product_discovery_queue IS 'User-driven product discovery requests';
COMMENT ON TABLE scraping_queue IS 'Aggregated scraping queue with configurable intervals';
COMMENT ON TABLE category_scraping_config IS 'Category-specific scraping intervals';
COMMENT ON TABLE user_alert_thresholds IS 'User-configurable price alert thresholds';
COMMENT ON TABLE price_validation_config IS 'Configurable price validation rules';