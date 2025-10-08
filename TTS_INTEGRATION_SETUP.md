# 🎯 TTS Integration Setup Guide

Complete guide for integrating your RunPod TTS service with n8n, webhooks, and external applications.

---

## 📁 Files Created

This setup includes the following files:

```
chatterbox-twilio-integration/
├── env.tts.example              # Environment variables template
├── scripts/
│   └── tts_bridge.py           # FastAPI proxy service
├── n8n/
│   ├── README.md               # n8n setup instructions
│   ├── tts_workflow.json       # Complete webhook→TTS→response workflow
│   └── tts_http_node.json      # Standalone TTS node for import
└── test_tts_bridge.sh          # Comprehensive test suite
```

---

## 🚀 Quick Start (3 Options)

### Option A: Direct API Calls (Simplest)

Call your RunPod TTS API directly from any application.

**Setup:**
```bash
# 1. Copy environment template
cp env.tts.example .env.tts

# 2. Edit .env.tts with your RunPod details
nano .env.tts

# 3. Test the connection
source .env.tts
./test_tts_bridge.sh
```

**Usage:**
```bash
curl -X POST "$TTS_BASE_URL/api/tts" \
  -H "Authorization: Bearer $TTS_API_KEY" \
  -F "text=Hello from Nigeria!" \
  -F "voice_id=naija_female" \
  --output hello.mp3
```

---

### Option B: n8n Workflows (Best for Automation)

Import ready-to-use workflows into n8n for visual automation.

**Setup:**

1. **Set n8n Environment Variables** (Settings → Environment):
   ```bash
   TTS_BASE_URL=https://your-pod-id-8888.proxy.runpod.net
   TTS_API_KEY=cw_demo_12345
   DEFAULT_VOICE_ID=naija_female
   ```

2. **Create Header Auth Credential**:
   - Go to **Credentials** → **New** → **Header Auth**
   - Name: `TTS Bearer Auth`
   - Header Name: `Authorization`
   - Header Value: `Bearer {{$env.TTS_API_KEY}}`

3. **Import Workflow**:
   - Go to **Workflows** → **Import from File**
   - Select `n8n/tts_workflow.json`
   - Activate the workflow

4. **Get Your Webhook URL** from the Webhook Trigger node

**Test:**
```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello!", "voice_id": "naija_female"}' \
  --output test.mp3
```

📚 **Full n8n guide**: See `n8n/README.md`

---

### Option C: FastAPI Bridge (Best for Custom Integration)

Run a lightweight proxy service with additional features (caching, error handling, etc.).

**Setup:**
```bash
# 1. Install dependencies
pip install fastapi uvicorn httpx

# 2. Copy and configure environment
cp env.tts.example .env.tts
nano .env.tts

# 3. Start the bridge
source .env.tts
python scripts/tts_bridge.py

# Or with uvicorn directly
uvicorn scripts.tts_bridge:app --host 0.0.0.0 --port 7070
```

**Usage:**
```bash
# Simple call
curl -X POST "http://localhost:7070/tts" \
  -F "text=Hello from the bridge!" \
  -F "voice_id=naija_female" \
  --output bridge.mp3

# Health check
curl http://localhost:7070/health

# API docs (Swagger)
open http://localhost:7070/docs
```

---

## 🧪 Testing

### Automated Test Suite

Run the comprehensive test script:

```bash
source .env.tts
./test_tts_bridge.sh
```

This tests:
- ✅ TTS service health
- ✅ Direct API calls (simple & long text)
- ✅ Multiple voices
- ✅ Bridge service (if running)
- ✅ Error handling (invalid keys, missing params)

### Manual Testing

**Test Direct API:**
```bash
curl -X POST "$TTS_BASE_URL/api/tts" \
  -H "Authorization: Bearer $TTS_API_KEY" \
  -F "text=Testing TTS service" \
  -F "voice_id=naija_female" \
  --output test.mp3 && open test.mp3
```

**Test Bridge:**
```bash
curl -X POST "http://localhost:7070/tts" \
  -F "text=Testing bridge service" \
  --output test.mp3 && open test.mp3
```

---

