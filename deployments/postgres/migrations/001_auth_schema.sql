-- Authentication and User Management Schema
-- Migration: 001_auth_schema.sql
-- Created: 2024-01-15
-- Description: Initial authentication system with GDPR compliance

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table with encrypted PII
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Email handling (encrypted for privacy, hashed for indexing)
    email_hash VARCHAR(64) UNIQUE NOT NULL, -- SHA-256 hash for indexing
    email_encrypted BYTEA NOT NULL,         -- AES-256 encrypted email
    
    -- Personal information (encrypted)
    name_encrypted BYTEA,                   -- AES-256 encrypted name
    avatar_url VARCHAR(255),                -- Public avatar URL
    
    -- Account status
    email_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    -- GDPR compliance
    gdpr_consent_at TIMESTAMP WITH TIME ZONE,
    gdpr_consent_version VARCHAR(10) DEFAULT '1.0',
    data_retention_until TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 years'),
    
    -- Marketing preferences
    consent_marketing BOOLEAN DEFAULT FALSE,
    consent_analytics BOOLEAN DEFAULT FALSE,
    
    -- Audit fields
    created_by UUID,
    updated_by UUID
);

-- Indexes for users table
CREATE INDEX idx_users_email_hash ON users(email_hash);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_login ON users(last_login_at);
CREATE INDEX idx_users_active ON users(is_active);
CREATE INDEX idx_users_data_retention ON users(data_retention_until);

-- OAuth providers table
CREATE TABLE user_oauth_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Provider information
    provider VARCHAR(50) NOT NULL, -- 'google', 'github', 'facebook'
    provider_user_id VARCHAR(255) NOT NULL,
    provider_email VARCHAR(255),
    
    -- Encrypted tokens
    access_token_encrypted BYTEA,
    refresh_token_encrypted BYTEA,
    
    -- Token metadata
    expires_at TIMESTAMP WITH TIME ZONE,
    scope TEXT,
    
    -- Timestamps  
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT uq_oauth_provider_user UNIQUE(provider, provider_user_id)
);

-- Indexes for OAuth providers
CREATE INDEX idx_oauth_user_id ON user_oauth_providers(user_id);
CREATE INDEX idx_oauth_provider ON user_oauth_providers(provider);
CREATE INDEX idx_oauth_last_used ON user_oauth_providers(last_used_at);

-- User roles table
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Role information
    role VARCHAR(50) NOT NULL, -- 'user', 'premium', 'admin', 'super_admin'
    
    -- Grant information
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID REFERENCES users(id),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Constraints
    CONSTRAINT uq_user_role UNIQUE(user_id, role)
);

-- Indexes for user roles
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);
CREATE INDEX idx_user_roles_active ON user_roles(is_active);

-- API keys table for B2B access
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Key information (encrypted)
    key_hash VARCHAR(64) UNIQUE NOT NULL, -- SHA-256 hash for lookup
    key_encrypted BYTEA NOT NULL,         -- AES-256 encrypted key
    
    -- Metadata
    name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Tier and limits
    tier VARCHAR(50) NOT NULL DEFAULT 'free', -- 'free', 'developer', 'enterprise'
    rate_limit_per_hour INTEGER NOT NULL DEFAULT 1000,
    
    -- Usage tracking
    total_requests_made BIGINT DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- IP restrictions (optional)
    allowed_ips INET[],
    
    -- Audit
    created_by UUID REFERENCES users(id)
);

-- Indexes for API keys
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_tier ON api_keys(tier);
CREATE INDEX idx_api_keys_active ON api_keys(is_active);
CREATE INDEX idx_api_keys_expires ON api_keys(expires_at);

-- Password table (for email/password authentication)
CREATE TABLE user_passwords (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Password hash (Argon2id)
    password_hash TEXT NOT NULL,
    salt BYTEA NOT NULL,
    
    -- Password metadata
    algorithm VARCHAR(50) DEFAULT 'argon2id',
    iterations INTEGER DEFAULT 3,
    memory_kb INTEGER DEFAULT 65536, -- 64MB
    parallelism INTEGER DEFAULT 4,
    
    -- Security
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    must_change BOOLEAN DEFAULT FALSE,
    
    -- Password history (prevent reuse)
    previous_hashes TEXT[],
    
    -- Reset tokens
    reset_token_hash VARCHAR(64),
    reset_token_expires_at TIMESTAMP WITH TIME ZONE,
    reset_attempts INTEGER DEFAULT 0,
    
    -- Constraints
    CONSTRAINT uq_user_password UNIQUE(user_id)
);

