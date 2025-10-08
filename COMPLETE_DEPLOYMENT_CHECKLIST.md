# ✅ Complete Deployment Checklist

**Follow this exact order for smooth deployment**

---

## Phase 1: Deploy to RunPod (2 minutes)

### Step 1.1: SSH to RunPod
```bash
ssh a288y3vpbfxwkk-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519
```

### Step 1.2: Run Deployment Script
```bash
curl -sSL https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh | bash
```

### Step 1.3: Verify Deployment
```bash
# On RunPod
curl http://localhost:8004/health
```

**Expected**: `{"status": "healthy", ...}`

---

## Phase 2: Test from Local Machine (1 minute)

### Step 2.1: Test Health Endpoint
```bash
# On your Mac
curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/health
```

### Step 2.2: Test TTS Generation
```bash
# On your Mac, in project directory
./test_scripts/quick_test.sh
```

**Expected**: Audio file generated and plays automatically

---

## Phase 3: Configure Twilio (1 minute)

### Step 3.1: Update Voice Webhook

1. Go to: https://console.twilio.com/us1/develop/phone-numbers/manage/incoming
2. Click: **(218) 400-3410**
3. Scroll to **Voice Configuration**
4. Change:
   - **A call comes in**: `https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice`
   - **HTTP**: POST
5. Click **Save configuration**

---

## Phase 4: Test Complete System (2 minutes)

### Step 4.1: Test Voice Call

Call your Twilio number from your phone:
```
📞 (218) 400-3410
```

You should hear:
> "Welcome to Chatterbox Voice Service. Press 1 for English..."

### Step 4.2: Test Each Option

- Press **1**: English greeting
- Press **2**: Pidgin greeting  
- Press **3**: Demo message

---

## Phase 5: Import n8n Workflow (Optional, 2 minutes)

### Step 5.1: Setup n8n Environment

In n8n (Settings → Environments):
```
TTS_BASE_URL=https://a288y3vpbfxwkk-8888.proxy.runpod.net
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
DEFAULT_VOICE_ID=naija_female
```

### Step 5.2: Create Credential

Credentials → New → Header Auth:
```
Name: TTS Bearer Auth
Header Name: Authorization
Header Value: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

### Step 5.3: Import Workflow

Workflows → Import → Select `n8n/tts_workflow_READY.json`

### Step 5.4: Test n8n

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from n8n!"}' \
  --output n8n_test.mp3
```

---

## 📊 Final Verification

### ✅ System Status Check

- [ ] **RunPod TTS**: `curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/health` → 200 OK
- [ ] **Local TTS Test**: `./test_scripts/quick_test.sh` → Audio plays
- [ ] **Twilio Voice**: Call (218) 400-3410 → Greeting plays
- [ ] **Twilio Options**: Press 1, 2, 3 → Different messages
- [ ] **n8n Workflow** (optional): Import successful
- [ ] **n8n Test** (optional): Webhook returns MP3

---

## 🎯 Your Complete Stack

```
┌─────────────────────────────────────────┐
│  Phone Call: (218) 400-3410            │
│  ↓                                      │
│  Twilio → RunPod TTS → Audio           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  n8n Webhook → RunPod TTS → MP3        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Direct API → RunPod TTS → Audio       │
└─────────────────────────────────────────┘
```

**All integrated and working!** 🎉

---

## 📞 Your Live URLs

```
TTS Service:    https://a288y3vpbfxwkk-8888.proxy.runpod.net
TTS Health:     https://a288y3vpbfxwkk-8888.proxy.runpod.net/health
Twilio Webhook: https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
Twilio Number:  (218) 400-3410 / +12184003410
```

---

## 🚀 Start Deployment Now!

**Copy and run**:
```bash
ssh a288y3vpbfxwkk-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519
```

Then:
```bash
curl -sSL https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh | bash
```

**Total time**: ~5-7 minutes for everything! ⚡