## 🔧 Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TTS_BASE_URL` | ✅ Yes | - | RunPod TTS endpoint URL |
| `TTS_API_KEY` | ✅ Yes | - | API key for authentication |
| `DEFAULT_VOICE_ID` | No | `naija_female` | Default voice when not specified |
| `TTS_BRIDGE_PORT` | No | `7070` | Port for bridge service |
| `TTS_BRIDGE_HOST` | No | `0.0.0.0` | Host for bridge service |

### Available Voices

Common voice IDs (check your TTS service for full list):
- `naija_female` - Nigerian female voice
- `naija_male` - Nigerian male voice

---

## 🎯 Integration Examples

### JavaScript/TypeScript

```javascript
// Direct API call
async function generateSpeech(text, voiceId = 'naija_female') {
  const formData = new FormData();
  formData.append('text', text);
  formData.append('voice_id', voiceId);

  const response = await fetch(`${TTS_BASE_URL}/api/tts`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${TTS_API_KEY}`
    },
    body: formData
  });

  const audioBlob = await response.blob();
  return URL.createObjectURL(audioBlob);
}

// Usage
const audioUrl = await generateSpeech('Hello from Nigeria!');
const audio = new Audio(audioUrl);
audio.play();
```

### Python

```python
import httpx
import os

TTS_BASE_URL = os.environ['TTS_BASE_URL']
TTS_API_KEY = os.environ['TTS_API_KEY']

async def generate_speech(text: str, voice_id: str = 'naija_female') -> bytes:
    url = f"{TTS_BASE_URL}/api/tts"
    headers = {"Authorization": f"Bearer {TTS_API_KEY}"}
    data = {"text": text, "voice_id": voice_id}
    
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(url, headers=headers, data=data)
        response.raise_for_status()
        return response.content

# Usage
audio_data = await generate_speech("Hello from Nigeria!")
with open("output.mp3", "wb") as f:
    f.write(audio_data)
```

### PHP

```php
<?php
$tts_base_url = getenv('TTS_BASE_URL');
$tts_api_key = getenv('TTS_API_KEY');

function generateSpeech($text, $voiceId = 'naija_female') {
    global $tts_base_url, $tts_api_key;
    
    $ch = curl_init("$tts_base_url/api/tts");
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, [
        'text' => $text,
        'voice_id' => $voiceId
    ]);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        "Authorization: Bearer $tts_api_key"
    ]);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $audio = curl_exec($ch);
    curl_close($ch);
    
    return $audio;
}

// Usage
$audio = generateSpeech("Hello from Nigeria!");
file_put_contents("output.mp3", $audio);
```

---

## 🌐 Twilio Integration

### Step 1: Initial Response (Immediate)

When Twilio calls your webhook, respond immediately to prevent timeout:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say>One moment please, preparing your message...</Say>
</Response>
```

### Step 2: Generate Audio (Async)

In the background, call your TTS service:

```bash
# Generate audio
curl -X POST "$TTS_BASE_URL/api/tts" \
  -H "Authorization: Bearer $TTS_API_KEY" \
  -F "text=$CALLER_MESSAGE" \
  -F "voice_id=naija_female" \
  --output message.mp3
```

### Step 3: Upload to Storage

Upload the MP3 to accessible storage:

```bash
# Example: Upload to S3
aws s3 cp message.mp3 s3://your-bucket/call-audio/message.mp3 --acl public-read

# Get public URL
AUDIO_URL="https://your-bucket.s3.amazonaws.com/call-audio/message.mp3"
```

### Step 4: Play in Call

Use Twilio's API to update the active call:

```bash
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Calls/$CALL_SID.json" \
  -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
  -d "Url=https://your-server.com/play-audio?url=$AUDIO_URL"
```

