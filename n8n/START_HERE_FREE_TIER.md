# 🆓 n8n Free Tier - Quick Start

**For users without environment variable access**

---

## ⚡ 3-Step Setup

### Step 1: Create Credential (2 minutes)

1. In n8n, go to **Credentials** → **New**
2. Select **Header Auth**
3. Fill in:

```
Name: TTS Bearer Auth

Header Name:
Authorization

Header Value:
Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

4. Click **Save**

✅ **Done!** Your API key is securely stored.

---

### Step 2: Import Workflow (1 minute)

1. In n8n, go to **Workflows** → **Import from File**
2. Select **`tts_workflow_free_tier.json`** from this folder
3. Click **Import**

---

### Step 3: Edit URL (30 seconds)

1. Click on the **HTTP Request** node (you'll see a note)
2. Change the URL from:
   ```
   https://YOUR-POD-ID-8888.proxy.runpod.net/api/tts
   ```
   
   To your actual RunPod URL (example):
   ```
   https://abc123def456-8888.proxy.runpod.net/api/tts
   ```

3. Click **Save**
4. Activate the workflow

---

## 🧪 Test It

Get your webhook URL from the **Webhook** node, then run:

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria!"}' \
  --output test.mp3
```

✅ **Success**: You should get a valid `test.mp3` file!

---

## 📋 Your API Key

```
cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

This is Key #1 from your `generated_api_keys.txt` file.

---

## 📁 Files to Use

| File | Use This For |
|------|--------------|
| `tts_workflow_free_tier.json` | ✅ Import this (free tier compatible) |
| `tts_workflow.json` | ❌ Skip this (requires environment variables) |
| `FREE_TIER_SETUP.md` | 📖 Detailed guide |

---

## ❓ Need Your RunPod URL?

Your RunPod TTS URL looks like:
```
https://YOUR-POD-ID-8888.proxy.runpod.net
```

To find it:
1. Go to RunPod dashboard
2. Find your TTS pod
3. Copy the proxy URL (port 8888)

Example:
```
https://abc123def456-8888.proxy.runpod.net
```

---

## 🐛 Troubleshooting

**"401 Unauthorized"**
→ Check credential has `Bearer ` before the API key

**"Cannot connect"**
→ Verify your RunPod URL is correct and pod is running

**"Credential not found"**
→ Make sure credential is named exactly `TTS Bearer Auth`

---

## ✅ Quick Checklist

- [ ] Created credential with API key (Step 1)
- [ ] Imported `tts_workflow_free_tier.json` (Step 2)
- [ ] Updated HTTP Request URL with your RunPod URL (Step 3)
- [ ] Activated workflow
- [ ] Tested with curl command
- [ ] Got valid MP3 file

---

**Time to Complete**: ~5 minutes  
**Difficulty**: 🟢 Easy  
**Requirements**: n8n account (free tier OK!)

---

**Next**: Once it works, you can customize the workflow or integrate with Twilio! 🎉