-- Indexes for passwords
CREATE INDEX idx_user_passwords_user_id ON user_passwords(user_id);
CREATE INDEX idx_user_passwords_reset_token ON user_passwords(reset_token_hash);
CREATE INDEX idx_user_passwords_reset_expires ON user_passwords(reset_token_expires_at);

-- Email verification tokens
CREATE TABLE email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Token information
    token_hash VARCHAR(64) NOT NULL,
    email_to_verify TEXT NOT NULL, -- The email being verified
    
    -- Expiration and usage
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    attempts INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for email verification
CREATE INDEX idx_email_verification_token ON email_verification_tokens(token_hash);
CREATE INDEX idx_email_verification_user ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_expires ON email_verification_tokens(expires_at);

-- Price alerts table
CREATE TABLE price_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Alert configuration
    product_id VARCHAR(255) NOT NULL,
    target_price DECIMAL(10,2) NOT NULL,
    retailer_ids TEXT[], -- Array of retailer IDs or NULL for all
    
    -- Notification preferences
    notification_methods TEXT[] DEFAULT ARRAY['email'], -- 'email', 'push', 'sms'
    notification_frequency VARCHAR(50) DEFAULT 'immediate', -- 'immediate', 'daily', 'weekly'
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    trigger_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for price alerts
CREATE INDEX idx_alerts_user_id ON price_alerts(user_id);
CREATE INDEX idx_alerts_product_id ON price_alerts(product_id);
CREATE INDEX idx_alerts_active ON price_alerts(is_active);
CREATE INDEX idx_alerts_target_price ON price_alerts(target_price);

-- User favorites table
CREATE TABLE user_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id VARCHAR(255) NOT NULL,
    
    -- Metadata
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    category VARCHAR(100), -- For future categorization
    notes TEXT, -- User notes about the product
    
    -- Constraints
    CONSTRAINT uq_user_favorite UNIQUE(user_id, product_id)
);

-- Indexes for favorites
CREATE INDEX idx_favorites_user_id ON user_favorites(user_id);
CREATE INDEX idx_favorites_product_id ON user_favorites(product_id);
CREATE INDEX idx_favorites_added_at ON user_favorites(added_at);

-- User search history (anonymized for analytics)
CREATE TABLE user_search_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Anonymized identifiers
    user_hash VARCHAR(64) NOT NULL,      -- Anonymized user identifier
    session_id VARCHAR(255),             -- Session tracking
    
    -- Search information (hashed for privacy)
    search_query_hash VARCHAR(64),       -- Hashed search terms
    search_query_encrypted BYTEA,        -- Encrypted for user's own history
    category VARCHAR(100),
    filters_applied JSONB,               -- Applied filters
    
    -- Results and interaction
    results_count INTEGER,
    clicked_products TEXT[],             -- Product IDs clicked
    
    -- Timestamps
    searched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Data retention (shorter for search history)
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '90 days')
);

-- Indexes for search history
CREATE INDEX idx_search_history_user_hash ON user_search_history(user_hash);
CREATE INDEX idx_search_history_timestamp ON user_search_history(searched_at);
CREATE INDEX idx_search_history_expires ON user_search_history(expires_at);
CREATE INDEX idx_search_history_category ON user_search_history(category);

-- User preferences table
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Display preferences
    currency VARCHAR(10) DEFAULT 'INR',
    language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
    
    -- Notification preferences
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT FALSE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    
    -- Privacy preferences
    profile_public BOOLEAN DEFAULT FALSE,
    search_history_enabled BOOLEAN DEFAULT TRUE,
    recommendations_enabled BOOLEAN DEFAULT TRUE,
    
    -- Feature preferences
    favorite_categories TEXT[],
    preferred_retailers TEXT[],
    price_range_min DECIMAL(10,2),
    price_range_max DECIMAL(10,2),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT uq_user_preferences UNIQUE(user_id)
);

-- Index for user preferences
CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);

