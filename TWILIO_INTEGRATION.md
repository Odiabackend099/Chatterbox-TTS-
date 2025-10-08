# 📞 Twilio + TTS Integration Guide

Complete integration between Twilio voice calls and your Chatterbox TTS service.

---

## 🔑 Your Twilio Credentials

```
Account SID:    (See .env.master or env.twilio.example)
Auth Token:     (See .env.master or env.twilio.example)
Phone Number:   (See .env.master or env.twilio.example)
```

⚠️ **Security**: Credentials are in `.env.master` - **never commit to git**!

---

## 🚀 Quick Start

### 1. Test Your Twilio Setup

```bash
# Load credentials
source .env.twilio

# Run tests
./test_twilio.sh
```

###  2. Start Integration Server

```bash
# Install dependencies
pip install twilio fastapi uvicorn httpx

# Start the server
python scripts/twilio_integration.py
```

### 3. Configure Twilio Webhooks

1. Go to: https://console.twilio.com/us1/develop/phone-numbers/manage/incoming
2. Click on your number: **YOUR_TWILIO_NUMBER**
3. Under **Voice Configuration**:
   - **A CALL COMES IN**: Webhook
   - **URL**: `https://your-server.com/twilio/voice`
   - **HTTP**: POST

---

## 📊 Integration Architecture

```
┌─────────────────┐
│  Caller         │
│  Dials          │
│  YOUR_TWILIO_NUMBER   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Twilio         │
│  Receives Call  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Your Webhook   │  ← /twilio/voice
│  (FastAPI)      │
└────────┬────────┘
         │
         ├──→ Immediate Response (TwiML)
         │    "Please wait..."
         │
         ├──→ Generate TTS (Async)
         │    Call RunPod TTS API
         │
         ├──→ Upload Audio
         │    S3/Supabase/CDN
         │
         └──→ Update Call
              Play generated audio
```

---

## 🎯 Use Cases

### 1. Simple IVR Menu

```python
from twilio.twiml.voice_response import VoiceResponse, Gather

response = VoiceResponse()
gather = Gather(num_digits=1, action='/twilio/gather')
gather.say("Press 1 for English. Press 2 for Pidgin.")
response.append(gather)
```

### 2. Text-to-Speech Playback

```python
# Generate TTS
audio_bytes = await generate_tts("Welcome to Chatterbox!", "naija_female")

# Upload to storage
audio_url = await upload_to_s3(audio_bytes)

# Play in call
response = VoiceResponse()
response.play(audio_url)
```

### 3. Dynamic Messages

```python
# Get user data from database
user = get_user(caller_number)

# Personalized message
text = f"Hello {user.name}, your balance is {user.balance} naira."
audio_bytes = await generate_tts(text, "naija_female")
```

---

## 🔧 Configuration Files

### `.env.twilio` (Created)

```bash
TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=YOUR_TWILIO_AUTH_TOKEN
TWILIO_PHONE_NUMBER=YOUR_TWILIO_NUMBER
TTS_BASE_URL=https://a288y3vpbfxwkk-8888.proxy.runpod.net
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

### `config/config.yaml` (Update)

```yaml
twilio:
  account_sid: ""  # Set via TWILIO_ACCOUNT_SID env var
  auth_token: ""   # Set via TWILIO_AUTH_TOKEN env var
  phone_number: "YOUR_TWILIO_NUMBER"
```

---

## 📝 Example Workflows

### Basic Call Handler

```python
@app.post("/twilio/voice")
async def handle_call(From: str = Form(...), CallSid: str = Form(...)):
    response = VoiceResponse()
    
    # Greet caller
    response.say("Welcome to Chatterbox!")
    
    # Play TTS audio
    # (In production, generate and upload first)
    response.play("https://your-cdn.com/welcome.mp3")
    
    # Hangup
    response.hangup()
    
    return str(response)
```

### Interactive Menu

```python
@app.post("/twilio/gather")
async def handle_input(Digits: str = Form(...)):
    response = VoiceResponse()
    
    if Digits == '1':
        text = "You selected English. How can we help you today?"
        voice = "naija_female"
    elif Digits == '2':
        text = "You select Pidgin. Wetin we fit do for you?"
        voice = "naija_male"
    else:
        response.say("Invalid option.")
        response.redirect('/twilio/voice')
        return str(response)
    
    # Generate TTS
    audio_bytes = await generate_tts(text, voice)
    audio_url = await upload_to_storage(audio_bytes)
    
    response.play(audio_url)
    return str(response)
```

### Async TTS with Live Call Update

```python
@app.post("/twilio/voice")
async def handle_call(CallSid: str = Form(...)):
    # Respond immediately
    response = VoiceResponse()
    response.say("Please wait while we prepare your message...")
    
    # Generate TTS in background
    asyncio.create_task(generate_and_play(CallSid))
    
    return str(response)

