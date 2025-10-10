# 🚀 Deploy to New RunPod Instance - Complete Guide

**Pod ID**: `aav4qfa6yqgt3k`  
**Port**: `8000` (Jupyter is on 8888)  
**Status**: Ready to deploy

---

## 📋 Quick Start (2 Options)

### **Option 1: Transfer Model Cache First (Recommended - Faster)**

Saves 2-3GB download and 10+ minutes of time.

```bash
# Step 1: Transfer model cache from old pod
./transfer_model_cache.sh

# Step 2: Deploy on new pod (via Web Terminal or SSH)
# In RunPod Web Terminal:
cd /workspace
curl -O https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_PORT_8000.sh
chmod +x DEPLOY_PORT_8000.sh
./DEPLOY_PORT_8000.sh

# Step 3: Test from local machine
./test_new_pod.sh
```

### **Option 2: Fresh Install (Simpler, but slower)**

Downloads models fresh (~10 minutes).

```bash
# Deploy on new pod (via Web Terminal or SSH)
# In RunPod Web Terminal:
cd /workspace
curl -O https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_PORT_8000.sh
chmod +x DEPLOY_PORT_8000.sh
./DEPLOY_PORT_8000.sh

# Test from local machine
./test_new_pod.sh
```

---

## 🔧 Detailed Step-by-Step

### **Step 1: Transfer Model Cache (Optional but Recommended)**

**From your local machine:**

```bash
cd /Users/odiadev/chatterbox-twilio-integration
./transfer_model_cache.sh
```

**What it does:**
1. Connects to old pod (`a288y3vpbfxwkk`)
2. Compresses model cache (~2-3GB → ~800MB)
3. Downloads to local machine
4. Uploads to new pod (`aav4qfa6yqgt3k`)
5. Extracts on new pod
6. Cleans up archives

**Expected time:** 5-8 minutes (depends on internet speed)

---

### **Step 2: Deploy TTS Service**

**Option A: Via Web Terminal (Easiest)**

1. Go to RunPod dashboard: https://www.runpod.io/console/pods
2. Find pod: `scared_jade_sloth` (aav4qfa6yqgt3k)
3. Click **"Connect"** → **"Start Web Terminal"**
4. Run deployment:

```bash
cd /workspace

# Clone or update repository
if [ -d "chatterbox-twilio-integration" ]; then
  cd chatterbox-twilio-integration && git pull
else
  git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-twilio-integration
  cd chatterbox-twilio-integration
fi

# Run deployment script
chmod +x runpod/DEPLOY_PORT_8000.sh
./runpod/DEPLOY_PORT_8000.sh
```

**Option B: Via SSH**

```bash
# From your local machine
ssh root@157.157.221.29 -p 19191 -i ~/.ssh/id_ed25519

# Then follow same commands as Option A
```

---

### **Step 3: Verify Deployment**

**From RunPod terminal (inside pod):**

```bash
# Check service is running
curl http://localhost:8000/health

# Expected response:
# {"status":"healthy","model_loaded":true}
```

**From your local machine:**

```bash
# Test public endpoint
curl https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/health

# Run comprehensive tests
./test_new_pod.sh
```

---

### **Step 4: Test n8n Integration**

Your n8n workflows have been updated with the new URL. Test them:

```bash
# Replace with your actual n8n webhook URL
./quick_n8n_test.sh "YOUR_N8N_WEBHOOK_URL"
```

Expected: `🎉 ALL TESTS PASSED!`

---

## ✅ Success Checklist

- [ ] Model cache transferred (or fresh download complete)
- [ ] Service running on port 8000
- [ ] Health endpoint returns `{"status":"healthy","model_loaded":true}`
- [ ] `./test_new_pod.sh` passes all tests
- [ ] Audio files play correctly
- [ ] n8n workflows tested and working
- [ ] Old pod can be stopped/deleted to save costs

---

## 🔍 Troubleshooting

### ❌ **"Connection refused" on health check**

**Cause**: Service not started yet