-- GDPR data processing requests
CREATE TABLE gdpr_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Request information
    request_type VARCHAR(50) NOT NULL,   -- 'export', 'delete', 'rectify', 'restrict'
    description TEXT,
    
    -- Status tracking
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    
    -- Processing information
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_processing_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Data export information
    data_export_url VARCHAR(500),
    data_export_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Processing details
    processed_by UUID REFERENCES users(id),
    processing_notes TEXT,
    
    -- Legal basis
    legal_basis TEXT,
    retention_period_days INTEGER
);

-- Indexes for GDPR requests
CREATE INDEX idx_gdpr_requests_user_id ON gdpr_requests(user_id);
CREATE INDEX idx_gdpr_requests_status ON gdpr_requests(status);
CREATE INDEX idx_gdpr_requests_type ON gdpr_requests(request_type);
CREATE INDEX idx_gdpr_requests_requested_at ON gdpr_requests(requested_at);

-- Audit log table for security and compliance
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Subject information
    user_id UUID REFERENCES users(id),
    session_id VARCHAR(255),
    
    -- Action information
    action VARCHAR(100) NOT NULL,       -- 'login', 'logout', 'create_alert', etc.
    resource_type VARCHAR(50),          -- 'user', 'alert', 'favorite', etc.
    resource_id VARCHAR(255),
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    
    -- Request information
    http_method VARCHAR(10),
    endpoint VARCHAR(255),
    request_id VARCHAR(255),
    
    -- Result
    success BOOLEAN NOT NULL,
    error_message TEXT,
    
    -- Additional data
    metadata JSONB,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for audit logs
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_ip ON audit_logs(ip_address);

-- User sessions table (for tracking active sessions)
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Session information
    session_token_hash VARCHAR(64) UNIQUE NOT NULL,
    refresh_token_hash VARCHAR(64) UNIQUE NOT NULL,
    
    -- Client information
    ip_address INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(255),
    
    -- Geographic information
    country_code VARCHAR(2),
    city VARCHAR(100),
    
    -- Session lifecycle
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    revoked_at TIMESTAMP WITH TIME ZONE,
    revoked_reason TEXT
);

-- Indexes for user sessions
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token_hash);
CREATE INDEX idx_user_sessions_refresh_token ON user_sessions(refresh_token_hash);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active);

-- Rate limiting table (for API usage tracking)
CREATE TABLE rate_limit_buckets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Identifier (can be user_id, ip_address, api_key_hash, etc.)
    identifier_type VARCHAR(50) NOT NULL, -- 'user', 'ip', 'api_key'
    identifier_value VARCHAR(255) NOT NULL,
    
    -- Rate limiting information
    endpoint_pattern VARCHAR(255),        -- '/api/products/*' or 'global'
    requests_count INTEGER DEFAULT 0,
    requests_limit INTEGER NOT NULL,
    
    -- Time window
    window_start TIMESTAMP WITH TIME ZONE NOT NULL,
    window_duration INTERVAL NOT NULL,   -- '1 hour', '1 day', etc.
    
    -- Status
    is_blocked BOOLEAN DEFAULT FALSE,
    blocked_until TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT uq_rate_limit_bucket UNIQUE(identifier_type, identifier_value, endpoint_pattern, window_start)
);

-- Indexes for rate limiting
CREATE INDEX idx_rate_limit_identifier ON rate_limit_buckets(identifier_type, identifier_value);
CREATE INDEX idx_rate_limit_window ON rate_limit_buckets(window_start);
CREATE INDEX idx_rate_limit_blocked ON rate_limit_buckets(is_blocked);
CREATE INDEX idx_rate_limit_updated ON rate_limit_buckets(updated_at);

-- Notification queue table
CREATE TABLE notification_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Notification information
    type VARCHAR(50) NOT NULL,           -- 'price_alert', 'welcome', 'security'
    channel VARCHAR(50) NOT NULL,       -- 'email', 'push', 'sms'
    
    -- Message content
    subject VARCHAR(255),
    message TEXT NOT NULL,
    
    -- Metadata
    metadata JSONB,
    template_id VARCHAR(100),
    
    -- Status
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'sent', 'failed', 'cancelled'
    
    -- Scheduling
    scheduled_for TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    
    -- Delivery information
    delivery_attempts INTEGER DEFAULT 0,
    last_attempt_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for notification queue
