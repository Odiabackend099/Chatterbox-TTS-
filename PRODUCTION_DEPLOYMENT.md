# Production Deployment Guide
## CallWaiting TTS API - Complete SaaS Setup

This guide walks you through deploying the CallWaiting TTS API as a production-ready SaaS service with API key authentication, rate limiting, and monitoring.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Database Setup](#database-setup)
4. [API Key Generation](#api-key-generation)
5. [Docker Deployment](#docker-deployment)
6. [NGINX & SSL Configuration](#nginx--ssl-configuration)
7. [DNS Configuration](#dns-configuration)
8. [Testing the API](#testing-the-api)
9. [Monitoring & Observability](#monitoring--observability)
10. [Scaling & Performance](#scaling--performance)
11. [Security Checklist](#security-checklist)
12. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

- **Docker** 24.0+ with Docker Compose
- **NVIDIA GPU** (optional, but recommended for performance)
- **Domain name** pointing to your server (e.g., `tts.odia.dev`)
- **SSL Certificate** (Let's Encrypt recommended)

### Required Accounts/Credentials

- Database credentials (PostgreSQL)
- Redis instance
- (Optional) Twilio account for phone integration
- (Optional) Anthropic/OpenAI API keys for LLM features

---

## Quick Start

### 1. Clone and Configure

```bash
# Clone repository
cd /path/to/chatterbox-twilio-integration

# Copy environment template
cp .env.example .env

# Edit with your credentials
nano .env
```

### 2. Set Environment Variables

Create `.env` file:

```bash
# Database Configuration
POSTGRES_DB=chatterbox
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE
POSTGRES_PORT=5432

# Redis Configuration
REDIS_PORT=6379

# Server Configuration
ENVIRONMENT=production
CHATTERBOX_PORT=8004

# Optional: Twilio Integration
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# Optional: LLM Integration
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
```

### 3. Start Services

```bash
# Start database and cache services
docker-compose up -d postgres redis

# Wait for services to be healthy (check with)
docker-compose ps

# Start TTS server
docker-compose up -d chatterbox-tts

# Check logs
docker-compose logs -f chatterbox-tts
```

---

## Database Setup

### Initialize Database

The database schema is automatically applied on first startup via the `schema.sql` file.

To manually apply or update:

```bash
# Connect to PostgreSQL
docker exec -it chatterbox-postgres psql -U postgres -d chatterbox

# Verify tables
\dt

# Check sample voices
SELECT slug, display_name, language FROM voices;

# Exit
\q
```

### Backup Database

```bash
# Backup
docker exec chatterbox-postgres pg_dump -U postgres chatterbox > backup_$(date +%Y%m%d).sql

# Restore
cat backup_20231025.sql | docker exec -i chatterbox-postgres psql -U postgres -d chatterbox
```

---

## API Key Generation

### Generate New Keys

```bash
# Generate 5 production keys
python3 scripts/generate_api_keys.py -n 5 --prefix "cw_live_" --name-prefix "Production Key"

# Generate SQL INSERT statements
python3 scripts/generate_api_keys.py -n 5 --sql > keys.sql

# Insert into database
cat keys.sql | docker exec -i chatterbox-postgres psql -U postgres -d chatterbox
```

### Example Output

```
Key 1:
  Full Key: cw_live_aK3oK7w2P7kzKp6M2kO1kN8bG6Q4mQ1iX9WmW9UXbV0
  Prefix:   cw_live_
  Hash:     scrypt$dGVzdHNhbHQxMjM0NTY=$...

⚠️  CRITICAL: Store these keys securely!
```

### Store Keys Securely

**AWS Secrets Manager:**
```bash
aws secretsmanager create-secret \
  --name callwaiting/api-keys/key1 \
  --secret-string "cw_live_aK3oK7w2P7kzKp6M2kO1kN8bG6Q4mQ1iX9WmW9UXbV0"
```

**Environment Variables:**
```bash
export API_KEY_1="cw_live_aK3oK7w2P7kzKp6M2kO1kN8bG6Q4mQ1iX9WmW9UXbV0"
```

---

## Docker Deployment

### Production Build

```bash
# Build with GPU support
docker-compose build --build-arg RUNTIME=nvidia

# Build with CPU only
docker-compose build --build-arg RUNTIME=cpu

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### Health Check

```bash
# Check service health
curl http://localhost:8004/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2024-10-07T12:00:00",
  "components": {
    "tts_model": true,
    "database": true,
    "redis": true
  }
}
```

---

## NGINX & SSL Configuration

### Install Certbot (Let's Encrypt)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Generate SSL certificate
sudo certbot certonly --standalone -d tts.odia.dev

# Verify certificate location
ls -la /etc/letsencrypt/live/tts.odia.dev/
```

### Configure NGINX

```bash
# Copy NGINX config
sudo cp nginx.conf /etc/nginx/sites-available/tts.odia.dev
sudo ln -s /etc/nginx/sites-available/tts.odia.dev /etc/nginx/sites-enabled/

# Test configuration
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx
```

### Docker-based NGINX (Alternative)

```bash
# Start with production profile
docker-compose --profile production up -d

# This starts:
# - nginx (reverse proxy with SSL)
# - certbot (automatic SSL renewal)
```

### SSL Certificate Renewal

```bash
# Manual renewal
sudo certbot renew

# Auto-renewal (crontab)
0 0 * * * certbot renew --quiet
```

---

## DNS Configuration

Point your domain to your server:

```
A Record:
  tts.odia.dev → YOUR_SERVER_IP

CNAME (optional):
  api.odia.dev → tts.odia.dev
  *.odia.dev → tts.odia.dev
```

**Cloudflare Setup:**
1. Add A record pointing to server IP
2. Enable "Proxied" status for DDoS protection
3. Set SSL/TLS mode to "Full (strict)"
4. Enable "Always Use HTTPS"

---

## Testing the API

### 1. Verify Health

```bash
curl https://tts.odia.dev/health
```

### 2. List Voices

```bash
curl https://tts.odia.dev/v1/voices \
  -H "x-api-key: YOUR_API_KEY_HERE"
```

### 3. Generate TTS (WAV)

```bash
curl -X POST https://tts.odia.dev/v1/tts \
  -H "x-api-key: YOUR_API_KEY_HERE" \
  -H "content-type: application/json" \
  -d '{
    "text": "Hello from CallWaiting AI",
    "voice_id": "VOICE_UUID_FROM_CATALOG",
    "format": "wav"
  }' \
  -o output.wav
```

### 4. Generate TTS (PCM16 for Telephony)

```bash
curl -X POST https://tts.odia.dev/v1/tts \
  -H "x-api-key: YOUR_API_KEY_HERE" \
  -H "content-type: application/json" \
  -d '{
    "text": "Welcome to our service",
    "voice_id": "VOICE_UUID",
    "format": "pcm16",
    "speed": 1.0
  }' \
  -o output.pcm
```

### 5. Check Usage

```bash
curl https://tts.odia.dev/v1/usage \
  -H "x-api-key: YOUR_API_KEY_HERE"
```

### 6. Verify Authentication

```bash
curl https://tts.odia.dev/v1/auth/verify \
  -H "x-api-key: YOUR_API_KEY_HERE"
```

---

## Monitoring & Observability

### Prometheus Metrics

Scrape endpoint at `/metrics`:

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'callwaiting-tts'
    static_configs:
      - targets: ['tts.odia.dev:8004']
    metrics_path: '/metrics'
    scheme: https
```

### Key Metrics to Monitor

- `http_requests_total` - Total requests
- `tts_generation_duration_seconds` - TTS latency (p50, p95, p99)
- `api_key_rate_limit_exceeded_total` - Rate limit violations
- `system_cpu_percent` - CPU usage
- `system_memory_percent` - Memory usage
- `tts_model_loaded` - Model status

### Grafana Dashboard

```bash
# Import dashboard JSON
curl https://grafana.com/api/dashboards/XXXXX/revisions/1/download
```

### Logging

```bash
# View application logs
docker-compose logs -f chatterbox-tts

# View NGINX access logs
docker-compose logs nginx | grep "POST /v1/tts"

# View PostgreSQL logs
docker-compose logs postgres

# Export logs for analysis
docker-compose logs --since 24h > logs_$(date +%Y%m%d).log
```

---

## Scaling & Performance

### Vertical Scaling

```yaml
# docker-compose.yml - increase resources
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
    reservations:
      cpus: '2'
      memory: 4G
```

### Horizontal Scaling

```bash
# Scale TTS workers
docker-compose up -d --scale chatterbox-tts=3

# Update NGINX upstream
upstream tts_backend {
    server chatterbox-tts-1:8004;
    server chatterbox-tts-2:8004;
    server chatterbox-tts-3:8004;
}
```

### Performance Tuning

**Database Connection Pool:**
```python
# In server.py startup
app.state.pg = await asyncpg.create_pool(
    min_size=5,
    max_size=20,  # Increase for high traffic
    command_timeout=60
)
```

**Redis Configuration:**
```bash
# Increase memory limit
redis-server --maxmemory 2gb --maxmemory-policy allkeys-lru
```

**NGINX Rate Limits:**
```nginx
# Adjust in nginx.conf
limit_req_zone $binary_remote_addr zone=tts_limit:10m rate=5r/s;  # Increase from 2r/s
```

---

## Security Checklist

### ✅ Must-Have Security Measures

- [ ] **SSL/TLS enabled** with A+ rating on SSL Labs
- [ ] **API keys stored securely** (never in code/logs)
- [ ] **Rate limiting enabled** per IP and per key
- [ ] **Database credentials** in environment variables only
- [ ] **CORS configured** with specific allowed origins
- [ ] **Security headers** enabled (HSTS, CSP, X-Frame-Options)
- [ ] **Database backups** automated daily
- [ ] **Firewall rules** restrict database/redis access
- [ ] **Monitoring alerts** for 5xx errors and p95 latency spikes
- [ ] **Log rotation** configured (max 10 files, 100MB each)

### Network Security

```bash
# Firewall rules (UFW example)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw deny 5432/tcp  # Block external PostgreSQL access
sudo ufw deny 6379/tcp  # Block external Redis access
sudo ufw enable
```

### Secrets Management

**AWS Secrets Manager:**
```python
import boto3
secrets = boto3.client('secretsmanager')
db_password = secrets.get_secret_value(SecretId='callwaiting/db/password')['SecretString']
```

**HashiCorp Vault:**
```bash
export VAULT_ADDR=https://vault.example.com
vault kv get -field=password secret/chatterbox/db
```

---

## Troubleshooting

### Database Connection Failed

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Test connection manually
docker exec -it chatterbox-postgres psql -U postgres -d chatterbox

# Check logs
docker-compose logs postgres
```

### Redis Connection Failed

```bash
# Test Redis
docker exec -it chatterbox-redis redis-cli ping

# Should return: PONG

# Check memory usage
docker exec -it chatterbox-redis redis-cli INFO memory
```

### TTS Model Not Loading

```bash
# Check VRAM/RAM availability
nvidia-smi  # For GPU

# Check HuggingFace cache
ls -lah model_cache/

# Force re-download
rm -rf model_cache/*
docker-compose restart chatterbox-tts
```

### Rate Limit Issues

```bash
# Check current rate limit counters
docker exec -it chatterbox-redis redis-cli KEYS "rl:*"

# Clear rate limits for testing
docker exec -it chatterbox-redis redis-cli FLUSHDB
```

### High Latency

```bash
# Check metrics
curl http://localhost:8004/metrics | grep tts_generation_duration

# Check system resources
docker stats

# Enable debug logging
docker-compose logs -f chatterbox-tts | grep "TTS generation"
```

### SSL Certificate Issues

```bash
# Test SSL
openssl s_client -connect tts.odia.dev:443 -servername tts.odia.dev

# Renew certificate
sudo certbot renew --force-renewal

# Check expiration
sudo certbot certificates
```

---

## Production Checklist

### Before Go-Live

- [ ] Generate and securely store 5+ API keys
- [ ] Configure SSL with valid certificate
- [ ] Set strong database password
- [ ] Configure CORS with specific allowed origins
- [ ] Set up automated backups (database + volumes)
- [ ] Configure monitoring (Prometheus + Grafana)
- [ ] Set up alerting (PagerDuty / Slack)
- [ ] Load test to 100+ RPS
- [ ] Document API usage for customers
- [ ] Set up log aggregation (ELK / Datadog)

### After Go-Live

- [ ] Monitor error rates and latency
- [ ] Track usage per API key
- [ ] Review access logs for abuse
- [ ] Check disk space and database size
- [ ] Test failover scenarios
- [ ] Update documentation
- [ ] Collect customer feedback

---

## Support & Resources

### Documentation

- **API Reference**: https://tts.odia.dev/docs
- **Health Check**: https://tts.odia.dev/health
- **Metrics**: http://localhost:8004/metrics

### Key Endpoints

- `GET /health` - Health status
- `GET /v1/voices` - List voices
- `POST /v1/tts` - Generate TTS
- `GET /v1/usage` - Usage statistics
- `GET /metrics` - Prometheus metrics

### Contact

For production issues, contact your infrastructure team or file an issue in the repository.

---

**Version**: 1.0.0  
**Last Updated**: 2024-10-07