Where `/play-audio` returns:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Play>{{ audio_url }}</Play>
</Response>
```

### n8n Twilio Flow

See `n8n/README.md` for a complete n8n workflow with:
1. Twilio webhook trigger
2. TTS synthesis
3. S3/Supabase upload
4. Twilio play API call

---

## 🐛 Troubleshooting

### Connection Issues

**Error**: `Cannot connect to TTS service`

**Solutions**:
- ✅ Verify RunPod pod is running: `curl $TTS_BASE_URL/health`
- ✅ Check `TTS_BASE_URL` has correct pod ID
- ✅ Ensure no trailing slash in `TTS_BASE_URL`
- ✅ Verify firewall/network access

### Authentication Issues

**Error**: `401 Unauthorized` or `403 Forbidden`

**Solutions**:
- ✅ Check `TTS_API_KEY` is correct
- ✅ Ensure Bearer format: `Authorization: Bearer YOUR_KEY`
- ✅ Verify API key is active in `generated_api_keys.txt`

### Timeout Issues

**Error**: `Timeout` or `504 Gateway Timeout`

**Solutions**:
- ✅ Increase timeout in HTTP request (default: 30s)
- ✅ Check if text is too long (>500 words may timeout)
- ✅ Verify RunPod has sufficient GPU resources
- ✅ Test with shorter text first

### Audio Issues

**Error**: File too small or corrupted

**Solutions**:
- ✅ Check response is binary (not JSON error)
- ✅ Verify `voice_id` exists in your TTS service
- ✅ Test with simple text: `"Hello world"`
- ✅ Check logs for actual error message

### n8n Issues

**Error**: `Cannot find credential`

**Solutions**:
- ✅ Create Header Auth credential named exactly: `TTS Bearer Auth`
- ✅ Set header value to: `Bearer {{$env.TTS_API_KEY}}`
- ✅ Don't forget `{{` and `}}` for environment variables

**Error**: `Response is not binary`

**Solutions**:
- ✅ Set Response Format to `file` (not `json`)
- ✅ Enable "Return full response" option
- ✅ Check output property name is set

---

## 📊 Performance Tips

### Caching

Implement caching for common phrases:

```python
# Simple in-memory cache
cache = {}

async def generate_speech_cached(text: str, voice_id: str = 'naija_female'):
    cache_key = f"{text}:{voice_id}"
    if cache_key in cache:
        return cache[cache_key]
    
    audio = await generate_speech(text, voice_id)
    cache[cache_key] = audio
    return audio
```

### Batch Processing

For multiple texts, process in parallel:

```python
import asyncio

texts = ["Hello", "Goodbye", "Thank you"]
audio_files = await asyncio.gather(*[
    generate_speech(text) for text in texts
])
```

### Pre-generation

Generate common phrases ahead of time:

```bash
# Pre-generate greetings
for phrase in "Hello" "Goodbye" "Welcome" "Thank you"; do
    curl -X POST "$TTS_BASE_URL/api/tts" \
        -H "Authorization: Bearer $TTS_API_KEY" \
        -F "text=$phrase" \
        -F "voice_id=naija_female" \
        --output "cache/${phrase}.mp3"
done
```

---

## 🔐 Security Best Practices

1. **Never commit `.env.tts`** - Add to `.gitignore`
2. **Use environment variables** - Never hardcode API keys
3. **Rotate API keys** - Regularly update keys
4. **Restrict CORS** - Don't use `allow_origins=["*"]` in production
5. **Rate limiting** - Implement rate limits to prevent abuse
6. **HTTPS only** - Always use HTTPS in production
7. **Validate input** - Sanitize text input to prevent injection

---

## 📚 Additional Resources

- **n8n Integration**: See `n8n/README.md`
- **Main Project**: See `README.md`
- **API Reference**: See `API_REFERENCE.md`
- **Production Deploy**: See `PRODUCTION_DEPLOYMENT.md`

---

## 🎉 What's Next?

- ✅ **Twilio Voice** - Complete phone call integration
- ✅ **Storage** - S3/Supabase for audio hosting
- ✅ **Queue** - Redis queue for high-volume processing
- ✅ **Monitoring** - Track usage and errors
- ✅ **Webhooks** - Implement webhook callbacks for async processing

---

## 🆘 Support

If you encounter issues:

1. Run the test suite: `./test_tts_bridge.sh`
2. Check logs in bridge service
3. Verify RunPod pod status
4. Review this guide's troubleshooting section

---

**Happy Building! 🚀**

