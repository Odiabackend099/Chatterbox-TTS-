# RunPod Production TTS Server - Complete Guide

## 🎯 Mission: Production-Ready TTS on RunPod

**Pod ID:** `dmbt2v5xek8fou`
**Status:** ✅ Ready for Deployment

---

## 🚀 ONE-COMMAND DEPLOYMENT

```bash
cd /workspace/chatterbox-tts && bash runpod/start_production.sh
```

This single command:
1. ✅ Kills conflicting processes (JupyterLab on port 8888)
2. ✅ Starts TTS server in background
3. ✅ Monitors startup (25s for model loading)
4. ✅ Verifies health check
5. ✅ Displays connection info and test commands

---

## ✨ What's Been Fixed

### 1. Robust WAV Encoding ✅
- Float32 dtype conversion
- Audio normalization to [-1, 1]
- Explicit PCM_16 subtype
- File size validation
- Comprehensive error handling
- **Location:** `scripts/api_production.py:100-174`

### 2. Port 8888 Default ✅
- No environment variables needed
- **Location:** `scripts/server_production.py:143`

### 3. Production Startup Script ✅
- Background process management
- Auto-recovery from port conflicts
- Health monitoring
- **Location:** `runpod/start_production.sh`

---

## 🧪 Test Commands

### After Deployment, Run:

```bash
curl -X POST http://localhost:8888/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Production server is working!", "voice": "emily-en-us"}' \
  --output success.wav
```

### Expected Logs (in `/workspace/chatterbox-tts/logs/tts_server.log`):

```
[request-id] Prepared WAV: shape=(XXXXX,), dtype=float32, range=[-0.XXX, 0.XXX]
[request-id] ✓ Wrote WAV to /tmp/tmpXXX.wav (XXXXX samples)
[request-id] ✓ Temp file size: XXXXX bytes
[request-id] ✓ Read XXXXX bytes from temp file
[request-id] ✓ Cleaned up temp file
```

---

## 📝 Server Management

| Action | Command |
|--------|---------|
| **Start** | `cd /workspace/chatterbox-tts && bash runpod/start_production.sh` |
| **View Logs** | `tail -f /workspace/chatterbox-tts/logs/tts_server.log` |
| **Stop** | `kill $(cat /workspace/chatterbox-tts/logs/tts_server.pid)` |
| **Status** | `ps -p $(cat /workspace/chatterbox-tts/logs/tts_server.pid)` |

---

## 🌐 URLs

- **Internal:** `http://localhost:8888`
- **External:** `https://dmbt2v5xek8fou-8888.proxy.runpod.net`
- **Docs:** `https://dmbt2v5xek8fou-8888.proxy.runpod.net/docs`

---

## 📊 Endpoints

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/api/tts` | Generate TTS |
| GET | `/api/voices` | List voices |
| GET | `/api/health` | Health check |
| GET | `/docs` | API docs |

---

**Ready to deploy!** 🚀
