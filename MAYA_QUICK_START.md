# Maya Voice - Quick Start Guide

**New Optimized Voice:** maya-professional  
**Status:** ✅ Ready to Deploy

---

## What Changed

Maya now has a **warm, natural, professional voice** instead of the theatrical, rushed default.

### Parameters

| Parameter | Before | After | Impact |
|-----------|--------|-------|--------|
| Temperature | 0.8 | **0.6** | More consistent |
| Exaggeration | 1.3 | **0.85** | More natural |
| Speed | 1.0 | **0.88** | 12% slower, clearer |
| CFG Weight | 0.5 | **0.75** | Better pronunciation |

---

## Deploy to RunPod (Required)

```bash
./deploy_maya_voice_to_runpod.sh
```

This will:
1. Upload new voice configuration
2. Restart TTS service
3. Verify maya-professional is available

**Time:** ~2 minutes

---

## Test It

### Option 1: Quick Comparison

```bash
./test_maya_voice_quality.sh
```

Generates two audio files:
- `~/Desktop/old_voice.wav` - Old parameters
- `~/Desktop/maya_voice.wav` - New parameters

Listen to both and hear the difference!

### Option 2: Direct Test

```bash
curl -X POST https://aav4qfa6yqgt3k-8888.proxy.runpod.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, I am here to help you today.", "voice": "maya-professional"}' \
  --max-time 180 --output ~/Desktop/maya_test.wav

afplay ~/Desktop/maya_test.wav
```

---

## Use Maya (After Deployment)

### Default Voice

Maya is now the default. No need to specify voice:

```bash
curl -X POST https://aav4qfa6yqgt3k-8888.proxy.runpod.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Your text here"}' \
  --max-time 180 --output output.wav
```

### Explicit Voice

Or specify explicitly:

```bash
curl -X POST https://aav4qfa6yqgt3k-8888.proxy.runpod.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Your text here", "voice": "maya-professional"}' \
  --max-time 180 --output output.wav
```

---

## Expected Results

### Voice Characteristics

- ✅ Warm and approachable
- ✅ Clear and professional
- ✅ Natural, not robotic
- ✅ Consistent across generations
- ✅ Slower pace for better clarity

### What You'll Hear

- Natural pauses
- Professional tone
- Clear articulation
- Warm, friendly delivery
- No theatrical over-acting

---

## Troubleshooting

### Maya voice not available

```bash
# Verify deployment
ssh root@ssh.runpod.io
cd /workspace/chatterbox-twilio-integration
python3 scripts/bootstrap_voices.py
pkill -f server_production
python3 scripts/server_production.py &
```

### Voice sounds the same as before

- Verify deployment completed successfully
- Check that service restarted
- Clear any cached audio

### Need to adjust parameters

Edit `scripts/bootstrap_voices.py` lines 97-102 and redeploy.

---

## Quick Commands

```bash
# Deploy to production
./deploy_maya_voice_to_runpod.sh

# Test locally (comparison)
./test_maya_voice_quality.sh

# Test production endpoint
curl -X POST https://aav4qfa6yqgt3k-8888.proxy.runpod.net/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Test"}' \
  --max-time 180 --output test.wav
```

---

## Documentation

- **Full Details**: `MAYA_VOICE_PARAMETERS.md`
- **Implementation**: `MAYA_VOICE_IMPLEMENTATION_SUMMARY.md`
- **Original Plan**: `.cursor/plans/maya-voice-optimization-*.plan.md`

---

**Ready to deploy?** Run: `./deploy_maya_voice_to_runpod.sh`

