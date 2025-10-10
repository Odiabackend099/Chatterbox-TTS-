# 🚀 IMPORT & TEST n8n TTS Workflow - ONE-SHOT GUIDE

**Status**: ✅ PRODUCTION READY  
**File**: `n8n/COMPLETE_TTS_WORKFLOW.json`  
**Time to Setup**: 2 minutes

---

## 📋 **CHECKLIST - DO THIS IN ORDER**

### ✅ **Step 1: Import Workflow (30 seconds)**

1. Open n8n in browser
2. Click **"Workflows"** (left sidebar)
3. Click **"Import from File"** button (top-right)
4. Select: `/Users/odiadev/chatterbox-twilio-integration/n8n/COMPLETE_TTS_WORKFLOW.json`
5. Click **"Import"**

**Result**: You should see 4 connected nodes:
```
Webhook Trigger → Extract Parameters → Call TTS API → Return Audio
```

---

### ✅ **Step 2: Activate Workflow (5 seconds)**

1. Find the toggle switch at **top-right** of workflow editor
2. Click it to turn **ON** (should turn green and say "Active")

**IMPORTANT**: Workflow MUST be active for webhook to work!

---

### ✅ **Step 3: Get Webhook URL (10 seconds)**

1. Click on the **"Webhook Trigger"** node (first node)
2. Look at the right panel under "Webhook URLs"
3. Copy the **Production URL**

**It will look like:**
- Local: `http://localhost:5678/webhook/tts-trigger`
- Cloud: `https://your-instance.app.n8n.cloud/webhook/tts-trigger`

---

### ✅ **Step 4: Test It (30 seconds)**

Open terminal and run:

```bash
cd /Users/odiadev/chatterbox-twilio-integration

# Replace YOUR_WEBHOOK_URL with the URL from Step 3
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria! This is a test.", "voice": "emily-en-us"}' \
  --output test_n8n_output.mp3
```

**Expected Result:**
```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  166k  100  166k    0    89  55k    29  0:00:03  0:00:03 --:--:-- 55k
```

**File created:** `test_n8n_output.mp3` (should be ~160-170KB)

---

### ✅ **Step 5: Verify Audio (10 seconds)**

```bash
# Play the audio (Mac)
afplay test_n8n_output.mp3

# Or open in Finder
open test_n8n_output.mp3
```

**You should hear:** "Hello from Nigeria! This is a test."

---

## 🎯 **ONE-COMMAND TEST**

Save your webhook URL and use this quick test:

```bash
# Set your webhook URL once
export N8N_WEBHOOK_URL="YOUR_WEBHOOK_URL_HERE"

# Quick test anytime
curl -X POST "$N8N_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "Quick test", "voice": "emily-en-us"}' \
  --output quick_test.mp3 && afplay quick_test.mp3
```

---

## 🔧 **WORKFLOW CONFIGURATION**

### **What's Inside:**

| Node | Purpose | Configuration |
|------|---------|---------------|
| **Webhook Trigger** | Receives POST requests | Path: `/webhook/tts-trigger` |
| **Extract Parameters** | Validates input | Extracts `text` & `voice` with fallbacks |
| **Call TTS API** | Generates audio | URL: `https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts`<br>Timeout: 30s<br>Retries: 3 |
| **Return Audio** | Sends MP3 back | Content-Type: `audio/mpeg`<br>CORS enabled |

### **Supported Parameters:**

```json
{
  "text": "Your text here",           // Required (fallback: "Hello from Nigeria!")
  "voice": "emily-en-us"              // Optional (fallback: "emily-en-us")
}
```

### **Available Voices:**
- `emily-en-us` (Female, US English) ✅ Default
- `james-en-us` (Male, US English)
- `sophia-en-gb` (Female, British English)
- `marcus-en-us` (Male, US English)
- `luna-en-us` (Female, US English)

---

## 🐛 **TROUBLESHOOTING**

### ❌ **"404 Not Found"**

**Cause**: Workflow is not activated OR wrong URL

**Fix**:
```bash
# 1. Check workflow is ACTIVE (green toggle)
# 2. Verify webhook URL from the Webhook Trigger node
# 3. Ensure path is /webhook/tts-trigger
```

---

### ❌ **"Connection refused"**

**Cause**: n8n is not running

