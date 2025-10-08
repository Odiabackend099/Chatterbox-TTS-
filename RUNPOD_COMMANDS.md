# 🚀 RunPod Deployment Commands (Directory Already Exists)

**You're on RunPod!** The directory exists, so just update and start.

---

## ⚡ Copy & Paste These Commands

```bash
# Go to existing directory
cd /workspace/chatterbox-twilio-integration

# Pull latest changes from GitHub
git pull origin main

# Install/update dependencies
pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install fastapi uvicorn[standard] httpx python-multipart -q

# Create environment file
cat > .env << 'EOF'
TTS_PORT=8004
PYTHONUNBUFFERED=1
API_KEY_1=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
API_KEY_2=cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI
TRANSFORMERS_CACHE=/workspace/model_cache
HF_HOME=/workspace/model_cache
EOF

# Create directories
mkdir -p logs outputs model_cache

# Kill any existing service
pkill -9 -f server_production || true

# Start TTS service
nohup python scripts/server_production.py > logs/tts.log 2>&1 &

# Wait for startup
sleep 5

# Test it
curl http://localhost:8004/health
```

---

## 📋 Expected Output

You should see:
```json
{"status": "healthy", "version": "...", ...}
```

---

## 🔍 Check Logs (If Issues)

```bash
tail -f logs/tts.log
```

Press `Ctrl+C` to stop viewing logs.

---

## ✅ Verify Running

```bash
# Check process
ps aux | grep server_production

# Check port
lsof -i :8004
```

---

**Copy the commands above into your RunPod terminal now!** 🚀

