# ✅ You're Already on RunPod!

**You're connected!** The prompt `root@3fbf5eb5e633:/#` means you're inside your RunPod container.

---

## 🚀 Just Run These Commands

### Copy and paste ALL of these (one by one):

```bash
# Navigate to workspace
cd /workspace

# Update system
apt-get update -qq && apt-get install -y -qq git curl wget ffmpeg libsndfile1

# Clone your repository
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-twilio-integration

# Enter directory
cd chatterbox-twilio-integration

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install fastapi uvicorn[standard] httpx python-multipart

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

# Start TTS service
nohup python scripts/server_production.py > logs/tts.log 2>&1 &

# Wait a moment
sleep 5

# Test it
curl http://localhost:8004/health
```

---

## ⚡ OR Use the Automated Script:

```bash
cd /workspace
curl -sSL https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh | bash
```

---

## ✅ Verify It's Working

After running the commands above:

```bash
# Check health
curl http://localhost:8004/health

# Should return: {"status": "healthy", ...}

# View logs
tail -f logs/tts.log

# Check process
ps aux | grep server_production
```

---

## 🧪 Test from Your Mac

Open a **new terminal on your Mac** and run:

```bash
# Test health
curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/health

# Quick test with auto-play
./test_scripts/quick_test.sh
```

---

**You're already connected to RunPod - just run the deployment commands!** 🚀