async def generate_and_play(call_sid: str):
    # Generate TTS
    audio_bytes = await generate_tts("Your custom message", "naija_female")
    
    # Upload
    audio_url = await upload_to_s3(audio_bytes)
    
    # Update call
    twilio_client.calls(call_sid).update(
        url=f"https://your-server.com/play?url={audio_url}"
    )
```

---

## 🌐 Deployment Options

### Option 1: ngrok (Testing)

```bash
# Start your server
python scripts/twilio_integration.py

# In another terminal
ngrok http 8080

# Use the ngrok URL in Twilio console
# Example: https://abc123.ngrok.io/twilio/voice
```

### Option 2: Heroku

```bash
# Create Heroku app
heroku create your-app-name

# Set environment variables
heroku config:set TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID
heroku config:set TWILIO_AUTH_TOKEN=YOUR_TWILIO_AUTH_TOKEN
heroku config:set TTS_BASE_URL=https://a288y3vpbfxwkk-8888.proxy.runpod.net
heroku config:set TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU

# Deploy
git push heroku main

# Your webhook: https://your-app-name.herokuapp.com/twilio/voice
```

### Option 3: RunPod (Same as TTS)

Deploy to the same RunPod instance as your TTS service.

---

## 🧪 Testing

### Test with Twilio CLI

```bash
# Install Twilio CLI
npm install -g twilio-cli

# Login
twilio login

# Test call
twilio api:core:calls:create \
  --from=YOUR_TWILIO_NUMBER \
  --to=YOUR_PHONE_NUMBER \
  --url=https://your-server.com/twilio/voice
```

### Test Locally

```bash
# Start server
python scripts/twilio_integration.py

# Test webhook
curl -X POST http://localhost:8080/twilio/voice \
  -d "From=+1234567890" \
  -d "To=YOUR_TWILIO_NUMBER" \
  -d "CallSid=CAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### Test TTS Generation

```bash
# Direct TTS test
curl -X POST "https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Test message for Twilio" \
  -F "voice_id=naija_female" \
  --output twilio_test.mp3
```

---

## 📦 Required Packages

```bash
pip install twilio fastapi uvicorn httpx python-multipart
```

Or add to `requirements.txt`:
```
twilio==8.10.0
fastapi==0.104.1
uvicorn[standard]==0.24.0
httpx==0.25.1
python-multipart==0.0.6
```

---

## 🔐 Security Best Practices

### 1. Validate Twilio Requests

```python
from twilio.request_validator import RequestValidator

validator = RequestValidator(TWILIO_AUTH_TOKEN)

@app.post("/twilio/voice")
async def handle_call(request: Request):
    # Get signature
    signature = request.headers.get('X-Twilio-Signature', '')
    
    # Validate
    if not validator.validate(str(request.url), await request.form(), signature):
        raise HTTPException(status_code=403, detail="Invalid signature")
    
    # Process call...
```

### 2. Use Environment Variables

Never hardcode credentials:
```python
# ✅ Good
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")

# ❌ Bad
TWILIO_AUTH_TOKEN = "YOUR_TWILIO_AUTH_TOKEN"
```

### 3. Rotate Tokens

Twilio supports secondary auth tokens for zero-downtime rotation.

---

## 🐛 Troubleshooting

### Webhook Not Working

**Check:**
1. Server is publicly accessible
2. URL is correct in Twilio console
3. Server is running and responding
4. Firewall allows inbound traffic

**Test:**
```bash
curl -X POST https://your-server.com/twilio/voice \
  -d "From=+1234567890" \
  -d "To=YOUR_TWILIO_NUMBER" \
  -d "CallSid=test"
```

### TTS Not Generating

**Check:**
1. RunPod TTS service is running
2. API key is correct
3. Network connectivity from your webhook server to RunPod

### Audio Not Playing

**Check:**
1. Audio URL is publicly accessible
2. File is valid MP3
3. HTTPS (Twilio requires HTTPS for media)

---

## 📊 Monitoring

### Log Calls

```python
import logging

logger = logging.getLogger(__name__)

@app.post("/twilio/voice")
async def handle_call(From: str = Form(...), CallSid: str = Form(...)):
    logger.info(f"Call from {From}, SID: {CallSid}")
    # Handle call...
```

### Track Usage

```python
# Count calls
call_count = 0

@app.post("/twilio/voice")
async def handle_call():
    global call_count
    call_count += 1
    # Handle call...
```

### Store Call Data

```python
# Store in database
@app.post("/twilio/status")
async def call_status(CallSid: str = Form(...), CallStatus: str = Form(...)):
    db.calls.insert({
        "sid": CallSid,
        "status": CallStatus,
        "timestamp": datetime.now()
    })
```

---

## 🎉 What's Next?

- ✅ Test your Twilio setup: `./test_twilio.sh`
- ✅ Deploy webhook server
- ✅ Configure Twilio phone number
- ✅ Test incoming calls
- ✅ Integrate with n8n for advanced workflows

---

**Your Twilio credentials**: See `.env.master`  
**Ready to accept calls**! 🎉

