# Quick Start Guide - Chatterbox TTS Voice Isolation

**Get started in 5 minutes!**

---

## 🚀 For Developers (Local Testing)

### 1. Check if Features Are Loaded

```bash
curl http://localhost:8888/api/health | jq .features
```

**Expected Output:**
```json
[
  "voice_isolation",
  "emotion_detection",
  "text_preprocessing",
  "session_queuing"
]
```

---

### 2. Test Basic TTS with Auto Emotion

```bash
curl -X POST "http://localhost:8888/api/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Sorry for the delay!",
    "voice": "support_agent",
    "auto_detect_emotion": true
  }' \
  --output test.wav
```

**Play the audio:**
```bash
# macOS
afplay test.wav

# Linux
aplay test.wav
```

---

### 3. Test Voice Isolation

Open 2 terminals and run **simultaneously**:

**Terminal 1:**
```bash
curl -X POST "http://localhost:8888/api/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This is message one from session A",
    "voice": "naija_female",
    "session_id": "session_a"
  }' \
  --output msg1.wav
```

**Terminal 2:**
```bash
curl -X POST "http://localhost:8888/api/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This is message two from session A",
    "voice": "naija_female",
    "session_id": "session_a"
  }' \
  --output msg2.wav
```

**Result:** Message 2 will **wait** for Message 1 to finish (no overlap!).

---

### 4. Run Full Test Suite

```bash
chmod +x scripts/test_voice_isolation.sh
./scripts/test_voice_isolation.sh
```

---

## 🌐 For Cloud/CourO (Production Deployment)

### 1. SSH to RunPod

```bash
ssh root@<your-runpod-ip>
```

### 2. Pull Latest Code

```bash
cd /workspace/chatterbox-twilio-integration
git pull origin main
```

### 3. Verify Files

```bash
ls -la config/voices.json
ls -la scripts/text_filters.py
ls -la scripts/voice_queue.py
```

### 4. Restart Service

```bash
# Find and kill existing server
pkill -f server_production.py

# Start new server
cd /workspace/chatterbox-twilio-integration
python3 scripts/server_production.py
```

### 5. Test from Outside

```bash
# Replace with your RunPod URL
export RUNPOD_URL="https://xxxxx-8888.proxy.runpod.net"

curl "$RUNPOD_URL/api/health" | jq .features
```

---

## 📱 For n8n Integration

### 1. Import Workflow

1. Open n8n
2. Go to **Workflows** → **Import from File**
3. Select: `n8n/tts_workflow_voice_isolation_EXAMPLE.json`

### 2. Set Environment Variables

In n8n Settings → Variables:

```
TTS_BASE_URL = https://your-runpod-url.runpod.net
TTS_API_KEY = your-api-key-here
```

### 3. Test Webhook

```bash
curl -X POST "http://your-n8n-url/webhook/tts-webhook" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Thank you for calling!",
    "voice": "naija_female",
    "session_id": "call_12345"
  }' \
  --output output.wav
```

---

## 🎯 Common Use Cases

### Use Case 1: Twilio Phone Call

```python
import requests

# When Twilio call starts
call_sid = "CA1234567890abcdef"

# Message 1
response = requests.post(
    f"{TTS_BASE_URL}/api/tts",
    json={
        "text": "Welcome to CallWaiting support!",
        "voice": "naija_female",
        "session_id": call_sid,  # ← Use call SID as session
        "format": "wav"
    }
)

# Message 2 (will queue if message 1 not done)
response = requests.post(
    f"{TTS_BASE_URL}/api/tts",
    json={
        "text": "How can I help you today?",
        "voice": "naija_female",
        "session_id": call_sid,  # ← Same session = queued
        "format": "wav"
    }
)
```

---

### Use Case 2: Multi-User Chat Support

```python
# User A's message (session = user_id_A)
requests.post(TTS_URL, json={
    "text": "Your order is ready",
    "voice": "support_agent",
    "session_id": "user_123"
})

# User B's message (runs in parallel!)
requests.post(TTS_URL, json={
    "text": "Your order is ready",
    "voice": "support_agent",
    "session_id": "user_456"  # ← Different session = parallel
})
```

---

### Use Case 3: Auto-Adaptive Customer Service

```python
# Apologetic scenario
requests.post(TTS_URL, json={
    "text": "Sorry for the inconvenience caused by the delay.",
    "auto_detect_emotion": True  # ← Auto-detects "apologetic"
})

# Urgent scenario
requests.post(TTS_URL, json={
    "text": "URGENT: Your account requires immediate attention!",
    "auto_detect_emotion": True  # ← Auto-detects "urgent"
})
```

---

## 🔍 Monitoring

### Check Queue Stats

```bash
watch -n 5 'curl -s http://localhost:8888/api/queue/stats | jq'
```

**Sample Output:**
```json
{
  "queue": {
    "total_requests": 150,
    "queued_requests": 5,
    "completed_requests": 145,
    "timeout_requests": 0,
    "active_locks": 2,
    "total_locks": 6,
    "active_sessions": 3
  }
}
```

---

## ❓ FAQ

**Q: Do I need to change existing code?**
A: No! All new parameters are optional. Existing integrations work unchanged.

**Q: What if I don't provide session_id?**
A: It will use global queuing (all requests for same voice are queued).

**Q: Can I disable emotion detection?**
A: Yes, set `"auto_detect_emotion": false`

**Q: How do I add a new voice?**
A: Edit `config/voices.json` and restart the server.

**Q: What happens if a request times out?**
A: Returns HTTP 429 "Voice busy" error. Client should retry or use different voice.

---

## 📚 More Resources

- **Full Guide:** [VOICE_TUNING_GUIDE.md](VOICE_TUNING_GUIDE.md)
- **Implementation Details:** [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)
- **Test Suite:** [scripts/test_voice_isolation.sh](scripts/test_voice_isolation.sh)
- **API Docs:** http://localhost:8888/docs

---

**Ready to deploy! 🚀**
