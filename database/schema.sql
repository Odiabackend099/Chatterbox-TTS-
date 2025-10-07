-- CallWaiting TTS Production Database Schema
-- PostgreSQL 14+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- API Keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    key_prefix TEXT NOT NULL UNIQUE,              -- e.g., cw_live_
    key_hash TEXT NOT NULL,                        -- scrypt hash
    tenant_id UUID,
    scopes TEXT[] DEFAULT '{tts:write,voices:read}',
    rate_limit_per_min INT DEFAULT 120,
    rate_limit_per_day INT DEFAULT 10000,
    status TEXT NOT NULL DEFAULT 'active',         -- active|revoked|suspended
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    allowed_origins TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}'::JSONB,
    created_by TEXT,

    CONSTRAINT valid_status CHECK (status IN ('active', 'revoked', 'suspended'))
);

CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_status ON api_keys(status);
CREATE INDEX idx_api_keys_tenant ON api_keys(tenant_id);

-- Voices catalog (public + tenant-private)
CREATE TABLE IF NOT EXISTS voices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT UNIQUE NOT NULL,                     -- e.g., "naomi-en"
    display_name TEXT NOT NULL,
    description TEXT,
    language TEXT NOT NULL,                        -- BCP-47 e.g., en-US
    gender TEXT,                                   -- male|female|neutral
    sample_url TEXT,
    audio_file_path TEXT,                          -- local reference audio
    params JSONB DEFAULT '{}'::JSONB,              -- model settings
    owner_tenant UUID,                             -- null => public
    is_public BOOLEAN DEFAULT FALSE,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_gender CHECK (gender IN ('male', 'female', 'neutral', NULL))
);

CREATE INDEX idx_voices_slug ON voices(slug);
CREATE INDEX idx_voices_language ON voices(language);
CREATE INDEX idx_voices_public ON voices(is_public) WHERE is_public = TRUE;
CREATE INDEX idx_voices_owner ON voices(owner_tenant);

-- Usage metering (per key / per day)
CREATE TABLE IF NOT EXISTS usage_counters (
    day DATE NOT NULL,
    api_key_id UUID REFERENCES api_keys(id) ON DELETE CASCADE,
    requests INT DEFAULT 0,
    chars INT DEFAULT 0,
    ms_synth INT DEFAULT 0,
    errors INT DEFAULT 0,
    PRIMARY KEY (day, api_key_id)
);

CREATE INDEX idx_usage_day ON usage_counters(day DESC);
CREATE INDEX idx_usage_key ON usage_counters(api_key_id);

-- Request logs (for audit & debugging)
CREATE TABLE IF NOT EXISTS request_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id TEXT NOT NULL,
    api_key_id UUID REFERENCES api_keys(id) ON DELETE SET NULL,
    endpoint TEXT NOT NULL,
    method TEXT NOT NULL,
    status_code INT,
    voice_id UUID REFERENCES voices(id) ON DELETE SET NULL,
    text_length INT,
    duration_ms INT,
    error_message TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_request_logs_created ON request_logs(created_at DESC);
CREATE INDEX idx_request_logs_api_key ON request_logs(api_key_id);
CREATE INDEX idx_request_logs_request_id ON request_logs(request_id);

-- Consent records for voice cloning
CREATE TABLE IF NOT EXISTS voice_consent (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    voice_id UUID REFERENCES voices(id) ON DELETE CASCADE,
    consent_type TEXT NOT NULL,                    -- upload|clone|commercial
    consenter_name TEXT,
    consenter_email TEXT,
    consent_document_url TEXT,
    ip_address INET,
    user_agent TEXT,
    granted_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX idx_voice_consent_voice ON voice_consent(voice_id);
CREATE INDEX idx_voice_consent_granted ON voice_consent(granted_at DESC);

-- Tenants table
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    plan TEXT DEFAULT 'free',                      -- free|starter|pro|enterprise
    status TEXT DEFAULT 'active',
    max_keys INT DEFAULT 5,
    max_voices INT DEFAULT 10,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX idx_tenants_slug ON tenants(slug);

-- Add foreign key to api_keys
ALTER TABLE api_keys
ADD CONSTRAINT fk_api_keys_tenant
FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

-- Add foreign key to voices
ALTER TABLE voices
ADD CONSTRAINT fk_voices_tenant
FOREIGN KEY (owner_tenant) REFERENCES tenants(id) ON DELETE CASCADE;

-- Functions for updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_voices_updated_at BEFORE UPDATE ON voices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample data: Default tenant
INSERT INTO tenants (id, name, slug, plan, status)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Default',
    'default',
    'free',
    'active'
) ON CONFLICT (id) DO NOTHING;

-- Sample voices (English)
INSERT INTO voices (slug, display_name, description, language, gender, is_public, params)
VALUES
(
    'emily-en-us',
    'Emily',
    'Natural American English female voice',
    'en-US',
    'female',
    TRUE,
    '{"temperature": 0.8, "exaggeration": 1.3, "cfg_weight": 0.5}'::JSONB
),
(
    'james-en-us',
    'James',
    'Professional American English male voice',
    'en-US',
    'male',
    TRUE,
    '{"temperature": 0.8, "exaggeration": 1.0, "cfg_weight": 0.5}'::JSONB
),
(
    'sophia-en-gb',
    'Sophia',
    'British English female voice',
    'en-GB',
    'female',
    TRUE,
    '{"temperature": 0.8, "exaggeration": 1.2, "cfg_weight": 0.5}'::JSONB
)
ON CONFLICT (slug) DO NOTHING;

-- Views for reporting
CREATE OR REPLACE VIEW usage_summary AS
SELECT
    ak.name AS api_key_name,
    ak.tenant_id,
    uc.day,
    uc.requests,
    uc.chars,
    uc.ms_synth,
    uc.errors,
    ROUND(uc.ms_synth::NUMERIC / NULLIF(uc.requests, 0), 2) AS avg_latency_ms
FROM usage_counters uc
JOIN api_keys ak ON uc.api_key_id = ak.id
ORDER BY uc.day DESC, uc.requests DESC;

-- Grant permissions (adjust for your user)
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO chatterbox_user;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO chatterbox_user;