**Fix**:
```bash
# Check if service is running
ps aux | grep server_production

# View logs
tail -f /workspace/chatterbox-twilio-integration/logs/tts.log

# Restart if needed
cd /workspace/chatterbox-twilio-integration
python scripts/server_production.py
```

---

### ❌ **"Model not loaded" in health response**

**Cause**: Still downloading/loading models

**Fix**:
```bash
# Check logs for progress
tail -f logs/tts.log

# If model cache was transferred, verify it exists
ls -lh /workspace/model_cache/

# Wait 2-3 minutes for model to load into GPU memory
```

---

### ❌ **404 on public URL**

**Cause**: Port not exposed or service on wrong port

**Fix**:
```bash
# Verify service is on port 8000
netstat -tlnp | grep 8000

# Check environment
cat .env | grep PORT

# Ensure CHATTERBOX_PORT=8000 is set
```

---

### ❌ **Audio file is empty or corrupted**

**Cause**: Model not fully loaded or GPU issue

**Fix**:
```bash
# Check GPU
nvidia-smi

# Verify model is loaded
curl http://localhost:8000/health

# Try with simple text first
curl -X POST "http://localhost:8000/api/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test", "voice": "emily-en-us"}' \
  --output test.mp3
```

---

## 📊 What Changed

| Item | Old Pod | New Pod |
|------|---------|---------|
| **Pod ID** | a288y3vpbfxwkk | aav4qfa6yqgt3k |
| **Port** | 8888 | 8000 |
| **Public URL** | `https://a288y3vpbfxwkk-8888.proxy.runpod.net` | `https://aav4qfa6yqgt3k-8000.proxy.runpod.net` |
| **SSH** | `root@213.173.108.103 -p 14814` | `root@157.157.221.29 -p 19191` |
| **GPU** | RTX 2000 Ada | RTX 2000 Ada |

---

## 📝 Files Updated

All these files have been updated with the new pod URL:

- ✅ `n8n/COMPLETE_TTS_WORKFLOW.json`
- ✅ `n8n/tts_workflow_READY.json`
- ✅ `YOUR_ENV_CONFIG.md`
- ✅ `N8N_COMPLETE_SETUP.md`
- ✅ `START_HERE_N8N.txt`

---

## 🗑️ Clean Up Old Pod

Once the new pod is working:

1. **Test everything thoroughly** (don't rush this!)
2. **Backup any important logs** from old pod
3. **Stop old pod** to save costs:
   - Go to RunPod dashboard
   - Find pod `a288y3vpbfxwkk`
   - Click "Stop" or "Terminate"

**Cost savings**: ~$0.25/hour = $6/day = $180/month

---

## 🎯 Quick Commands Reference

### **Local Machine**

```bash
# Transfer model cache
./transfer_model_cache.sh

# Test new pod
./test_new_pod.sh

# Test n8n integration
./quick_n8n_test.sh "YOUR_WEBHOOK_URL"
```

### **On New Pod (via SSH or Web Terminal)**

```bash
# Deploy
cd /workspace/chatterbox-twilio-integration
./runpod/DEPLOY_PORT_8000.sh

# Check health
curl http://localhost:8000/health

# View logs
tail -f logs/tts.log

# Check process
ps aux | grep server_production

# Restart service
pkill -f server_production
python scripts/server_production.py &
```

### **Test Endpoints**

```bash
# Health check
curl https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/health

# List voices
curl https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/voices

# Generate TTS
curl -X POST "https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from new pod!", "voice": "emily-en-us"}' \
  --output test.mp3
```

---

## 📚 Documentation

- **Full setup guide**: `N8N_COMPLETE_SETUP.md`
- **n8n quick start**: `START_HERE_N8N.txt`
- **Environment config**: `YOUR_ENV_CONFIG.md`
- **Troubleshooting**: See above or `RUNPOD_FIX.md`

---

**Status**: ✅ **READY TO DEPLOY**  
**Created**: October 10, 2025  
**Estimated Time**: 15-20 minutes total

🚀 **Let's go!** Run `./transfer_model_cache.sh` to start!

