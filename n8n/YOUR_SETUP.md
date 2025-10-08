# 🎯 YOUR PERSONALIZED n8n SETUP

**Everything configured for your RunPod TTS service!**

---

## ✅ Your Configuration

### RunPod Details
```
Pod ID:  bh1ki2a4eg8ufz
URL:     https://bh1ki2a4eg8ufz-8004.proxy.runpod.net
```

### API Key (Production Key #1)
```
cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

---

## 🚀 Super Quick Setup (2 Steps)

### Step 1: Create Credential in n8n (1 minute)

1. Go to **Credentials** → **New Credential**
2. Select **Header Auth**
3. Copy/paste exactly:

```
Name: 
TTS Bearer Auth

Header Name:
Authorization

Header Value:
Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

4. Click **Save**

---

### Step 2: Import Workflow (30 seconds)

1. Go to **Workflows** → **Import from File**
2. Select **`tts_workflow_READY.json`**
3. Click **Import**
4. **Activate** the workflow

**✨ That's it!** Your RunPod URL is already configured in the workflow.

---

## 🧪 Test Your Setup

### Get Webhook URL

1. Click on the **Webhook** node in your workflow
2. Copy the **Production URL**
   - Example: `https://your-n8n.com/webhook/tts-trigger`

### Run Test Command

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria!", "voice_id": "naija_female"}' \
  --output test.mp3
```

**Expected Result**: A valid `test.mp3` file containing the synthesized speech! 🎵

---

## 🔍 Test RunPod Directly

First, verify your RunPod TTS is running:

```bash
# Health check
curl https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/health

# Direct TTS test
curl -X POST "https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/synthesize" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Hello from Nigeria!" \
  -F "voice_id=naija_female" \
  --output direct_test.mp3
```

---

## 📋 Complete Configuration Reference

### For n8n Credential:
```
Type: Header Auth
Name: TTS Bearer Auth
Header Name: Authorization
Header Value: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

### For HTTP Request Node (already configured):
```
URL: https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/synthesize
Method: POST
Body Type: multipart-form-data
Parameters:
  - text: {{ $json.text }}
  - voice_id: {{ $json.voice_id }}
```

### For Direct API Calls:
```bash
# With curl
curl -X POST "https://sbwpfh7exfn63d-8888.proxy.runpod.net/synthesize" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Your text here" \
  -F "voice_id=naija_female" \
  --output output.mp3
```

### For .env.tts (local testing):
```bash
TTS_BASE_URL=https://bh1ki2a4eg8ufz-8004.proxy.runpod.net
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
DEFAULT_VOICE_ID=naija_female
```

---

## 📁 Files to Use

| File | Status | Purpose |
|------|--------|---------|
| **`tts_workflow_READY.json`** | ✅ **USE THIS** | Your personalized workflow |
| `YOUR_SETUP.md` | 📖 This file | Your configuration reference |
| `START_HERE_FREE_TIER.md` | 📚 General guide | For reference |
| `FREE_TIER_SETUP.md` | 📚 Detailed guide | For troubleshooting |

---

## ✅ Pre-configured Settings

What's already set up in `tts_workflow_READY.json`:

- ✅ RunPod URL: `https://sbwpfh7exfn63d-8888.proxy.runpod.net/synthesize`
- ✅ Default voice: `naija_female`
- ✅ Timeout: 30 seconds
- ✅ Retries: 3 attempts
- ✅ Response format: Binary MP3
- ✅ Webhook path: `/tts-trigger`

**You only need to**: Create the credential and import!

---

## 🎯 Quick Checklist

- [ ] RunPod TTS pod is running (test with health check)
- [ ] Created `TTS Bearer Auth` credential in n8n
- [ ] Imported `tts_workflow_READY.json`
- [ ] Activated workflow
- [ ] Got webhook URL from Webhook node
- [ ] Tested with curl command
- [ ] Received valid MP3 file

**Time Required**: ~2-3 minutes total! ⚡

---

## 🐛 Troubleshooting

### "Cannot connect" or timeout

**Check if your RunPod pod is running:**
```bash
curl https://sbwpfh7exfn63d-8888.proxy.runpod.net/health
```

**Expected**: `{"status": "healthy", ...}`

If pod is stopped, start it in RunPod dashboard.

### "401 Unauthorized"

**Check your credential has**:
- Header Name: `Authorization`
- Header Value: `Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU`

⚠️ Must include `Bearer ` at the start!

### "Credential not found"

**Make sure**:
- Credential name is exactly: `TTS Bearer Auth`
- Credential is saved
- HTTP Request node is linked to the credential

### Audio quality issues

**Try different voices**:
```json
{"text": "Test", "voice_id": "naija_male"}
{"text": "Test", "voice_id": "naija_female"}
```

---

## 🔐 Security Notes

✅ **Good practices**:
- API key is encrypted in n8n credential storage
- Don't share workflow screenshots showing credential details
- Use this key (Key #1) exclusively for n8n
- Keep other keys for different services

⚠️ **If key is compromised**:
You have 4 backup keys in `generated_api_keys.txt`:
- Key #2: `cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI`
- Key #3: `cw_live_9rSEdn-4tfW-blbihfBsm08S1Zggs0OaJuLbCFXGKd8`
- Key #4: `cw_live_-_MZyOhDPDB4PWBS3tfc-4mqONpa1dXhn6XjeL4aOlk`
- Key #5: `cw_live_HpqXxNWGY6N4EO5ZP4nS6Vqo1shGUS-63HTIZh_EWVY`

---

## 📊 Usage Examples

### Simple Text
```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -d '{"text": "Hello!"}' \
  -H "Content-Type: application/json" \
  --output hello.mp3
```

### With Voice Selection
```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -d '{"text": "Welcome!", "voice_id": "naija_male"}' \
  -H "Content-Type: application/json" \
  --output welcome.mp3
```

### Long Text
```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Welcome to Chatterbox TTS service. We provide high-quality Nigerian accented text-to-speech.",
    "voice_id": "naija_female"
  }' \
  --output long_text.mp3
```

### Form Data (Alternative)
```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -F "text=Hello Nigeria!" \
  -F "voice_id=naija_female" \
  --output form_test.mp3
```

---

## 🎉 What's Next?

Once your workflow is working:

1. **Integrate with Twilio** - Add phone call support
2. **Add storage** - Save MP3s to S3/Supabase
3. **Create variations** - Different workflows for different use cases
4. **Monitor usage** - Track API calls and costs
5. **Scale up** - Add more RunPod pods if needed

---

## 📞 Twilio Integration Preview

To use with Twilio:

```
Twilio Call → Webhook → Your Workflow → TTS → S3 Upload → Twilio Play API
```

See main `TTS_INTEGRATION_SETUP.md` for complete Twilio guide.

---

**Status**: ✅ **100% Ready to Use!**  
**Your Pod**: `sbwpfh7exfn63d`  
**Your API Key**: Key #1 (configured)  
**Setup Time**: ~2 minutes  
**Next Step**: Create credential → Import workflow → Test! 🚀

