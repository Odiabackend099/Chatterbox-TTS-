# RunPod Deployment Fix Guide

## Current Issue

Your RunPod instance is returning `404` on all endpoints:
- ✅ RunPod proxy is working
- ✅ SSL/TLS is configured
- ❌ FastAPI server isn't responding

**Why:** The production server requires PostgreSQL + Redis, but RunPod doesn't have these running by default.

---

## Solution 1: Deploy Simple Version (Fastest)

This version works without database dependencies - just pure TTS.

### Step 1: Check Your Current Pod

1. Go to [RunPod Dashboard](https://www.runpod.io/console/pods)
2. Find your pod: `ekq3uygf1706p4`
3. Click **"Connect"** → **"Start Web Terminal"**

### Step 2: Check Logs

In the web terminal:

```bash
# Check if server is running
ps aux | grep python

# Check logs
tail -100 /app/logs/server.log

# Or check Docker logs if using Docker
docker logs $(docker ps -q)
```

**Look for errors like:**
- `Failed to initialize database pool`
- `Redis connection error`
- `TTS model not loaded`
- `Port already in use`

### Step 3: Stop Current Server

```bash
# Kill any running Python process
pkill -9 python3

# Or stop Docker
docker stop $(docker ps -q)
```

### Step 4: Start Simple Server

```bash
# Navigate to your code
cd /workspace/chatterbox-twilio-integration  # Or wherever you cloned

# Start simple server (no database needed)
python3 scripts/server_simple.py
```

### Step 5: Test

In a new terminal or from your local machine:

```bash
# Check health
curl https://ekq3uygf1706p4-8004.proxy.runpod.net/health

# Should return:
# {"status":"healthy","timestamp":"...","model_loaded":true,"device":"cuda"}

# Generate TTS
curl -X POST "https://ekq3uygf1706p4-8004.proxy.runpod.net/tts" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from RunPod!","format":"wav"}' \
  --output test.wav

# Or use simple endpoint
curl -X POST "https://ekq3uygf1706p4-8004.proxy.runpod.net/generate?text=Hello+world" \
  --output hello.wav
```

---

## Solution 2: Deploy with Full Production Stack

If you need authentication, rate limiting, and database features:

### Step 1: Add PostgreSQL + Redis to RunPod

Create `docker-compose.runpod.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: chatterbox
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme123}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/schema.sql:/docker-entrypoint-initdb.d/schema.sql
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    command: redis-server --maxmemory 512mb
    ports:
      - "6379:6379"

  chatterbox-tts:
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - postgres
      - redis
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      REDIS_HOST: redis
      REDIS_PORT: 6379
      CHATTERBOX_DEVICE: cuda
    ports:
      - "8004:8004"
    volumes:
      - ./outputs:/app/outputs
      - ./logs:/app/logs
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]

volumes:
  postgres_data:
```

### Step 2: Deploy on RunPod

```bash
# In RunPod terminal
cd /workspace/chatterbox-twilio-integration

# Start services
docker-compose -f docker-compose.runpod.yml up -d

# Check logs
docker-compose -f docker-compose.runpod.yml logs -f

# Insert API keys
python3 scripts/generate_api_keys.py -n 5 --sql | \
  docker exec -i $(docker ps -qf "name=postgres") psql -U postgres -d chatterbox
```

---

## Solution 3: Use RunPod Template (Recommended for Production)

### Create RunPod Template

1. Go to **Templates** in RunPod
2. Click **"New Template"**
3. Configure:

```
Name: Chatterbox TTS Production
Container Image: ghcr.io/YOUR_USERNAME/chatterbox-tts:latest
Docker Command: python3 scripts/server.py
Container Disk: 20 GB
Expose HTTP Ports: 8004
Environment Variables:
  - CHATTERBOX_DEVICE=cuda
  - POSTGRES_HOST=host.docker.internal
  - REDIS_HOST=host.docker.internal
Volume Mount Path: /workspace
```

4. Save template
5. Deploy new pod from template

---

## Quick Fix: Rebuild Current Pod

If you just want to get it working NOW:

### Option A: Use Existing RunPod Deployment Files

```bash
# In RunPod terminal
cd /workspace

# Clone your repo fresh
rm -rf chatterbox-twilio-integration
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-twilio-integration
cd chatterbox-twilio-integration

# Use RunPod deployment script
chmod +x runpod/deploy_runpod.sh
./runpod/deploy_runpod.sh
```

### Option B: Manual Start

```bash
# Install dependencies
pip3 install -r requirements.txt

# Set environment
export CHATTERBOX_DEVICE=cuda
export CHATTERBOX_PORT=8004

# Start simple server (no DB)
python3 scripts/server_simple.py &

# Or start full server (needs DB setup first)
# python3 scripts/server.py &
```

---

## Debugging Commands

```bash
# Check if port 8004 is listening
netstat -tlnp | grep 8004
# Or
lsof -i :8004

# Check GPU
nvidia-smi

# Check Python processes
ps aux | grep python

# Test locally first
curl http://localhost:8004/health

# Then test via proxy
curl https://ekq3uygf1706p4-8004.proxy.runpod.net/health

# View real-time logs
tail -f logs/server.log
```

---

## Common Issues

### Issue 1: "TTS model not loaded"

**Cause:** Not enough VRAM or model download failed

**Fix:**
```bash
# Check VRAM
nvidia-smi

# Clear cache and retry
rm -rf /app/hf_cache/*
python3 scripts/server_simple.py
```

### Issue 2: "Port 8004 already in use"

**Cause:** Another process is using the port

**Fix:**
```bash
# Find and kill process
lsof -ti:8004 | xargs kill -9

# Or use different port
export CHATTERBOX_PORT=8005
python3 scripts/server_simple.py
```

### Issue 3: "Database connection failed"

**Cause:** PostgreSQL not running

**Fix:**
```bash
# Start PostgreSQL
docker-compose up -d postgres redis

# Or use simple server without DB
python3 scripts/server_simple.py
```

---

## Test Endpoints

Once server is running:

```bash
BASE_URL="https://ekq3uygf1706p4-8004.proxy.runpod.net"

# 1. Check health
curl $BASE_URL/health

# 2. View API docs
open $BASE_URL/docs  # Opens in browser

# 3. Generate TTS (simple server)
curl -X POST "$BASE_URL/tts" \
  -H "Content-Type: application/json" \
  -d '{"text":"Testing RunPod TTS!"}' \
  -o test.wav

# 4. Simple generate endpoint
curl -X POST "$BASE_URL/generate?text=Hello+from+RunPod" \
  -o hello.wav
```

---

## Next Steps

1. **Get Simple Server Working First**
   - Use `server_simple.py` (no database)
   - Verify TTS generation works
   - Test all endpoints

2. **Add Database Layer** (if needed)
   - Start PostgreSQL + Redis
   - Use full production server
   - Add API key authentication

3. **Optimize Performance**
   - Enable model caching
   - Configure batch processing
   - Set up load balancing

---

## Support

If still not working:

1. **Share RunPod logs:**
   ```bash
   tail -200 logs/server.log > debug.log
   cat debug.log
   ```

2. **Check Docker logs:**
   ```bash
   docker logs $(docker ps -q) 2>&1 | tail -100
   ```

3. **Test locally first:**
   ```bash
   curl http://localhost:8004/health -v
   ```

4. **Verify RunPod port forwarding:**
   - Go to RunPod Dashboard
   - Check "Connect" → "TCP Port Mappings"
   - Ensure 8004 is forwarded

---

**Quick Start Command:**

```bash
cd /workspace/chatterbox-twilio-integration && \
python3 scripts/server_simple.py
```

Then test: `curl https://ekq3uygf1706p4-8004.proxy.runpod.net/health`

---

**Last Updated:** 2024-10-07

