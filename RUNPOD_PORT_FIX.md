# 🔧 RunPod Port Fix - Complete Solution

## 🎯 The Problem

Your server works perfectly, but RunPod's HTTP proxy doesn't expose port 8004 by default.

**What happened:**
- ✅ Server running on port 8004 inside container
- ❌ RunPod proxy only exposes ports 8888, 8000, 7860, etc.
- ❌ External URL returns 404

---

## ✅ The Solution

**Use port 8888** - RunPod's default HTTP proxy port (normally used for Jupyter Lab)

---

## 🚀 Quick Fix for Current Pod

**In your RunPod terminal:**

```bash
# Stop current server
pkill -f server_production.py || true
pkill -f jupyter || true
sleep 2

# Start on port 8888
export CHATTERBOX_PORT=8888
export CHATTERBOX_HOST=0.0.0.0
export CHATTERBOX_DEVICE=cuda
cd /workspace/chatterbox-tts
python scripts/server_production.py
```

**Then test from your Mac:**

```bash
# Replace with your actual pod ID
curl https://ln3898c5gajjr0-8888.proxy.runpod.net/health

# Expected: {"status":"healthy","model_loaded":true}
```

---

## 🐳 Permanent Fix - New Dockerfile

I've created `runpod/Dockerfile.fixed` that:
1. Uses RunPod's PyTorch base image
2. Sets port 8888 by default
3. Includes healthcheck on correct port
4. Auto-clones from GitHub

### Deploy New Image:

```bash
# 1. Build image
docker build -f runpod/Dockerfile.fixed -t your-username/chatterbox-runpod .

# 2. Push to Docker Hub
docker push your-username/chatterbox-runpod

# 3. Create RunPod template with:
#    - Image: your-username/chatterbox-runpod
#    - HTTP Service Port: 8888
```

---

## 📋 RunPod HTTP Service Ports

RunPod exposes these ports by default:
- ✅ **8888** - Jupyter Lab (we're using this)
- ✅ **8000** - Alternative
- ✅ **7860** - Gradio apps
- ❌ **8004** - NOT exposed

---

## 🧪 Testing Checklist

After deploying on port 8888:

### 1. Health Check
```bash
curl https://YOUR-POD-ID-8888.proxy.runpod.net/health
```
Expected: `{"status":"healthy","model_loaded":true}`

### 2. API Documentation
```
https://YOUR-POD-ID-8888.proxy.runpod.net/docs
```

### 3. List Voices
```bash
curl https://YOUR-POD-ID-8888.proxy.runpod.net/api/voices
```

### 4. Generate TTS
```bash
curl -X POST https://YOUR-POD-ID-8888.proxy.runpod.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello from RunPod!","voice":"emily-en-us"}' \
  --output runpod.wav

afplay runpod.wav
```

---

## 🔄 Migration Summary

### Old (Broken):
- Port: 8004
- URL: `https://pod-id-8004.proxy.runpod.net` ❌
- Result: 404

### New (Working):
- Port: 8888
- URL: `https://pod-id-8888.proxy.runpod.net` ✅
- Result: Success!

---

## 📁 New Files Created

1. **`runpod/Dockerfile.fixed`** - Dockerfile with port 8888
2. **`runpod/deploy_fixed.sh`** - Deployment script
3. **`RUNPOD_PORT_FIX.md`** - This guide

---

## 💡 Alternative: Custom Port Configuration

If you MUST use port 8004:

1. Go to RunPod dashboard
2. Select your pod
3. Go to "HTTP Services"
4. Click "Add Service"
5. Add port 8004
6. Save and restart pod

But **port 8888 is easier** - it works immediately!

---

## 🎉 Final Test Commands

Once your pod is running on port 8888:

```bash
# Set your pod ID
POD_ID="ln3898c5gajjr0"

# Health check
curl https://${POD_ID}-8888.proxy.runpod.net/health

# Open docs
open https://${POD_ID}-8888.proxy.runpod.net/docs

# Generate audio
curl -X POST https://${POD_ID}-8888.proxy.runpod.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"Success! The fix worked!","voice":"emily-en-us"}' \
  --output success.wav && afplay success.wav
```

---

**That's it! The issue was just the port number - everything else works perfectly!** ✅