CREATE INDEX idx_notification_queue_user_id ON notification_queue(user_id);
CREATE INDEX idx_notification_queue_status ON notification_queue(status);
CREATE INDEX idx_notification_queue_scheduled ON notification_queue(scheduled_for);
CREATE INDEX idx_notification_queue_type ON notification_queue(type);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_oauth_providers_updated_at BEFORE UPDATE ON user_oauth_providers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_price_alerts_updated_at BEFORE UPDATE ON price_alerts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rate_limit_buckets_updated_at BEFORE UPDATE ON rate_limit_buckets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to automatically clean expired data
CREATE OR REPLACE FUNCTION cleanup_expired_data()
RETURNS void AS $$
BEGIN
    -- Clean expired search history
    DELETE FROM user_search_history WHERE expires_at < NOW();
    
    -- Clean expired email verification tokens
    DELETE FROM email_verification_tokens WHERE expires_at < NOW() AND used_at IS NULL;
    
    -- Clean expired user sessions
    DELETE FROM user_sessions WHERE expires_at < NOW() OR (revoked_at IS NOT NULL AND revoked_at < NOW() - INTERVAL '7 days');
    
    -- Clean old rate limit buckets
    DELETE FROM rate_limit_buckets WHERE window_start < NOW() - INTERVAL '7 days';
    
    -- Clean old audit logs (keep for 1 year)
    DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '1 year';
    
    -- Clean sent notifications (keep for 30 days)
    DELETE FROM notification_queue WHERE status = 'sent' AND sent_at < NOW() - INTERVAL '30 days';
    
    -- Clean expired GDPR data exports
    UPDATE gdpr_requests SET data_export_url = NULL WHERE data_export_expires_at < NOW() AND data_export_url IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Create indexes for performance optimization
CREATE INDEX CONCURRENTLY idx_users_gdpr_retention ON users(data_retention_until) WHERE data_retention_until < NOW() + INTERVAL '30 days';
CREATE INDEX CONCURRENTLY idx_audit_logs_performance ON audit_logs(created_at, user_id) WHERE created_at > NOW() - INTERVAL '90 days';

-- Insert default admin user (to be updated with proper credentials)
INSERT INTO users (
    email_hash,
    email_encrypted,
    name_encrypted,
    email_verified,
    is_active,
    gdpr_consent_at,
    consent_marketing,
    consent_analytics
) VALUES (
    encode(sha256('admin@proteinprices.com'::bytea), 'hex'),
    'encrypted_admin_email', -- This should be properly encrypted in the application
    'encrypted_admin_name',  -- This should be properly encrypted in the application
    true,
    true,
    NOW(),
    false,
    true
);

-- Insert admin role for the default admin user
INSERT INTO user_roles (user_id, role)
SELECT id, 'super_admin'
FROM users 
WHERE email_hash = encode(sha256('admin@proteinprices.com'::bytea), 'hex');

-- Create default user preferences for admin
INSERT INTO user_preferences (user_id)
SELECT id FROM users WHERE email_hash = encode(sha256('admin@proteinprices.com'::bytea), 'hex');

-- Comments for documentation
COMMENT ON TABLE users IS 'User accounts with encrypted PII and GDPR compliance';
COMMENT ON TABLE user_oauth_providers IS 'OAuth provider connections for social login';
COMMENT ON TABLE user_roles IS 'Role-based access control for users';
COMMENT ON TABLE api_keys IS 'API keys for B2B access with rate limiting';
COMMENT ON TABLE user_passwords IS 'Password authentication with Argon2id hashing';
COMMENT ON TABLE price_alerts IS 'User-configured price alerts for products';
COMMENT ON TABLE user_favorites IS 'User favorite products';
COMMENT ON TABLE user_search_history IS 'Anonymized search history for analytics';
COMMENT ON TABLE gdpr_requests IS 'GDPR data processing requests tracking';
COMMENT ON TABLE audit_logs IS 'Security and compliance audit trail';
COMMENT ON TABLE rate_limit_buckets IS 'API rate limiting tracking';
COMMENT ON TABLE notification_queue IS 'Notification delivery queue';

-- Grant permissions for application user
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO proteinprices_app;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO proteinprices_app;