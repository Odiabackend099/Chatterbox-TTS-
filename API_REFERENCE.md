# CallWaiting TTS API Reference

**Version**: 1.0.0  
**Base URL**: `https://tts.odia.dev`

## Authentication

All API endpoints (except `/health` and `/docs`) require authentication using an API key.

**Header Format:**
```http
x-api-key: cw_live_YOUR_API_KEY_HERE
```

**Alternative:**
```http
Authorization: Bearer cw_live_YOUR_API_KEY_HERE
```

---

## Endpoints

### Health & Status

#### `GET /health`
Check API health status.

**No authentication required.**

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-10-07T12:00:00",
  "components": {
    "tts_model": true,
    "database": true,
    "redis": true
  }
}
```

---

### Voice Catalog

#### `GET /v1/voices`
List all available voices.

**Authentication:** Required

**Response:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "slug": "emily-en-us",
    "display_name": "Emily",
    "description": "Natural American English female voice",
    "language": "en-US",
    "gender": "female",
    "sample_url": null,
    "is_public": true
  },
  {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "slug": "james-en-us",
    "display_name": "James",
    "description": "Professional American English male voice",
    "language": "en-US",
    "gender": "male",
    "sample_url": null,
    "is_public": true
  }
]
```

#### `GET /v1/voices/{voice_id}`
Get details for a specific voice.

**Authentication:** Required

**Parameters:**
- `voice_id` (path): UUID of the voice

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "slug": "emily-en-us",
  "display_name": "Emily",
  "language": "en-US",
  "is_public": true
}
```

**Error Responses:**
- `404`: Voice not found or access denied

---

### Text-to-Speech

#### `POST /v1/tts`
Generate speech from text.

**Authentication:** Required

**Request Body:**
```json
{
  "text": "Hello from CallWaiting AI",
  "voice_id": "550e8400-e29b-41d4-a716-446655440000",
  "format": "wav",
  "speed": 1.0,
  "seed": null
}
```

**Parameters:**

| Field | Type | Required | Description | Default |
|-------|------|----------|-------------|---------|
| `text` | string | ✓ | Text to synthesize (max 1200 chars) | - |
| `voice_id` | string | ✓ | Voice UUID from catalog | - |
| `format` | string | | Audio format: `wav`, `mp3`, `pcm16` | `wav` |
| `speed` | float | | Playback speed (0.5 - 2.0) | `1.0` |
| `seed` | integer | | Random seed for reproducibility | `null` |

**Audio Formats:**

| Format | MIME Type | Use Case | Quality |
|--------|-----------|----------|---------|
| `wav` | `audio/wav` | General purpose, lossless | High |
| `mp3` | `audio/mpeg` | Web, mobile apps | Medium |
| `pcm16` | `audio/L16; rate=24000; channels=1` | Telephony, real-time | High |

**Response:**
- Stream of audio bytes
- Content-Type varies by format
- Content-Disposition header with filename

**Response Headers:**
```http
X-Voice-ID: 550e8400-e29b-41d4-a716-446655440000
X-Text-Length: 26
X-Request-ID: 123e4567-e89b-12d3-a456-426614174000
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 119
```

**Examples:**

**curl (WAV):**
```bash
curl -X POST https://tts.odia.dev/v1/tts \
  -H "x-api-key: cw_live_YOUR_KEY" \
  -H "content-type: application/json" \
  -d '{
    "text": "Welcome to our service",
    "voice_id": "550e8400-e29b-41d4-a716-446655440000",
    "format": "wav"
  }' \
  -o output.wav
```

**curl (PCM16 for Twilio):**
```bash
curl -X POST https://tts.odia.dev/v1/tts \
  -H "x-api-key: cw_live_YOUR_KEY" \
  -H "content-type: application/json" \
  -d '{
    "text": "Your code is 1 2 3 4",
    "voice_id": "550e8400-e29b-41d4-a716-446655440000",
    "format": "pcm16",
    "speed": 0.9
  }' \
  -o output.pcm
```

**Python:**
```python
import requests

response = requests.post(
    "https://tts.odia.dev/v1/tts",
    headers={"x-api-key": "cw_live_YOUR_KEY"},
    json={
        "text": "Hello world",
        "voice_id": "550e8400-e29b-41d4-a716-446655440000",
        "format": "mp3",
        "speed": 1.0
    }
)

with open("output.mp3", "wb") as f:
    f.write(response.content)
```

**JavaScript/TypeScript:**
```typescript
const response = await fetch("https://tts.odia.dev/v1/tts", {
  method: "POST",
  headers: {
    "x-api-key": "cw_live_YOUR_KEY",
    "content-type": "application/json",
  },
  body: JSON.stringify({
    text: "Hello from JavaScript",
    voice_id: "550e8400-e29b-41d4-a716-446655440000",
    format: "wav",
  }),
});

