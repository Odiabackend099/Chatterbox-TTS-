# 🚀 MVP Production Setup - Live AI Voice Agent
## Get Your AI Answering Calls in 15 Minutes

---

## ✅ Pre-Flight Checklist

Before starting, ensure you have:

- [ ] Twilio account with phone number ([Get one here](https://www.twilio.com/try-twilio))
- [ ] Anthropic API key ([Get free credits](https://console.anthropic.com/))
- [ ] Domain or ngrok for webhooks (ngrok is fastest for testing)
- [ ] Server with GPU (RunPod) OR Mac with Apple Silicon (for testing)

---

## 🎯 Quick Start - 3 Steps to Live

### Step 1: Configure Your Credentials (2 minutes)

```bash
# Copy environment template
cp .env.example .env.production

# Edit with your real credentials
nano .env.production
```

**Required values:**
```bash
# Twilio (REQUIRED - get from https://console.twilio.com)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15551234567

# AI Brain (REQUIRED - get from https://console.anthropic.com)
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxx

# Security (REQUIRED - generate strong passwords)
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# Server (defaults are fine for MVP)
CHATTERBOX_PORT=8004
ENVIRONMENT=production
```

### Step 2: Start the AI Voice Service (5 minutes)

**Option A: Local Testing (Mac/Linux with GPU)**
```bash
# Install dependencies
pip install -r requirements.txt

# Start the server
python scripts/server.py
```

**Option B: Production Docker (Recommended)**
```bash
# Start all services (database, redis, TTS server)
docker-compose up -d

# Check logs to confirm it's running
docker-compose logs -f chatterbox-tts

# Wait for "TTS model loaded successfully" message
```

**Option C: Cloud Deployment (RunPod)**
```bash
# See RUNPOD_DEPLOYMENT.md for full instructions
cd runpod/
./deploy_runpod.sh
```

### Step 3: Connect Twilio to Your AI (8 minutes)

**3A: Expose Your Server (Choose One)**

**For Testing - Use ngrok (fastest):**
```bash
# Install ngrok: https://ngrok.com/download
ngrok http 8004

# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
```

**For Production - Use your domain:**
```bash
# Point your domain DNS to your server IP
# Configure SSL with Let's Encrypt:
sudo certbot --nginx -d voice.yourdomain.com
```

**3B: Configure Twilio Webhook**

1. Go to [Twilio Console](https://console.twilio.com/us1/develop/phone-numbers/manage/incoming)
2. Click on your phone number
3. Scroll to "Voice Configuration"
4. Set **"A CALL COMES IN"** to:
   - **Webhook**: `https://your-url.com/twilio/voice` (or `https://abc123.ngrok.io/twilio/voice`)
   - **HTTP Method**: `POST`
5. Set **"Status Callback URL"** to:
   - `https://your-url.com/twilio/status`
6. Click **Save**

**3C: Test Your AI!**

```bash
# Call your Twilio number from your phone
# You should hear: "Hello! I'm your AI assistant. How can I help you today?"

# Check server logs to see it working:
docker-compose logs -f chatterbox-tts

# Or if running locally:
tail -f logs/server.log
```

---

## 🎤 Customizing Your AI Voice Agent

### Change the Voice

**Option 1: Use Built-in Voices**

Edit `config/config.yaml`:
```yaml
model:
  default_voice: "Emily.wav"  # Change to "John.wav", "Sophia.wav", etc.
```

**Option 2: Clone Your Own Voice**

```bash
# Record 10-20 seconds of clear speech
# Save as myvoice.wav

# Upload via API
curl -X POST http://localhost:8004/upload-voice \
  -F "voice_name=MyCustomVoice" \
  -F "audio_file=@myvoice.wav"

# Update config to use it
# config.yaml -> default_voice: "MyCustomVoice.wav"
```

### Customize AI Personality

Edit `scripts/server.py` around line 502:

```python
# Change the greeting
response.say("Hello! I'm your AI assistant. How can I help you today?")

# To something like:
response.say("Hi there! You've reached Acme Corporation. I'm an AI assistant here to help. What can I do for you?")
```

For more advanced personality, edit the LLM system prompt (around line 454):

```python
messages=[
    {"role": "system", "content": "You are a helpful, professional customer service representative for Acme Corp. Be concise, friendly, and always offer to connect to a human if needed."},
    {"role": "user", "content": request.prompt}
]
```

### Adjust Voice Emotion

Edit `config/config.yaml`:

```yaml
generation_defaults:
  temperature: 0.8      # 0-2: Lower = more consistent, Higher = more varied
  exaggeration: 1.3     # 0-2: Lower = neutral, Higher = more emotional
  speed_factor: 1.0     # 0.5 = half speed, 2.0 = double speed
```

---

## 🔍 Monitoring & Troubleshooting

### Check if Everything is Running

```bash
# Health check
curl http://localhost:8004/health

# Should return:
{
  "status": "healthy",
  "components": {
    "tts_model": true,
    "llm_client": true,
    "twilio_client": true
  }
}
```

### Common Issues

**Problem: "TTS model not loaded"**
```bash
# Check device (GPU/CPU)
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, MPS: {torch.backends.mps.is_available()}')"

# Try forcing CPU mode
CHATTERBOX_DEVICE=cpu python scripts/server.py
```

**Problem: "Twilio webhook timeout"**
- TTS generation is too slow (need GPU or faster server)
- Check logs for actual generation time
- Twilio times out after 15 seconds

**Problem: "LLM client not initialized"**
```bash
# Verify API key is set
echo $ANTHROPIC_API_KEY

# Test LLM directly
curl -X POST http://localhost:8004/llm \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Say hello", "max_tokens": 50}'
```

**Problem: Call connects but no voice**
- Check that server URL is accessible from internet (test with curl)
- Verify webhook URL in Twilio console is correct (https, not http)
- Check server logs for errors

### View Live Logs

```bash
# Docker
docker-compose logs -f chatterbox-tts

# Local
tail -f logs/server.log

# Filter for Twilio-specific logs
docker-compose logs -f | grep "twilio"
```

---

## 📊 Testing Checklist

Before going live to customers:

- [ ] **Basic Call Test**: Call the number, hear greeting
- [ ] **Speech Recognition Test**: Speak a question, AI responds
- [ ] **Voice Quality Test**: Is the AI voice clear and natural?
- [ ] **Latency Test**: Response within 5 seconds?
- [ ] **Error Handling Test**: Say gibberish, AI handles gracefully?
- [ ] **Concurrent Calls Test**: Have 2-3 people call simultaneously
- [ ] **Long Conversation Test**: 5+ minute conversation, no crashes?

### Performance Benchmarks

**Expected latency (GPU):**
- Speech recognition by Twilio: 1-2 seconds
- LLM response: 1-2 seconds
- TTS generation: 0.5-2 seconds
- **Total**: 3-6 seconds per turn

**Expected latency (CPU):**
- TTS generation: 10-30 seconds
- **Total**: 12-35 seconds per turn
- ⚠️ **Too slow for production, use GPU**

---

## 🔐 Production Security Hardening

**Before announcing to customers, complete these:**

### 1. Change Default Passwords (CRITICAL)

```bash
# Generate strong password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update .env.production
sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PASSWORD/" .env.production

# Restart services
docker-compose down && docker-compose up -d
```

### 2. Restrict CORS Origins

Edit `config/config.yaml`:
```yaml
security:
  enable_auth: true  # Enable auth for admin endpoints
  allowed_origins:
    - "https://yourdomain.com"  # Replace * with your actual domain
    - "https://app.yourdomain.com"
```

### 3. Set Up HTTPS (Production Only)

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d voice.yourdomain.com

# Auto-renewal (already configured in docker-compose.yml)
```

### 4. Enable Rate Limiting

Already configured in Nginx (see `nginx.conf`):
- 10 requests/second per IP (general API)
- 2 requests/second per IP (TTS generation)

### 5. Set Up Monitoring Alerts

```bash
# Install uptimerobot or pingdom for uptime monitoring
# Point to: https://yourdomain.com/health

# Set up alerts for:
# - API down (health check fails)
# - High latency (>10s response time)
# - Error rate (>5% of requests)
```

---

## 💰 Cost Estimate (MVP Phase)

**For 100 calls/day, 3 min average:**

| Service | Cost/Month | Notes |
|---------|------------|-------|
| **Twilio** | $20-30 | $1/mo number + $0.0085/min |
| **Anthropic API** | $10-20 | ~$0.003/1k tokens |
| **RunPod GPU** | $290 | RTX 4090, 24/7 (or use spot for $100-150) |
| **Database** | $0 | PostgreSQL in Docker (or $50 for managed) |
| **Domain/SSL** | $15 | Domain + SSL cert |
| **Total** | **$335-405/mo** | Can reduce with spot instances |

**Cost Optimization Tips:**
- Use RunPod **Spot Instances**: $100-150/mo instead of $290 (save 50%)
- Enable **auto-shutdown** when no calls: Save 70% if only running business hours
- Use **CPU mode** for very low volume: Free (but slow, not recommended)

---

## 🚀 Next Steps After MVP

Once your AI is live and handling calls successfully:

1. **Add Call Analytics** - Track call volume, duration, common questions
2. **Implement Billing** - See `PRODUCTION_DEPLOYMENT.md` for Stripe integration
3. **Custom Integrations** - Connect to your CRM, calendar, database
4. **Multi-Language Support** - Enable other languages (23 supported)
5. **Advanced Features**:
   - Call transfer to humans
   - Voicemail transcription
   - Appointment scheduling
   - SMS follow-ups

See `INTEGRATION_BEST_PRACTICES.md` for advanced customization.

---

## 📞 Support & Resources

**Quick Links:**
- [Full Documentation](README.md)
- [API Reference](API_REFERENCE.md)
- [Troubleshooting Guide](QUICKSTART.md#troubleshooting)
- [Twilio Docs](https://www.twilio.com/docs/voice)

**Need Help?**
- Check logs first: `docker-compose logs -f`
- Test health endpoint: `curl http://localhost:8004/health`
- Review Twilio webhook logs in console

**Common Questions:**
- **Q: Can I use OpenAI instead of Anthropic?**
  A: Yes! Just set `OPENAI_API_KEY` in `.env` and change `llm.provider: openai` in `config.yaml`

- **Q: How do I scale to handle more calls?**
  A: Deploy multiple instances with load balancer (see `PRODUCTION_DEPLOYMENT.md`)

- **Q: Can I run this without GPU?**
  A: Yes, but TTS will be 10-20x slower. Good for very low volume (<10 calls/day)

---

**✅ You're Ready!**

Call your Twilio number and start talking to your AI voice agent!

---

*Last Updated: 2025-10-07*
*MVP Version: 1.0*
