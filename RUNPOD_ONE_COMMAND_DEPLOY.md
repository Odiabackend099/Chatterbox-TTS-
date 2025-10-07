# 🚀 RunPod One-Command Deployment

## ✅ Complete Production-Ready Deployment

All fixes have been applied and tested:
- ✅ Port 8888 (RunPod HTTP proxy compatibility)
- ✅ `/health` endpoint for Docker healthcheck
- ✅ Robust WAV encoding (torch→numpy conversion)
- ✅ TTS parameter fixes (removed unsupported params)
- ✅ Auto voice bootstrapping
- ✅ CUDA support with proper error handling

---

## 🎯 **One-Command Deployment**

**In your RunPod Web Terminal, run:**

```bash
cd /workspace && \
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-tts && \
cd chatterbox-tts && \
bash runpod/start_production.sh
```

That's it! The script handles everything:
- ✅ Clones latest code
- ✅ Installs dependencies
- ✅ Sets up voices
- ✅ Configures environment
- ✅ Starts server on port 8888

---

## 🧪 **Test After Deployment**

Once you see "✓ SERVER READY", test from your Mac:

### 1. Health Check
```bash
curl https://YOUR-POD-ID-8888.proxy.runpod.net/health
```

**Expected:**
```json
{"status":"healthy","model_loaded":true}
```

### 2. List Voices
```bash
curl https://YOUR-POD-ID-8888.proxy.runpod.net/api/voices | jq
```

### 3. API Documentation
Open in browser:
```
https://YOUR-POD-ID-8888.proxy.runpod.net/docs
```

### 4. Generate TTS
```bash
curl -X POST https://YOUR-POD-ID-8888.proxy.runpod.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello! Your RunPod TTS API is live and working perfectly!","voice":"emily-en-us"}' \
  --output runpod_tts.wav

# Play it
afplay runpod_tts.wav
```

---

## 📋 **Current Pod Details**

Based on your logs, you're on pod: `eb371a35d29d`

**Test URLs will be:**
- Health: `https://YOUR-POD-ID-8888.proxy.runpod.net/health`
- Docs: `https://YOUR-POD-ID-8888.proxy.runpod.net/docs`
- TTS: `https://YOUR-POD-ID-8888.proxy.runpod.net/api/tts`

*(Replace YOUR-POD-ID with actual RunPod pod ID from dashboard)*

---

## 🔧 **All Fixes Applied**

| Issue | Status | Commit |
|-------|--------|--------|
| Docker healthcheck 404 | ✅ Fixed | b3cb545 |
| Port 8004 not exposed | ✅ Fixed | 4c7ef86 |
| Unsupported seed param | ✅ Fixed | 29b1fcd |
| WAV encoding errors | ✅ Fixed | c074826 |
| Torch tensor conversion | ✅ Fixed | 281dea3 |
| Production script | ✅ Added | 3110731 |

---

## 💾 **Deployment Options**

### Option 1: Automated (Recommended)
```bash
cd /workspace && \
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-tts && \
cd chatterbox-tts && \
bash runpod/start_production.sh
```

### Option 2: Manual (Step-by-Step)
```bash
cd /workspace
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-tts
cd chatterbox-tts
pip install -r requirements.txt
python scripts/bootstrap_voices.py
export CHATTERBOX_PORT=8888
export CHATTERBOX_HOST=0.0.0.0
export CHATTERBOX_DEVICE=cuda
unset HF_HUB_ENABLE_HF_TRANSFER
python scripts/server_production.py
```

---

## 🎯 **Production Checklist**

After deployment, verify:

- [ ] Server starts without errors
- [ ] Health endpoint returns `{"status":"healthy","model_loaded":true}`
- [ ] TTS model loaded successfully
- [ ] 5 voices available
- [ ] TTS generation creates valid WAV files
- [ ] External access works through RunPod proxy

---

## 📚 **API Reference**

### Health Check
```bash
GET /health
GET /api/health
```

### List Voices
```bash
GET /api/voices
```

### Generate TTS
```bash
POST /api/tts
Content-Type: application/json

{
  "text": "Your text here",
  "voice": "emily-en-us",
  "format": "wav",
  "temperature": 0.8,
  "exaggeration": 1.3,
  "cfg_weight": 0.5,
  "speed_factor": 1.0
}
```

**Available voices:**
- `emily-en-us` - Natural American English female
- `james-en-us` - Professional American English male
- `sophia-en-gb` - British English female
- `marcus-en-us` - Deep authoritative male
- `luna-en-us` - Expressive energetic female

---

## 🔍 **Troubleshooting**

### If server doesn't start:
```bash
# Check Python version
python --version  # Should be 3.10+

# Check CUDA
nvidia-smi

# Check logs
tail -100 logs/server.log
```

### If TTS fails:
```bash
# Test locally inside container
curl http://localhost:8888/health
curl -X POST http://localhost:8888/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"test","voice":"emily-en-us"}' \
  --output test.wav
```

### If external access fails:
- Verify RunPod HTTP Services configured for port 8888
- Check pod ID in URL matches your actual pod
- Try accessing `/docs` for interactive API documentation

---

## 🌟 **Success Criteria**

Your deployment is successful when:

1. ✅ Server logs show "✓ SERVER READY"
2. ✅ Health check returns HTTP 200 with JSON
3. ✅ TTS generates valid WAV files
4. ✅ External URL works: `https://pod-id-8888.proxy.runpod.net/`

---

## 💡 **Next Steps**

After successful deployment:

1. **Save your pod as a template** (for easy redeployment)
2. **Note your pod URL** for API access
3. **Integrate with your applications**
4. **Monitor usage** through RunPod dashboard

---

**Deploy now with the one-command script!** 🚀

