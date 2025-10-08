# 🔄 n8n TTS Integration - Ready to Use

**Your Configuration**: All set up for pod `a288y3vpbfxwkk`

---

## ⚡ **2-Step Setup**

### **Step 1: Create Credential in n8n**

Go to **Credentials** → **New** → **Header Auth**

```
Credential Name: TTS Bearer Auth

Header Name:
Authorization

Header Value:
Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

Click **Save**

---

### **Step 2: Import Workflow**

1. Go to **Workflows** → **Import from File**
2. Select: **`n8n/tts_workflow_READY.json`**
3. Click **Import**
4. **Activate** the workflow

**Done!** ✨

---

## 🌐 **Your n8n Webhook URL**

After importing, click on the **Webhook** node to get your URL:

```
https://your-n8n.com/webhook/tts-trigger
```

---

## 🧪 **Test Your n8n Workflow**

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from n8n!", "voice": "emily-en-us"}' \
  --output n8n_test.wav

# Play it
open n8n_test.wav
```

---

## 📋 **Workflow Configuration**

**Pre-configured in `tts_workflow_READY.json`**:

```
✓ Webhook Trigger: POST /webhook/tts-trigger
✓ TTS URL: https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts
✓ Default Voice: emily-en-us
✓ Response: Binary WAV audio
✓ Timeout: 30 seconds
✓ Retries: 3 attempts
```

---

## 🎙️ **Voice Options**

Available voices (use in `voice` parameter):

- `emily-en-us` - Female, US English (default)
- `james-en-us` - Male, US English
- `sophia-en-gb` - Female, British English
- `marcus-en-us` - Male, US English
- `luna-en-us` - Female, US English

---

## 📝 **API Request Format**

**What n8n sends to your TTS**:

```json
POST https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts
Content-Type: application/json

{
  "text": "Your text here",
  "voice": "emily-en-us"
}
```

**Response**: Binary WAV audio file

---

## 🔧 **n8n Workflow Structure**

```
┌──────────────┐
│   Webhook    │ ← POST with {text, voice}
│   Trigger    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     Set      │ ← Extract & validate params
│  Parameters  │   Default: emily-en-us
└──────┬───────┘
       │
       ▼
┌──────────────┐
│     HTTP     │ ← POST to TTS API
│   Request    │   Auth: Bearer token
│              │   Response: WAV audio
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Respond    │ ← Return WAV to caller
│ to Webhook   │   Content-Type: audio/x-wav
└──────────────┘
```

---

## 🎯 **Usage Examples**

### JavaScript/TypeScript:
```javascript
const response = await fetch('https://your-n8n.com/webhook/tts-trigger', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: 'Hello from Nigeria!',
    voice: 'emily-en-us'
  })
});

const audioBlob = await response.blob();
const audio = new Audio(URL.createObjectURL(audioBlob));
audio.play();
```

### Python:
```python
import requests

response = requests.post(
    'https://your-n8n.com/webhook/tts-trigger',
    json={'text': 'Hello from Nigeria!', 'voice': 'emily-en-us'}
)

with open('output.wav', 'wb') as f:
    f.write(response.content)
```

### cURL:
```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello!", "voice": "emily-en-us"}' \
  --output output.wav
```

---

## 🔐 **For n8n Free Tier** (No Environment Variables)

If you can't set environment variables in n8n:

**Credential**:
```
Name: TTS Bearer Auth
Header Name: Authorization
Header Value: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```
*(Hardcode the actual key)*

**HTTP Request Node URL** (already set):
```
https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts
```

---

## 🐛 **Troubleshooting**

### "Credential not found"

**Fix**: Make sure credential is named exactly `TTS Bearer Auth`

### "Cannot connect to TTS service"

**Fix**: 
1. Check RunPod service is running
2. Test: `curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/health`

### "Response is not binary"

**Fix**: 
- Check voice name is correct (use `emily-en-us`, not `naija_female`)
- Verify HTTP Request node has Response Format: `file`

### Wrong voice error

**Fix**: Use these voice names:
- ✅ `emily-en-us`
- ❌ NOT `naija_female` (doesn't exist on your service)

---

## 📦 **Available n8n Files**

```
n8n/
├── tts_workflow_READY.json     ← Import this! (Pre-configured)
├── tts_workflow_free_tier.json ← Free tier version
├── tts_http_node.json          ← Standalone node
├── READY_TO_GO.md              ← Quick start
└── IMPORT_GUIDE.md             ← Detailed guide
```

---

## ✅ **Pre-configured Settings**

In `tts_workflow_READY.json`:

- ✅ URL: `https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts`
- ✅ Method: POST
- ✅ Body: JSON format
- ✅ Default voice: `emily-en-us`
- ✅ Timeout: 30 seconds
- ✅ Retries: 3 attempts
- ✅ Response: Binary audio

**Just import and create credential!**

---

## 🎉 **n8n Quick Start**

1. **Create credential** (Step 1 above) - 1 minute
2. **Import workflow** (Step 2 above) - 30 seconds  
3. **Test webhook** - 30 seconds

**Total time**: ~2 minutes ⚡

---

## 📞 **Advanced: Twilio + n8n Flow**

```
Phone Call → Twilio → n8n Webhook → TTS → Return Audio
```

See `TWILIO_INTEGRATION.md` for complete setup.

---

**Status**: ✅ **Ready to Import**  
**Your TTS**: https://a288y3vpbfxwkk-8888.proxy.runpod.net  
**Workflow File**: `n8n/tts_workflow_READY.json`

**Import now!** 🚀

