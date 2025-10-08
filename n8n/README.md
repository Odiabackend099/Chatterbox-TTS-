# n8n TTS Integration

This folder contains n8n workflows for integrating with your RunPod TTS service.

## 📁 Files

- `tts_workflow.json` - Complete workflow that accepts webhook triggers and returns MP3 audio
- `tts_http_node.json` - Standalone HTTP Request node (for importing into existing workflows)

## 🚀 Quick Setup

### 1. Environment Variables

Set these in n8n (Settings → Environment):

```bash
TTS_BASE_URL=https://your-pod-id-8888.proxy.runpod.net
TTS_API_KEY=cw_demo_12345
DEFAULT_VOICE_ID=naija_female
```

### 2. Create HTTP Header Auth Credential

1. Go to **Credentials** → **New**
2. Select **Header Auth**
3. Set:
   - **Name**: `TTS Bearer Auth`
   - **Name**: `Authorization`
   - **Value**: `Bearer {{$env.TTS_API_KEY}}`

> **Note**: The credential name must match exactly: `TTS Bearer Auth` (or update the workflow JSON)

### 3. Import Workflow

1. Go to **Workflows** → **Import from File**
2. Select `tts_workflow.json`
3. Activate the workflow

### 4. Get Webhook URL

After importing, click on the **Webhook Trigger** node to see your unique URL:

```
https://your-n8n.com/webhook/tts-trigger
```

## 🧪 Testing

### Test with curl

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria!", "voice_id": "naija_female"}' \
  --output test.mp3
```

### Test with form data

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -F "text=Hello from Nigeria!" \
  -F "voice_id=naija_female" \
  --output test.mp3
```

## 📊 Workflow Structure

```
┌─────────────────┐
│ Webhook Trigger │  ← POST /webhook/tts-trigger
│ (POST request)  │     Body: {text, voice_id}
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Set Parameters  │  ← Extract & validate input
│                 │     Fallback to DEFAULT_VOICE_ID
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ TTS HTTP        │  ← POST to TTS_BASE_URL/synthesize
│ Request         │     Auth: Bearer TTS_API_KEY
│                 │     Response: binary MP3
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Respond to      │  ← Return MP3 to webhook caller
│ Webhook         │     Content-Type: audio/mpeg
└─────────────────┘
```

## 🔧 Configuration Options

### Node: TTS HTTP Request

- **Timeout**: 30 seconds (adjust for long texts)
- **Retries**: 3 attempts with 1s interval
- **Response Format**: Binary file

### Node: Respond to Webhook

- **Response Mode**: Binary
- **Headers**:
  - `Content-Type: audio/mpeg`
  - `Content-Disposition: attachment; filename="synthesized.mp3"`

## 🎯 Use Cases

### 1. Direct TTS via Webhook

Accept HTTP requests and return MP3 directly.

```javascript
// JavaScript example
const response = await fetch('https://your-n8n.com/webhook/tts-trigger', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: 'Hello from Nigeria!',
    voice_id: 'naija_female'
  })
});

const audioBlob = await response.blob();
const audio = new Audio(URL.createObjectURL(audioBlob));
audio.play();
```

### 2. Integrate into Larger Workflows

Import `tts_http_node.json` as a standalone node into your existing workflows:

1. **Import** → `tts_http_node.json`
2. Connect it after any node that produces `{text, voice_id}` data
3. Use the binary output in downstream nodes (e.g., save to S3, send to Twilio)

### 3. Twilio Call Flow Integration

For Twilio voice calls:

1. Use the TTS node to generate audio
2. Save to cloud storage (S3, Supabase, etc.)
3. Call Twilio API to play the URL in an active call

Example follow-up nodes:
- **S3 Upload** → Upload MP3 to S3
- **HTTP Request** → POST to Twilio API with `play` URL

## 🐛 Troubleshooting

### "Cannot connect to TTS service"

- Verify `TTS_BASE_URL` is correct and accessible
- Check RunPod pod is running: `curl $TTS_BASE_URL/health`

### "Unauthorized" or 401 errors

- Verify `TTS_API_KEY` is correct
- Check credential name matches: `TTS Bearer Auth`
- Ensure Bearer format: `Bearer YOUR_KEY` (not just `YOUR_KEY`)

### "Timeout" errors

- Increase timeout in HTTP Request node (Options → Timeout)
- Check if text is too long (>500 words may take longer)
- Verify RunPod has sufficient GPU resources

### Binary response not working

- Ensure HTTP Request node has:
  - **Response Format**: `file` (not `json`)
  - **Output Property Name**: `data`
- Check "Respond to Webhook" node:
  - **Respond With**: `binary`

## 📚 Additional Resources

- [n8n HTTP Request Node Docs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/)
- [n8n Webhook Node Docs](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
- [n8n Environment Variables](https://docs.n8n.io/hosting/environment-variables/)

## 🎉 What's Next?

Once you have TTS working:

1. **Twilio Integration** - Connect to phone calls
2. **Storage** - Save generated MP3s to S3/Supabase
3. **Caching** - Cache common phrases to reduce API calls
4. **Queue** - Add Redis queue for high-volume processing
5. **Monitoring** - Track usage and errors

Need the Twilio call flow? See the main project README or ask!

