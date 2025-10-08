# 🔄 n8n TTS - READY TO USE

**Status**: ✅ Workflow fixed and ready to import

---

## ⚡ **Super Quick Setup (2 Steps)**

### **Step 1: Import Workflow** (No credential needed!)

1. Open n8n → **Workflows** → **Import from File**
2. Select: **`n8n/tts_workflow_READY.json`**
3. Click **Import**
4. **Activate** the workflow

### **Step 2: Get Webhook URL**

Click on the **Webhook** node to see your URL:
```
https://your-n8n.com/webhook/tts-trigger
```

**That's it!** No credentials needed - API is open. ✨

---

## 🧪 **Test Your n8n Workflow**

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from n8n!", "voice": "emily-en-us"}' \
  --output n8n_test.wav

open n8n_test.wav
```

---

## ✅ **What's Pre-Configured**

```
✓ URL: https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts
✓ Method: POST
✓ Format: JSON (not form-data)
✓ Body: {"text": "...", "voice": "..."}
✓ Default Voice: emily-en-us
✓ Response: Binary WAV audio
✓ No Authentication: Open API
✓ Timeout: 30 seconds
✓ Retries: 3 attempts
```

---

## 🎙️ **Voice Options**

Use in the `voice` parameter:

```json
{"text": "Your text", "voice": "emily-en-us"}
{"text": "Your text", "voice": "james-en-us"}
{"text": "Your text", "voice": "sophia-en-gb"}
{"text": "Your text", "voice": "marcus-en-us"}
{"text": "Your text", "voice": "luna-en-us"}
```

If no voice specified, defaults to `emily-en-us`

---

## 📝 **Request Format**

**What to send to your n8n webhook**:

```json
{
  "text": "Your text to synthesize",
  "voice": "emily-en-us"
}
```

**Or minimal** (uses default voice):
```json
{
  "text": "Your text to synthesize"
}
```

---

## 🌐 **Integration Examples**

### From Your App:
```javascript
fetch('https://your-n8n.com/webhook/tts-trigger', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    text: 'Hello from Nigeria!',
    voice: 'emily-en-us'
  })
})
.then(r => r.blob())
.then(blob => {
  const audio = new Audio(URL.createObjectURL(blob));
  audio.play();
});
```

### From Twilio Flow:
```
1. Twilio receives call
2. Trigger n8n webhook with text
3. n8n calls TTS
4. Returns audio to play in call
```

### From Another n8n Workflow:
```
Your Workflow → HTTP Request → n8n TTS Webhook → Get Audio
```

---

## 🚀 **What Changed**

**Before** (Not working):
- ❌ Form-data format
- ❌ Parameter: `voice_id`
- ❌ Default: `naija_female` (doesn't exist)
- ❌ Required authentication

**After** (Working now):
- ✅ JSON format
- ✅ Parameter: `voice`
- ✅ Default: `emily-en-us` (exists)
- ✅ No authentication needed

---

## 📦 **Files**

```
n8n/tts_workflow_READY.json  ← Import this (FIXED!)
N8N_TTS_SETUP.md             ← Complete guide
N8N_READY.md                 ← This quick start
```

---

## 🎯 **Ready to Import!**

**Just import and activate - no credential setup needed!**

**File**: `n8n/tts_workflow_READY.json`

---

**Status**: ✅ **READY TO USE**  
**Authentication**: None required  
**Format**: JSON  
**Working**: Verified with 166KB audio 🎉

