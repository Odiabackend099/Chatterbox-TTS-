# RunPod Production Deployment Guide

## Quick Start (2 Commands)

```bash
# 1. Update to latest fixes
cd /workspace/chatterbox-tts && git pull

# 2. Start server (auto-configures to port 8888)
python scripts/server_production.py
```

## What Gets Fixed

### ✅ WAV Encoding Issues Resolved
- **Problem**: "Format not recognised" error
- **Solution**:
  - Explicit float32 dtype conversion
  - Audio normalization to [-1, 1] range
  - PCM_16 subtype specification
  - File size validation
  - Comprehensive logging

### ✅ Port Configuration
- **Default**: Port 8888 (no env vars needed)
- **Host**: 0.0.0.0 (external access)
- **Auto-detect**: CUDA GPU

## Expected Startup Output

```
================================================================================
Starting Production TTS Server
================================================================================
Loading voice configurations...
✓ Loaded voice: Luna (luna-en-us)
✓ Loaded voice: Marcus (marcus-en-us)
✓ Loaded voice: Sophia (sophia-en-gb)
✓ Loaded voice: James (james-en-us)
✓ Loaded voice: Emily (emily-en-us)
✓ Loaded 5 voices
✓ CUDA available: NVIDIA RTX 2000Ada Generation
Loading Chatterbox TTS model on cuda...
✓ TTS model loaded successfully
================================================================================
✓ SERVER READY
================================================================================
[STARTUP] Server binding to 0.0.0.0:8888
Uvicorn running on http://0.0.0.0:8888
```

## Test TTS Generation

```bash
curl -X POST http://localhost:8888/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Testing production TTS server", "voice": "emily-en-us"}' \
  --output test.wav
```

## Expected Success Logs

When TTS works correctly, you'll see:

```
[request-id] Generating TTS: voice=emily-en-us, text_len=30
[request-id] Prepared WAV: shape=(72000,), dtype=float32, range=[-0.845, 0.912]
[request-id] ✓ Wrote WAV to /tmp/tmpXXX.wav (72000 samples)
[request-id] ✓ Temp file size: 144044 bytes
[request-id] ✓ Read 144044 bytes from temp file
[request-id] ✓ Cleaned up temp file
[request-id] Generated 3.00s audio in 2500ms
```

## API Endpoints

- `POST /api/tts` - Generate TTS audio
- `GET /api/voices` - List available voices
- `GET /api/health` - Health check
- `GET /docs` - Interactive API documentation

## Troubleshooting

### If Port 8888 is in Use
```bash
# Check what's using port 8888
lsof -i :8888

# Kill the process
kill -9 <PID>
```

### If Model Download Fails
The Chatterbox TTS model downloads automatically on first run. If it fails:
```bash
export HF_HUB_CACHE=/workspace/model_cache
unset HF_HUB_ENABLE_HF_TRANSFER
```

### View Server Logs
Server logs to stdout with detailed information at each step.

## Production Configuration

- **Audio Format**: WAV, 24kHz, 16-bit PCM
- **Sample Rate**: 24000 Hz
- **Encoding**: PCM_16 (standard WAV)
- **Normalization**: Auto-normalized to [-1, 1]
- **Voices**: 5 pre-configured voices
- **GPU**: CUDA auto-detected

## Latest Fixes (Commit History)

1. **Robust WAV Encoding**: Explicit dtype, normalization, PCM_16 subtype
2. **Port 8888 Default**: No environment variables required
3. **Comprehensive Logging**: Track every step of audio generation
4. **Error Handling**: Graceful fallbacks and cleanup

---

**Ready for Production** ✅

Last Updated: 2025-10-07
