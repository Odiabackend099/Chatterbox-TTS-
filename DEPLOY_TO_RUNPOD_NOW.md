# 🚀 Deploy to RunPod - NOW!

**Your Pod**: a288y3vpbfxwkk  
**Ready to deploy in 2 minutes!**

---

## ⚡ Super Quick Deployment (2 Steps)

### Step 1: SSH into RunPod (10 seconds)

```bash
ssh a288y3vpbfxwkk-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519
```

### Step 2: Run Deployment Script (2 minutes)

Copy and paste this single command:

```bash
curl -sSL https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh | bash
```

**OR** if you prefer to review first:

```bash
# Download script
wget https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh

# Review it
cat DEPLOY_NOW.sh

# Run it
bash DEPLOY_NOW.sh
```

---

## 📋 What the Script Does

1. ✅ Installs system dependencies (git, ffmpeg, etc.)
2. ✅ Clones your GitHub repository
3. ✅ Installs Python packages
4. ✅ Creates environment configuration
5. ✅ Sets up directories
6. ✅ Checks GPU availability
7. ✅ Starts TTS service on port 8004
8. ✅ Tests the service

**Total time**: ~2 minutes

---

## 🎯 Your Service URLs

After deployment:

**Public URL** (use this):
```
https://a288y3vpbfxwkk-8888.proxy.runpod.net
```

**Health Check**:
```
https://a288y3vpbfxwkk-8888.proxy.runpod.net/health
```

**TTS Endpoint**:
```
https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts
```

---

## ✅ Verify Deployment

### From RunPod (SSH session):

```bash
# Check health
curl http://localhost:8004/health

# View logs
tail -f /workspace/chatterbox-twilio-integration/logs/tts.log

# Check process
ps aux | grep server_production
```

### From Your Local Machine:

```bash
# Health check
curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/health

# Test TTS (auto-play!)
./test_scripts/quick_test.sh
```

---

## 🔧 Manual Deployment (If You Prefer)

### 1. SSH into RunPod

```bash
ssh a288y3vpbfxwkk-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519
```

### 2. Setup

```bash
# Update system
apt-get update
apt-get install -y git curl wget ffmpeg libsndfile1

# Navigate to workspace
cd /workspace

# Clone repository
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-twilio-integration
cd chatterbox-twilio-integration

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install fastapi uvicorn[standard] httpx python-multipart
```

### 3. Configure

```bash
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
```

### 4. Start Service

```bash
# Start in background
nohup python scripts/server_production.py > logs/tts.log 2>&1 &

# Check it's running
curl http://localhost:8004/health
```

### 5. Keep Running (Optional)

Use `screen` to keep it running after you disconnect:

```bash
# Start screen session
screen -S tts

# Run service
python scripts/server_production.py

# Detach: Press Ctrl+A then D

# Reattach later
screen -r tts
```

---

## 🧪 Test It

### Quick Test from Local Machine:

```bash
# Make sure you're in project directory
cd /Users/odiadev/chatterbox-twilio-integration

# Run quick test (with auto-play!)
./test_scripts/quick_test.sh
```

### Manual Test:

```bash
curl -X POST "https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Hello from RunPod!" \
  -F "voice_id=naija_female" \
  --output runpod_test.mp3

# Play it
open runpod_test.mp3
```

---

## 🔍 Troubleshooting

### Service Won't Start

```bash
# Check logs
tail -f logs/tts.log

# Check if port is in use
lsof -i :8004

# Kill existing process
pkill -f server_production

# Restart
python scripts/server_production.py
```

### GPU Not Detected

```bash
# Check CUDA
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Check GPU
nvidia-smi
```

### Can't Connect from Outside

1. Check RunPod dashboard - ensure port 8004 is exposed
2. Verify service is running: `curl localhost:8004/health`
3. Check firewall settings in RunPod

---

## 📊 Monitoring

### View Logs in Real-Time

```bash
tail -f /workspace/chatterbox-twilio-integration/logs/tts.log
```

### Check Resource Usage

```bash
# CPU/Memory
htop

# GPU usage
watch -n 1 nvidia-smi
```

### Check Service Status

```bash
# Process status
ps aux | grep server_production

# Port status
lsof -i :8004

# Recent logs
tail -20 logs/tts.log
```

---

## 🔄 Update Code

To pull latest changes from GitHub:

```bash
cd /workspace/chatterbox-twilio-integration

# Pull updates
git pull origin main

# Restart service
pkill -f server_production
python scripts/server_production.py &
```

---

## ⏹️ Stop Service

```bash
# Find process
ps aux | grep server_production

# Kill it
pkill -f server_production

# Or by PID
kill <PID>
```

---

## 🎉 Next Steps After Deployment

1. ✅ **Test locally**: `./test_scripts/quick_test.sh`
2. ✅ **Import n8n workflow**: `n8n/tts_workflow_READY.json`
3. ✅ **Setup Twilio**: Configure webhook to your service
4. ✅ **Monitor**: Check logs and GPU usage

---

## 📞 Your Complete System

Once deployed:

```
✅ RunPod TTS:  https://a288y3vpbfxwkk-8888.proxy.runpod.net
✅ n8n Ready:   Import n8n/tts_workflow_READY.json
✅ Twilio:      Configure webhooks (see TWILIO_INTEGRATION.md)
✅ Tests:       ./test_scripts/quick_test.sh
```

---

## 🚀 DEPLOY NOW!

**Copy this command and run on RunPod**:

```bash
curl -sSL https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh | bash
```

**Total deployment time**: ~2 minutes ⚡

---

**Pod**: a288y3vpbfxwkk  
**SSH**: `ssh a288y3vpbfxwkk-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519`  
**Status**: Ready to deploy! 🎯