const blob = await response.blob();
const audio = new Audio(URL.createObjectURL(blob));
audio.play();
```

**Error Responses:**
- `400`: Invalid request (missing fields, text too long)
- `404`: Voice not found
- `429`: Rate limit exceeded
- `500`: TTS generation failed

---

### Usage Statistics

#### `GET /v1/usage`
Get usage statistics for your API key.

**Authentication:** Required

**Query Parameters:**
- `days` (optional): Number of days to retrieve (default: 7, max: 90)

**Response:**
```json
[
  {
    "day": "2024-10-07",
    "requests": 245,
    "characters": 12450,
    "avg_latency_ms": 850.5
  },
  {
    "day": "2024-10-06",
    "requests": 312,
    "characters": 15600,
    "avg_latency_ms": 892.3
  }
]
```

---

### Authentication Verification

#### `GET /v1/auth/verify`
Verify API key and get key information.

**Authentication:** Required

**Response:**
```json
{
  "valid": true,
  "api_key_id": "770e8400-e29b-41d4-a716-446655440000",
  "api_key_name": "Production Key #1",
  "tenant_id": "00000000-0000-0000-0000-000000000000",
  "scopes": ["tts:write", "voices:read"]
}
```

---

### Monitoring

#### `GET /metrics`
Prometheus metrics endpoint.

**Authentication:** Not required (restricted by IP)

**Response:** Prometheus text format

**Metrics:**
- `http_requests_total` - Total HTTP requests
- `tts_requests_total` - Total TTS requests by voice/format
- `tts_generation_duration_seconds` - TTS latency histogram
- `api_key_rate_limit_exceeded_total` - Rate limit violations
- `system_cpu_percent` - CPU usage
- `system_memory_percent` - Memory usage

---

## Rate Limiting

Default rate limits per API key:
- **120 requests per minute**
- **10,000 requests per day**

Rate limit headers are included in all responses:
```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 95
```

When rate limit is exceeded:
```json
{
  "detail": "Rate limit exceeded: 120 requests per minute"
}
```
**Status Code:** `429 Too Many Requests`  
**Retry-After:** `60` (seconds)

---

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid API key |
| 403 | Forbidden | API key inactive or suspended |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | TTS generation or server error |
| 503 | Service Unavailable | Service temporarily unavailable |

**Error Response Format:**
```json
{
  "detail": "Error message here"
}
```

---

## Limits & Quotas

| Limit | Value |
|-------|-------|
| Max text length | 1,200 characters |
| Max requests/minute | 120 (default) |
| Max requests/day | 10,000 (default) |
| Audio file size | ~1-10 MB (varies by text length) |
| Supported languages | English (more coming) |

---

## Best Practices

### 1. Caching
Cache generated audio for repeated text:
```python
cache_key = f"{voice_id}:{text_hash}"
if cache_key in cache:
    return cache[cache_key]
```

### 2. Error Handling
Always handle errors gracefully:
```python
try:
    response = requests.post(url, ...)
    response.raise_for_status()
except requests.exceptions.HTTPError as e:
    if e.response.status_code == 429:
        # Wait and retry
        time.sleep(60)
```

### 3. Streaming for Long Text
For text > 200 characters, the API automatically chunks and streams:
```python
response = requests.post(url, json={...}, stream=True)
with open("output.wav", "wb") as f:
    for chunk in response.iter_content(chunk_size=8192):
        f.write(chunk)
```

### 4. Telephony Integration
For Twilio/phone systems, use PCM16 format:
```python
{
  "format": "pcm16",
  "speed": 0.9  # Slightly slower for clarity
}
```

### 5. API Key Security
- Never commit API keys to version control
- Use environment variables or secret managers
- Rotate keys regularly
- Use different keys for dev/staging/production

---

## SDK Examples

### Python SDK (requests)
```python
import requests
import os

API_KEY = os.environ["CALLWAITING_API_KEY"]
BASE_URL = "https://tts.odia.dev"

def text_to_speech(text: str, voice_id: str, format: str = "wav"):
    response = requests.post(
        f"{BASE_URL}/v1/tts",
        headers={"x-api-key": API_KEY},
        json={"text": text, "voice_id": voice_id, "format": format},
        timeout=60
    )
    response.raise_for_status()
    return response.content

# Usage
audio = text_to_speech("Hello world", "550e8400-e29b-41d4-a716-446655440000")
with open("output.wav", "wb") as f:
    f.write(audio)
```

### Node.js SDK
```javascript
const axios = require('axios');
const fs = require('fs');

const API_KEY = process.env.CALLWAITING_API_KEY;
const BASE_URL = 'https://tts.odia.dev';

async function textToSpeech(text, voiceId, format = 'wav') {
  const response = await axios.post(
    `${BASE_URL}/v1/tts`,
    { text, voice_id: voiceId, format },
    {
      headers: { 'x-api-key': API_KEY },
      responseType: 'arraybuffer',
      timeout: 60000
    }
  );
  return response.data;
}

// Usage
textToSpeech('Hello world', '550e8400-e29b-41d4-a716-446655440000')
  .then(audio => fs.writeFileSync('output.wav', audio));
```

---

## Support

- **API Documentation**: https://tts.odia.dev/docs
- **Status Page**: https://tts.odia.dev/health
- **Metrics**: http://localhost:8004/metrics (internal)

For technical support or to request increased rate limits, contact your account manager.

---

**Last Updated**: 2024-10-07

