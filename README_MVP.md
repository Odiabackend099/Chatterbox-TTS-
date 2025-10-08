# 🤖 AI Voice Agent - MVP Production Package

**Get your AI answering phone calls with real voice in under 15 minutes**

---

## 🎯 What This Is

A **production-ready AI voice agent** that:
- ✅ Answers Twilio phone calls automatically
- ✅ Understands speech (via Twilio transcription)
- ✅ Responds intelligently (via Claude AI)
- ✅ Speaks with natural voice (via Chatterbox TTS)
- ✅ Handles concurrent calls
- ✅ Includes security hardening
- ✅ Ready to deploy today

---

## 🚀 Quick Start (3 Commands)

```bash
# 1. Configure credentials
cp .env.production.template .env.production
nano .env.production  # Add your Twilio & Anthropic keys

# 2. Deploy (one command does everything!)
./deploy_mvp.sh

# 3. Test
./test_twilio_webhook.sh
```

**Then:** Configure Twilio webhook to point to your server → Call your number → Talk to AI!

---

## 📚 Documentation

Choose your path:

### 🏃 **I want to go live NOW** (10 minutes)
→ [QUICK_START_MVP.md](QUICK_START_MVP.md)

### 📖 **I want to understand everything** (30 minutes)
→ [MVP_PRODUCTION_SETUP.md](MVP_PRODUCTION_SETUP.md)

### 🔐 **I need to secure this properly** (1 hour)
→ [SECURITY_CHECKLIST_MVP.md](SECURITY_CHECKLIST_MVP.md)

### 🔧 **I want to customize the AI** (ongoing)
→ [README.md](README.md) (full technical documentation)

---

## ✅ What's Included

### 🛠️ Scripts

- **`deploy_mvp.sh`** - One-command deployment with security checks
- **`test_twilio_webhook.sh`** - Comprehensive integration testing
- **`security_audit.sh`** - Pre-launch security validation

### 📄 Configuration

- **`.env.production.template`** - Production environment template (secure defaults)
- **`config/config.yaml`** - Application configuration (CORS fixed, no default passwords)
- **`docker-compose.yml`** - Full stack (TTS server + PostgreSQL + Redis + Nginx)

### 📖 Documentation

- **`QUICK_START_MVP.md`** - Get live in 10 minutes
- **`MVP_PRODUCTION_SETUP.md`** - Complete setup guide
- **`SECURITY_CHECKLIST_MVP.md`** - Production security hardening
- **`API_REFERENCE.md`** - API endpoint documentation

### 🔐 Security Improvements Applied

✅ Removed default credentials from config files
✅ Generated secure random passwords automatically
✅ Restricted CORS origins (no more wildcards)
✅ Environment-based secrets (not in code)
✅ .env.production template with security warnings
✅ Automated security audit script
✅ Production deployment checklist

---

## 🎤 How It Works

```
┌──────────────┐
│  User calls  │
│ Twilio number│
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  Twilio receives │
│  calls webhook   │ ──────────────┐
└──────┬───────────┘               │
       │                           │
       ▼                           │
┌──────────────────┐               │
│ Your Server      │               │
│ /twilio/voice    │               │
└──────┬───────────┘               │
       │                           │
       ▼                           │
┌──────────────────┐               │
│ AI greets caller │               │
│ "Hello! I'm your │               │
│  AI assistant"   │               │
└──────┬───────────┘               │
       │                           │
       ▼                           │
┌──────────────────┐               │
│ User speaks      │               │
│ Twilio transcribes│              │
└──────┬───────────┘               │
       │                           │
       ▼                           ▼
┌──────────────────┐      ┌────────────────┐
│ LLM (Claude)     │      │ Text → Voice   │
│ generates reply  │─────▶│ (Chatterbox TTS)│
└──────────────────┘      └────────┬───────┘
                                   │
                                   ▼
                          ┌────────────────┐
                          │ AI speaks reply│
                          │ to caller      │
                          └────────┬───────┘
                                   │
                                   ▼
                          ┌────────────────┐
                          │ Loop continues │
                          │ until hangup   │
                          └────────────────┘
```

---

## 💰 Cost Breakdown (MVP Phase)

For **100 calls/day, 3 minutes average**:

