# Quick Reference Card - CallWaiting TTS API

## 🔥 Common Commands

### Start/Stop Services
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart TTS server
docker-compose restart chatterbox-tts

# View logs
docker-compose logs -f chatterbox-tts
```

### API Key Management
```bash
# Generate 1 new key
python3 scripts/generate_api_keys.py

# Generate 5 keys with SQL
python3 scripts/generate_api_keys.py -n 5 --sql

# Insert keys into database
python3 scripts/generate_api_keys.py -n 5 --sql | \
  docker exec -i chatterbox-postgres psql -U postgres -d chatterbox

# List active keys
docker exec -it chatterbox-postgres psql -U postgres -d chatterbox \
  -c "SELECT name, key_prefix, status, rate_limit_per_min FROM api_keys;"
```

### Health Checks
```bash
# Basic health
curl http://localhost:8004/health

# With SSL
curl https://tts.odia.dev/health

# Check specific components
curl http://localhost:8004/health | jq '.components'
```

### Testing Endpoints
```bash
# List voices
curl http://localhost:8004/v1/voices \
  -H "x-api-key: YOUR_KEY"

# Generate TTS (get voice ID from catalog first)
curl -X POST http://localhost:8004/v1/tts \
  -H "x-api-key: YOUR_KEY" \
  -H "content-type: application/json" \
  -d '{"text":"Test message","voice_id":"VOICE_UUID","format":"wav"}' \
  -o test.wav

# Check usage
curl http://localhost:8004/v1/usage \
  -H "x-api-key: YOUR_KEY"

# Verify auth
curl http://localhost:8004/v1/auth/verify \
  -H "x-api-key: YOUR_KEY"
```

### Database Operations
```bash
# Connect to database
docker exec -it chatterbox-postgres psql -U postgres -d chatterbox

# Backup database
docker exec chatterbox-postgres pg_dump -U postgres chatterbox > backup_$(date +%Y%m%d).sql

# Restore database
cat backup.sql | docker exec -i chatterbox-postgres psql -U postgres -d chatterbox

# View usage stats
docker exec -it chatterbox-postgres psql -U postgres -d chatterbox \
  -c "SELECT * FROM usage_summary ORDER BY day DESC LIMIT 10;"
```

### Redis Operations
```bash
# Check Redis connection
docker exec -it chatterbox-redis redis-cli PING

# View all rate limit keys
docker exec -it chatterbox-redis redis-cli KEYS "rl:*"

# Clear rate limits (for testing)
docker exec -it chatterbox-redis redis-cli FLUSHDB

# Check memory usage
docker exec -it chatterbox-redis redis-cli INFO memory
```

### Monitoring
```bash
# View Prometheus metrics
curl http://localhost:8004/metrics

# Filter TTS metrics
curl http://localhost:8004/metrics | grep tts_

# Check system resources
docker stats

# View detailed health
curl http://localhost:8004/health/detailed | jq
```

### SSL/NGINX
```bash
# Test NGINX config
sudo nginx -t

# Reload NGINX
sudo systemctl reload nginx

# Check SSL certificate
sudo certbot certificates

# Renew SSL
sudo certbot renew

# View NGINX logs
docker-compose logs nginx

# View access logs
docker-compose exec nginx tail -f /var/log/nginx/tts.odia.dev.access.log
```

### Debugging
```bash
# Check all service status
docker-compose ps

# View TTS server logs (last 100 lines)
docker-compose logs --tail=100 chatterbox-tts

# Follow logs in real-time
docker-compose logs -f

# Check PostgreSQL logs
docker-compose logs postgres | tail -50

# Check Redis logs
docker-compose logs redis | tail -50

# Inspect running container
docker exec -it chatterbox-tts-server bash

# Check disk space
df -h

# Check GPU usage
nvidia-smi
```

## 📊 SQL Queries

### View API Keys
```sql
SELECT name, key_prefix, status, rate_limit_per_min, created_at 
FROM api_keys 
ORDER BY created_at DESC;
```

### View Usage by Key
```sql
SELECT 
  ak.name,
  SUM(uc.requests) as total_requests,
  SUM(uc.chars) as total_chars,
  AVG(uc.ms_synth / NULLIF(uc.requests, 0)) as avg_latency_ms
FROM usage_counters uc
JOIN api_keys ak ON uc.api_key_id = ak.id
WHERE uc.day >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY ak.name
ORDER BY total_requests DESC;
```

### View Recent Requests
```sql
SELECT 
  created_at,
  endpoint,
  status_code,
  duration_ms,
  text_length,
  ip_address
FROM request_logs
ORDER BY created_at DESC
LIMIT 50;
```

### Revoke API Key
```sql
UPDATE api_keys 
SET status = 'revoked' 
WHERE key_prefix = 'cw_live_';
```

## 🔧 Environment Variables

### Required
```bash
POSTGRES_PASSWORD=your_secure_password
```

### Optional
```bash
CHATTERBOX_DEVICE=cuda          # cuda, mps, cpu
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
REDIS_HOST=localhost
REDIS_PORT=6379
ENVIRONMENT=production
```

## 🚨 Emergency Commands

### Restart Everything
```bash
docker-compose down
docker-compose up -d
```

### Clear All Rate Limits
```bash
docker exec -it chatterbox-redis redis-cli FLUSHDB
```

### Reset Database (DANGER!)
```bash
docker-compose down -v
docker-compose up -d postgres
# Wait for init, then start other services
```

### View Live Request Count
```bash
watch -n 1 'docker exec chatterbox-redis redis-cli DBSIZE'
```

## 📞 Quick Test Script

Save as `test_api.sh`:
```bash
#!/bin/bash
API_KEY="YOUR_API_KEY_HERE"
BASE_URL="http://localhost:8004"

# Get voices
echo "Fetching voices..."
VOICES=$(curl -s "${BASE_URL}/v1/voices" -H "x-api-key: ${API_KEY}")
echo "$VOICES" | jq -r '.[0]'

# Extract first voice ID
VOICE_ID=$(echo "$VOICES" | jq -r '.[0].id')
echo "Using voice: $VOICE_ID"

# Generate TTS
echo "Generating TTS..."
curl -X POST "${BASE_URL}/v1/tts" \
  -H "x-api-key: ${API_KEY}" \
  -H "content-type: application/json" \
  -d "{\"text\":\"Hello from CallWaiting AI\",\"voice_id\":\"${VOICE_ID}\",\"format\":\"wav\"}" \
  -o test_output.wav

echo "Audio saved to test_output.wav"
```

## 📱 Mobile Integration (Example)

### iOS (Swift)
```swift
func generateTTS(text: String, voiceId: String) async throws -> Data {
    let url = URL(string: "https://tts.odia.dev/v1/tts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("YOUR_API_KEY", forHTTPHeaderField: "x-api-key")
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    
    let body = ["text": text, "voice_id": voiceId, "format": "mp3"]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}
```

### Android (Kotlin)
```kotlin
suspend fun generateTTS(text: String, voiceId: String): ByteArray {
    val client = OkHttpClient()
    val json = """{"text":"$text","voice_id":"$voiceId","format":"mp3"}"""
    
    val request = Request.Builder()
        .url("https://tts.odia.dev/v1/tts")
        .addHeader("x-api-key", "YOUR_API_KEY")
        .post(json.toRequestBody("application/json".toMediaType()))
        .build()
    
    return client.newCall(request).execute().body?.bytes() ?: byteArrayOf()
}
```

---

**Version**: 1.0.0  
**Last Updated**: 2024-10-07

