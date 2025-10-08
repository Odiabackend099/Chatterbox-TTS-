# 🚀 RunPod Deployment - PyTorch 2.8.0

**Base Image**: `runpod/pytorch:1.0.1-cu1281-torch280-ubuntu2404`

---

## ⚡ Quick Deploy

### Option 1: Use RunPod Template (Easiest)

1. **Go to RunPod**: https://www.runpod.io/console/pods
2. **Click**: Deploy → GPU Pod
3. **Select GPU**: RTX 4090, A4000, or A100
4. **Use this Docker image**:
   ```
   runpod/pytorch:1.0.1-cu1281-torch280-ubuntu2404
   ```

5. **Set up after pod starts**:
   ```bash
   # SSH into pod
   cd /workspace
   git clone https://github.com/YOUR-USERNAME/chatterbox-twilio-integration.git
   cd chatterbox-twilio-integration
   pip install -r requirements.txt
   python scripts/server_production.py
   ```

6. **Expose Port**: 8004

---

### Option 2: Custom Docker Image (Recommended)

**Build and deploy your custom image:**

```bash
# Build the image
./runpod/deploy_pytorch280.sh

# Follow the on-screen instructions
```

---

## 📋 RunPod Configuration

### Container Settings

```yaml
Container Image: runpod/pytorch:1.0.1-cu1281-torch280-ubuntu2404
Container Disk: 20 GB
Volume Disk: 50 GB
Volume Path: /workspace
```

### Exposed Ports

```
HTTP Ports: 8004
```

### Environment Variables

```bash
# API Keys (from generated_api_keys.txt)
API_KEY_1=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
API_KEY_2=cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI
API_KEY_3=cw_live_9rSEdn-4tfW-blbihfBsm08S1Zggs0OaJuLbCFXGKd8

# Service Configuration
TTS_PORT=8004
PRELOAD_MODEL=true
PYTHONUNBUFFERED=1
```

---

## 🔧 Manual Setup in RunPod

If you're using the base PyTorch image without custom Docker:

### 1. Start Pod and SSH In

```bash
# You'll get SSH credentials from RunPod dashboard
ssh root@YOUR-POD-ID.runpod.io
```

### 2. Clone and Setup

```bash
cd /workspace

# Clone your repository (or upload files)
git clone https://github.com/YOUR-USERNAME/chatterbox-twilio-integration.git
cd chatterbox-twilio-integration

# Install dependencies
pip install -r requirements.txt

# Install additional dependencies
pip install fastapi uvicorn[standard] httpx python-multipart
```

### 3. Configure API Keys

```bash
# Create .env file
cat > .env << EOF
API_KEY_1=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
API_KEY_2=cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI
TTS_PORT=8004
EOF
```

### 4. Start TTS Service

```bash
# Start in background
nohup python scripts/server_production.py > logs/tts.log 2>&1 &

# Or use screen
screen -S tts
python scripts/server_production.py
# Press Ctrl+A, D to detach
```

### 5. Test It

```bash
# Health check
curl http://localhost:8004/health

# Test TTS
curl -X POST http://localhost:8004/api/tts \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Hello from RunPod!" \
  -F "voice_id=naija_female" \
  --output test.mp3
```

---

## 🌐 Access Your Service

### Get Your Pod URL

Once deployed, RunPod gives you a URL:

```
https://YOUR-POD-ID-8004.proxy.runpod.net
```

### Test Endpoints

```bash
# Replace YOUR-POD-ID with your actual pod ID
POD_ID="YOUR-POD-ID"

# Health check
curl https://$POD_ID-8004.proxy.runpod.net/health

# TTS test
curl -X POST "https://$POD_ID-8004.proxy.runpod.net/api/tts" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Hello from Nigeria!" \
  -F "voice_id=naija_female" \
  --output test.mp3
```

---

## 📊 System Requirements

### Minimum GPU

- **Memory**: 8 GB VRAM
- **Examples**: RTX 3060 12GB, RTX 3080

### Recommended GPU

- **Memory**: 16+ GB VRAM
- **Examples**: RTX 4090, A4000, A5000, A100

### Disk Space

- **Container**: 20 GB
- **Volume**: 50 GB (for models and cache)

---

## 🔍 Troubleshooting

### Port 8004 Shows Jupyter

**Problem**: Port 8004 is not running TTS

**Solution**:
```bash
# SSH into pod
ps aux | grep python

# Kill Jupyter if running
pkill -f jupyter

# Start TTS service
cd /workspace/chatterbox-twilio-integration
python scripts/server_production.py
```

### Service Won't Start

**Check logs**:
```bash
tail -f logs/tts.log
```

**Common issues**:
- Port already in use: `lsof -i :8004`
- Missing dependencies: `pip install -r requirements.txt`
- CUDA not available: Check GPU is assigned to pod

### Can't Connect from Outside

**Check**:
1. Port 8004 is exposed in RunPod settings
2. Service is actually running: `curl localhost:8004/health`
3. Use correct proxy URL: `https://POD-ID-8004.proxy.runpod.net`

---

## 📁 Files Created

```
runpod/
├── Dockerfile.pytorch280        ← Custom Docker image
├── entrypoint_production.sh     ← Startup script
├── deploy_pytorch280.sh         ← Build & deploy script
└── PYTORCH280_SETUP.md          ← This guide
```

---

## 🚀 Quick Start Commands

```bash
# Build Docker image
./runpod/deploy_pytorch280.sh

# Or manual setup in RunPod pod
cd /workspace
git clone YOUR-REPO
cd chatterbox-twilio-integration
pip install -r requirements.txt
python scripts/server_production.py
```

---

## ✅ Deployment Checklist

- [ ] RunPod account created
- [ ] GPU pod selected (RTX 4090 recommended)
- [ ] Base image configured: `runpod/pytorch:1.0.1-cu1281-torch280-ubuntu2404`
- [ ] Port 8004 exposed
- [ ] Environment variables set (API keys)
- [ ] Service started
- [ ] Health endpoint returns 200
- [ ] TTS endpoint works
- [ ] Pod URL noted for integration

---

**Pod ID**: `sbwpfh7exfn63d` (your existing pod)  
**Correct URL**: `https://sbwpfh7exfn63d-8004.proxy.runpod.net`  
**Status**: Needs TTS service started on port 8004

---

## 🔧 Fix Your Current Pod

Since you already have pod `sbwpfh7exfn63d`:

```bash
# 1. SSH into your pod
ssh root@sbwpfh7exfn63d.runpod.io

# 2. Navigate to workspace
cd /workspace

# 3. Clone/upload your code
# (upload via RunPod web terminal or git clone)

# 4. Start TTS service on port 8004
python scripts/server_production.py
```

Then update your test scripts to use port **8004** instead of 8888! 🎯

