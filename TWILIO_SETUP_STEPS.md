# 📞 Twilio Configuration - Step by Step

**Your Phone Number**: (218) 400-3410  
**Twilio Number Format**: +12184003410

---

## 🎯 Quick Setup (Choose One)

### Option A: Production Setup (After RunPod Deployment)

**Prerequisites**: TTS service deployed on RunPod

1. Go to: https://console.twilio.com/us1/develop/phone-numbers/manage/incoming
2. Click on: **(218) 400-3410**
3. Scroll to **Voice Configuration**
4. Update these fields:

```
Configure with: Webhook

A call comes in:
  URL: https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
  HTTP: POST

Primary handler fails:
  URL: (leave empty or same as above)
  HTTP: POST
```

5. Click **Save configuration**

---

### Option B: Local Testing with ngrok

**For testing before deploying to RunPod**

#### Step 1: Start Local Server

```bash
# Terminal 1: Start Twilio integration server
source .env.master
python scripts/twilio_integration.py
```

#### Step 2: Start ngrok

```bash
# Terminal 2: Expose local server
ngrok http 8080
```

You'll see output like:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:8080
```

#### Step 3: Configure Twilio

Use the ngrok URL in Twilio:

```
A call comes in:
  URL: https://abc123.ngrok.io/twilio/voice
  HTTP: POST
```

---

## 📋 Complete Twilio Configuration

### Voice Configuration Settings

| Field | Value |
|-------|-------|
| **Configure with** | Webhook |
| **A call comes in** | `https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice` |
| **HTTP Method** | POST |
| **Primary handler fails** | (optional) Same URL or leave empty |
| **Call status changes** | (optional) `https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/status` |

### Messaging Configuration (Optional)

| Field | Value |
|-------|-------|
| **Configure with** | Webhook |
| **A message comes in** | `https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/sms` |
| **HTTP Method** | POST |

---

## ✅ Verify Configuration

After saving, test it:

### Test 1: Call Your Twilio Number

```bash
# From your phone, call: (218) 400-3410
# You should hear: "Welcome to Chatterbox Voice Service..."
```

### Test 2: Programmatic Test

```bash
# Install Twilio CLI
npm install -g twilio-cli

# Login
twilio login

# Make test call
twilio api:core:calls:create \
  --from=+12184003410 \
  --to=YOUR_PHONE_NUMBER \
  --url=https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
```

---

## 🔧 Current Settings (Before Changes)

Your current configuration:
```
Voice webhook: https://demo.twilio.com/welcome/voice/
SMS webhook:   https://demo.twilio.com/welcome/sms/reply/
```

These are Twilio demo URLs. You need to replace them.

---

## 🚨 Important Notes

### A2P 10DLC Registration

You see this warning:
> "A2P 10DLC registration required for US messaging"

**This is only for SMS**. If you're only using voice calls, you can ignore it.

If you want to send SMS:
1. Click "Initiate A2P 10DLC registration"
2. Complete the registration process
3. This is required for SMS in the US

### Emergency Address

You see this warning:
> "Please add an emergency address"

**For voice calls with TTS, this is optional** but recommended:
1. Click "Add emergency address"
2. Enter your business address
3. Accept terms and conditions

---

## 📝 Step-by-Step Configuration

### 1. Navigate to Phone Number

```
Twilio Console → Phone Numbers → Manage → Active numbers → (218) 400-3410
```

### 2. Update Voice Configuration

Scroll to **Voice Configuration** section:

**Before**:
```
A call comes in: https://demo.twilio.com/welcome/voice/
```

**After**:
```
A call comes in: https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
HTTP POST ✓
```

### 3. (Optional) Update Messaging

Scroll to **Messaging Configuration** section:

**Before**:
```
A message comes in: https://demo.twilio.com/welcome/sms/reply/
```

**After**:
```
A message comes in: https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/sms
HTTP POST ✓
```

### 4. Save

Click **"Save configuration"** at the bottom

---

## 🧪 Test Your Setup

### Test Voice Call

**Method 1: Call the number**
```
1. Call (218) 400-3410 from your phone
2. You should hear: "Welcome to Chatterbox Voice Service"
3. Follow the prompts (Press 1, 2, or 3)
```

**Method 2: Use Twilio CLI**
```bash
twilio api:core:calls:create \
  --from=+12184003410 \
  --to=+1YOUR_PHONE \
  --url=https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
```

### Test SMS (if configured)

```bash
# Send test SMS
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
  -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
  -d "From=+12184003410" \
  -d "To=+1YOUR_PHONE" \
  -d "Body=Test from Chatterbox TTS"
```

---

## 🐛 Troubleshooting

### "Webhook returned 404"

**Problem**: Service not found at URL

**Check**:
1. Is RunPod service running? `curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/health`
2. Is the URL correct? Should end with `/twilio/voice`
3. Check RunPod logs

### "Webhook returned 500"

**Problem**: Server error

**Check**:
1. View logs on RunPod: `tail -f logs/tts.log`
2. Check if TTS service is running properly
3. Verify environment variables are set

### "No response from webhook"

**Problem**: Can't reach server

**Check**:
1. Is RunPod pod running?
2. Is port 8004 exposed?
3. Test directly: `curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/health`

---

## 📊 Webhook Flow

```
Incoming Call
    ↓
(218) 400-3410
    ↓
Twilio receives call
    ↓
Twilio calls your webhook:
https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
    ↓
Your server responds with TwiML
    ↓
Twilio executes TwiML
    ↓
Caller hears your TTS audio
```

---

## 🎯 Production Checklist

Before going live:

- [ ] RunPod TTS service deployed and running
- [ ] Health endpoint returns 200: `curl .../health`
- [ ] Twilio webhook URL updated
- [ ] Configuration saved in Twilio
- [ ] Test call successful
- [ ] Audio quality is good
- [ ] (Optional) Emergency address added
- [ ] (Optional) A2P 10DLC registered (for SMS)

---

## 🔄 Switching Between Testing and Production

### Testing (ngrok)
```
URL: https://YOUR_NGROK_ID.ngrok.io/twilio/voice
```

### Production (RunPod)
```
URL: https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
```

Just update the URL in Twilio console and save.

---

## 📞 Your Complete Setup

Once configured:

```
Twilio Number:  (218) 400-3410
Voice Webhook:  https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
TTS Service:    https://a288y3vpbfxwkk-8888.proxy.runpod.net
Status:         Ready for calls! 🎉
```

---

**Next**: Deploy to RunPod, then update these settings! 🚀

