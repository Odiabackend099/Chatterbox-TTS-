# 🔧 Auto-Fix Script - One Command Deployment

## Quick Start

Run this **ONE COMMAND** to fix all import issues, test the server, and push to GitHub:

```bash
bash fix_and_push.sh
```

That's it! The script will:
- ✅ Fix all Python import paths
- ✅ Set up PYTHONPATH correctly
- ✅ Validate server configuration
- ✅ Test all endpoints
- ✅ Commit and push to GitHub

---

## What It Does

### 1. **Fix Import Paths**
Automatically updates all imports in `scripts/server.py`:
```python
# Before (broken):
from auth import APIKeyMiddleware

# After (fixed):
from scripts.auth import APIKeyMiddleware
```

### 2. **Set Python Path**
```bash
export PYTHONPATH=/workspace/chatterbox-tts
```

### 3. **Test Server**
- Starts server on `localhost:8004`
- Tests health endpoint
- Tests TTS endpoint
- Generates test audio file

### 4. **Push to GitHub**
Commits all fixes and pushes to main branch

---

## Deploy to RunPod

After running `fix_and_push.sh` locally, deploy to RunPod:

### Method 1: SSH into RunPod

```bash
# 1. SSH into your pod
ssh root@YOUR_POD_IP

# 2. Navigate to code
cd /workspace/chatterbox-tts

# 3. Pull latest fixes
git pull origin main

# 4. Start server
bash start_server.sh
```

### Method 2: RunPod Web Terminal

1. Open RunPod Dashboard
2. Click your pod → **"Connect"** → **"Start Web Terminal"**
3. Run:

```bash
cd /workspace/chatterbox-tts
git pull origin main
bash start_server.sh
```

---

## Test Your Deployment

```bash
# Replace with your actual RunPod URL
RUNPOD_URL="https://YOUR-POD-ID-8004.proxy.runpod.net"

# 1. Health check
curl $RUNPOD_URL/health

# 2. List voices
curl $RUNPOD_URL/api/voices

# 3. Generate TTS
curl -X POST "$RUNPOD_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Adaqua AI is now live!",
    "voice": "emily-en-us"
  }' \
  --output deployed.wav
```

---

## Files Created

| File | Purpose |
|------|---------|
| `fix_and_push.sh` | Main auto-fix script |
| `start_server.sh` | Server startup script for RunPod |
| `server_test.log` | Test execution logs |
| `adaqua_test.wav` | Test audio file |

---

## Troubleshooting

### If `fix_and_push.sh` fails:

**1. Check Python version:**
```bash
python3 --version  # Should be 3.8+
```

**2. Check dependencies:**
```bash
pip install fastapi uvicorn
```

**3. Manual fix:**
```bash
# Set Python path
export PYTHONPATH=/workspace/chatterbox-tts

# Fix imports manually
nano scripts/server.py
# Change: from auth import → from scripts.auth import
```

### If RunPod deployment fails:

**1. Check logs:**
```bash
tail -100 server_test.log
```

**2. Check if server is running:**
```bash
ps aux | grep uvicorn
netstat -tlnp | grep 8004
```

**3. Restart server:**
```bash
pkill -f uvicorn
bash start_server.sh
```

---

## Advanced: Custom Configuration

Edit `start_server.sh` to customize:

```bash
#!/bin/bash
export PYTHONPATH=/workspace/chatterbox-tts
export CHATTERBOX_HOST=0.0.0.0
export CHATTERBOX_PORT=8004        # Change port here
export WORKERS=4                   # Add workers

cd /workspace/chatterbox-tts
exec uvicorn scripts.server:app \
  --host 0.0.0.0 \
  --port 8004 \
  --workers $WORKERS \
  --log-level info
```

---

## Quick Reference

```bash
# Run auto-fix (local)
bash fix_and_push.sh

# Start server (RunPod)
bash start_server.sh

# Test health
curl http://localhost:8004/health

# Stop server
pkill -f uvicorn

# View logs
tail -f server_test.log
```

---

## Success Criteria

✅ `fix_and_push.sh` completes without errors  
✅ Server starts on `0.0.0.0:8004`  
✅ Health endpoint returns `{"status":"healthy"}`  
✅ TTS endpoint generates audio  
✅ Changes pushed to GitHub  
✅ RunPod deployment accessible via proxy URL  

---

**Last Updated:** 2024-10-07