| Service | Cost | Notes |
|---------|------|-------|
| **Twilio** | $20-30/mo | Phone number + call minutes |
| **Anthropic API** | $10-20/mo | Claude AI responses |
| **RunPod GPU** | $290/mo | RTX 4090 24/7 (or $100-150 spot) |
| **Total** | **$320-400/mo** | Scales with usage |

**Cost optimization:**
- Spot instances: 50% savings ($100-150 vs $290)
- Auto-shutdown: 70% savings (business hours only)
- Start small, scale as needed

---

## 🎯 MVP Feature Checklist

What's working out of the box:

- [x] **Voice calls** - Twilio integration complete
- [x] **Speech recognition** - Twilio automatic transcription
- [x] **AI responses** - Claude 3.5 Sonnet integration
- [x] **Natural voice** - Chatterbox TTS with emotion control
- [x] **Voice cloning** - Upload custom voices (10-20 sec samples)
- [x] **Multi-language** - 23 languages supported
- [x] **Concurrent calls** - Handle 2-5 simultaneous calls (per GPU)
- [x] **Health checks** - `/health` endpoint for monitoring
- [x] **Docker deployment** - One-command production setup
- [x] **Security** - API keys, rate limiting, CORS, HTTPS-ready

What's **not** included (but easy to add):

- [ ] Billing integration (Stripe)
- [ ] Customer dashboard
- [ ] Call analytics/reporting
- [ ] Call recording storage
- [ ] SMS follow-up
- [ ] Calendar integration
- [ ] CRM integration
- [ ] Multi-region deployment
- [ ] Auto-scaling

See [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) for advanced features.

---

## 🧪 Testing Your Deployment

### 1. Automated Tests

```bash
# Run full integration test suite
./test_twilio_webhook.sh

# Should show:
# ✅ Health check passed
# ✅ Voice webhook working
# ✅ Speech processing working
# ✅ TTS generation working
# ✅ LLM integration working
```

### 2. Manual Tests

```bash
# Test health endpoint
curl http://localhost:8004/health

# Test TTS generation
curl -X POST http://localhost:8004/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello world"}' \
  --output test.wav

# Play the audio (macOS)
afplay test.wav

# Play the audio (Linux)
aplay test.wav
```

### 3. Real Phone Call Test

1. Call your Twilio number
2. You should hear: "Hello! I'm your AI assistant..."
3. Ask a question: "What's the weather like?"
4. AI should respond with natural voice

---

## 🔧 Customization Quick Guide

### Change Greeting