**Fix**:
```bash
# Check if n8n is running
curl http://localhost:5678/

# If Docker:
docker ps | grep n8n

# If not running, start it:
docker run -it --rm -p 5678:5678 n8nio/n8n
```

---

### ❌ **"Timeout" or takes too long**

**Cause**: RunPod TTS service might be cold-starting

**Fix**:
```bash
# 1. Test TTS service directly first:
curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/health

# Expected: {"status": "healthy", "model_loaded": true}

# 2. If service is down, wake it up:
curl -X POST "https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Wake up test", "voice": "emily-en-us"}' \
  --output wake_test.mp3

# 3. Try n8n workflow again
```

---

### ❌ **"File is empty" or 0 bytes**

**Cause**: TTS API returned an error

**Fix**:
```bash
# Check n8n execution logs:
# 1. Go to n8n → "Executions" (left sidebar)
# 2. Click on the failed execution
# 3. Look at "Call TTS API" node for error details

# Common errors:
# - "Invalid voice": Check voice name spelling
# - "Text too long": Max ~5000 characters
# - "Service unavailable": RunPod pod might be stopped
```

---

## 🧪 **ADVANCED TESTING**

### Test all voices:

```bash
for voice in emily-en-us james-en-us sophia-en-gb marcus-en-us luna-en-us; do
  echo "Testing voice: $voice"
  curl -X POST "$N8N_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"This is the $voice voice\", \"voice\": \"$voice\"}" \
    --output "test_${voice}.mp3"
  echo "Created: test_${voice}.mp3"
done
```

### Test long text:

```bash
curl -X POST "$N8N_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d @- --output long_test.mp3 <<'EOF'
{
  "text": "Welcome to Chatterbox AI. This is a longer text to test how well the text-to-speech system handles extended content. The service should generate natural-sounding audio that flows smoothly across multiple sentences. We support multiple voices and accents to suit different use cases. Thank you for testing our system!",
  "voice": "emily-en-us"
}
EOF
```

---

## 📊 **PERFORMANCE EXPECTATIONS**

| Text Length | Expected Time | File Size |
|-------------|---------------|-----------|
| 10 words | 2-3 seconds | ~50KB |
| 50 words | 3-5 seconds | ~150KB |
| 100 words | 5-8 seconds | ~300KB |
| 500 words | 15-25 seconds | ~1.5MB |

---

## 🎯 **NEXT STEPS**

Once this works:

### **For Web App Integration:**
```javascript
// Frontend code example
async function generateSpeech(text, voice = 'emily-en-us') {
  const response = await fetch('YOUR_N8N_WEBHOOK_URL', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text, voice })
  });
  
  const audioBlob = await response.blob();
  const audio = new Audio(URL.createObjectURL(audioBlob));
  audio.play();
}

// Usage
generateSpeech('Hello from Nigeria!', 'emily-en-us');
```

### **For Twilio Integration:**
```bash
# Save webhook URL as environment variable
export TWILIO_TTS_WEBHOOK="YOUR_N8N_WEBHOOK_URL"

# Use in Twilio flows
# See: /Users/odiadev/chatterbox-twilio-integration/TWILIO_INTEGRATION.md
```

### **For WhatsApp/Telegram:**
```bash
# Use n8n's WhatsApp/Telegram nodes
# Connect them before "Extract Parameters" node
# The workflow will handle the rest!
```

---

## ✅ **SUCCESS CRITERIA**

You're ready to go when:

- [ ] Workflow imported successfully
- [ ] Workflow is ACTIVE (green toggle)
- [ ] Webhook URL copied
- [ ] Test curl command returns MP3 file
- [ ] Audio file plays correctly
- [ ] File size is reasonable (~150KB for short text)

---

## 🔐 **SECURITY NOTES**

**Current Setup**: No authentication (open webhook)

**For Production**:
1. Add API key authentication in webhook node
2. Use n8n's built-in authentication
3. Whitelist IPs if needed
4. Rate limit in n8n settings

**To add auth:**
```bash
# Add header to curl:
-H "Authorization: Bearer YOUR_SECRET_KEY"

# Update webhook node settings:
# Options → Authentication → Header Auth
```

---

**Status**: ✅ **READY TO IMPORT AND TEST**  
**Created**: October 9, 2025  
**Workflow File**: `n8n/COMPLETE_TTS_WORKFLOW.json`  
**TTS Service**: `https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts`

---

**JUST DO IT:** Import → Activate → Copy URL → Test → DONE! 🚀