Edit [scripts/server.py:502](scripts/server.py#L502):
```python
response.say("Hello! I'm your AI assistant. How can I help you today?")
```

To:
```python
response.say("Thanks for calling Acme Corp! I'm an AI assistant. What can I do for you?")
```

### Adjust Voice Emotion

Edit [config/config.yaml:13-18](config/config.yaml#L13-18):
```yaml
generation_defaults:
  temperature: 0.8      # 0-2: Variation (lower = more consistent)
  exaggeration: 1.3     # 0-2: Emotion (lower = neutral, higher = dramatic)
  speed_factor: 1.0     # 0.5 = slow, 2.0 = fast
```

### Use Different Voice

```bash
# List built-in voices
curl http://localhost:8004/voices

# Upload custom voice (10-20 sec clean audio)
curl -X POST http://localhost:8004/upload-voice \
  -F "voice_name=MyVoice" \
  -F "audio_file=@my_voice.wav"

# Update config to use it
# config.yaml -> default_voice: "MyVoice.wav"
```

### Change AI Personality

Edit [scripts/server.py:454](scripts/server.py#L454) to add system prompt:
```python
messages=[
    {
        "role": "system",
        "content": "You are a helpful customer service rep for Acme Corp. Be concise, friendly, and professional."
    },
    {"role": "user", "content": request.prompt}
]
```

---

## 🆘 Troubleshooting

### "Connection refused" when calling webhook

**Solution:**
```bash
# Check services are running
docker-compose ps

# Restart if needed
docker-compose restart chatterbox-tts

# Check logs
docker-compose logs -f chatterbox-tts
```

### "TTS model not loaded"

**Solution:**
```bash
# Wait 2-3 minutes for first model download
docker-compose logs -f chatterbox-tts | grep "model"

# Check GPU availability
docker-compose exec chatterbox-tts python -c "import torch; print(torch.cuda.is_available())"

# If no GPU, use CPU (slow but works)
# Edit .env.production: CHATTERBOX_DEVICE=cpu
```

### "Twilio webhook timeout"

**Solution:**
- TTS generation taking too long (need GPU)
- Check latency in logs: `docker-compose logs | grep "Generated"`
- Expected: 0.5-2s on GPU, 10-30s on CPU
- Twilio times out after 15 seconds

### "No audio on call"

**Solution:**
```bash
# Verify webhook URL is HTTPS (not HTTP)
curl https://your-url/twilio/voice

# Check Twilio webhook logs
# Go to: https://console.twilio.com → Monitor → Logs

# Test TTS directly
curl -X POST http://localhost:8004/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"test"}' \
  --output test.wav

# Verify file is valid WAV
file test.wav
```

---

## 📊 Monitoring

### View Logs

```bash
# All logs
docker-compose logs -f

# Just TTS server
docker-compose logs -f chatterbox-tts

# Just Twilio calls
docker-compose logs | grep "twilio"

# Errors only
docker-compose logs | grep "ERROR"
```

### Check Health

```bash
# Basic health
curl http://localhost:8004/health

# Detailed health (with metrics)
curl http://localhost:8004/health/detailed

# Prometheus metrics
curl http://localhost:8004/metrics
```

### Performance Metrics

Expected performance on RTX 4090:
- **TTS latency**: 500ms - 1s
- **LLM latency**: 1-2s
- **Total response time**: 3-5s
- **Concurrent calls**: 2-5 simultaneously

---

## 🚨 Emergency Procedures

### Quick Shutdown

```bash
# Stop all services
docker-compose down

# If services won't stop
docker-compose kill
```

### Revoke All API Keys

```bash
# If you suspect a security breach
docker-compose exec postgres psql -U postgres chatterbox -c "UPDATE api_keys SET status='revoked';"
```

### View Security Logs

```bash
# Check for failed auth attempts
docker-compose logs | grep "Invalid API key"

# Check for rate limit violations
docker-compose logs | grep "Rate limit exceeded"

# Export logs for analysis
docker-compose logs --since 24h > security_audit_$(date +%Y%m%d).log
```

---

## 📞 Support & Resources

### Quick Links

- [Twilio Console](https://console.twilio.com) - Monitor calls
- [Anthropic Console](https://console.anthropic.com) - Check API usage
- [RunPod Console](https://runpod.io) - Manage GPU instances

### Documentation

- **This repo:**
  - [QUICK_START_MVP.md](QUICK_START_MVP.md) - Fast setup
  - [MVP_PRODUCTION_SETUP.md](MVP_PRODUCTION_SETUP.md) - Detailed guide
  - [SECURITY_CHECKLIST_MVP.md](SECURITY_CHECKLIST_MVP.md) - Security hardening
  - [API_REFERENCE.md](API_REFERENCE.md) - API docs

- **External:**
  - [Twilio Voice Docs](https://www.twilio.com/docs/voice)
  - [Chatterbox TTS Docs](https://github.com/resemble-ai/chatterbox)
  - [Anthropic API Docs](https://docs.anthropic.com)

---

## 🎉 Next Steps

Once your AI is live and handling calls:

1. **Monitor first 10-20 calls** - Check logs, listen to call quality
2. **Collect feedback** - What works? What needs improvement?
3. **Optimize personality** - Adjust system prompts, voice settings
4. **Add features** - Call transfer, voicemail, SMS follow-up
5. **Scale up** - Multiple instances, load balancer, multi-region

See [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) for scaling guidance.

---

## 🏆 Success Checklist

Your AI voice agent is production-ready when:

- [x] Server deployed and running
- [x] Twilio webhook configured
- [x] Test call successful
- [x] AI responds with natural voice
- [x] HTTPS enabled
- [x] Security checklist completed
- [x] Monitoring/alerts set up
- [x] Backups configured
- [x] Emergency procedures documented

---

**🚀 Ready to deploy? Run `./deploy_mvp.sh` and get live in 10 minutes!**

---

*Last Updated: 2025-10-07*
*Version: MVP 1.0*
*Tested on: Ubuntu 22.04, macOS 13+, Docker 24+*
