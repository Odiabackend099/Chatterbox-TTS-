# 🚀 Quick Start - Get Live in 10 Minutes

## One-Command Deployment

```bash
./deploy_mvp.sh
```

That's it! The script will:
- ✅ Check prerequisites
- ✅ Configure environment
- ✅ Apply security hardening
- ✅ Build and start services
- ✅ Verify deployment

---

## Before You Start

**Get these ready (5 minutes):**

1. **Twilio Account** → [console.twilio.com](https://console.twilio.com)
   - Account SID (starts with AC...)
   - Auth Token
   - Phone Number (+1...)

2. **Anthropic API Key** → [console.anthropic.com](https://console.anthropic.com)
   - Get $5 free credits
   - API key (starts with sk-ant-...)

---

## Step-by-Step (If deploy script fails)

### 1. Configure Credentials (2 min)

```bash
cp .env.production.template .env.production
nano .env.production
```

Set these values:
```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=+15551234567
ANTHROPIC_API_KEY=sk-ant-xxxxx
POSTGRES_PASSWORD=$(openssl rand -base64 32)
```

### 2. Start Services (3 min)

```bash
docker-compose up -d
```

Wait for "TTS model loaded" in logs:
```bash
docker-compose logs -f chatterbox-tts
```

### 3. Expose to Internet (2 min)

**For Testing:**
```bash
ngrok http 8004
```

**For Production:**
```bash
# Point your domain to server IP
# Enable SSL
sudo certbot --nginx -d voice.yourdomain.com
```

### 4. Connect Twilio (3 min)

1. Go to [Twilio Phone Numbers](https://console.twilio.com/us1/develop/phone-numbers/manage/incoming)
2. Click your number
3. Set "A CALL COMES IN" webhook:
   - **URL**: `https://your-ngrok-url.ngrok.io/twilio/voice`
   - **Method**: POST
4. Save

### 5. Test! (1 min)

Call your Twilio number. You should hear:
> "Hello! I'm your AI assistant. How can I help you today?"

---

## Verify Everything Works

```bash
# Test webhooks
./test_twilio_webhook.sh

# Check health
curl http://localhost:8004/health

# View logs
docker-compose logs -f chatterbox-tts
```

---

## Common Issues

**"TTS model not loaded"**
- Wait 2-3 minutes for first model download
- Check: `docker-compose logs chatterbox-tts | grep "model"`

**"Twilio webhook timeout"**
- Server too slow (need GPU)
- Check latency: `docker-compose logs | grep "Generated"`

**"Connection refused"**
- Services not started: `docker-compose ps`
- Firewall blocking port 8004

**"No audio on call"**
- Check ngrok URL is HTTPS (not HTTP)
- Verify webhook URL in Twilio console
- Test TTS directly: `curl -X POST http://localhost:8004/tts -H "Content-Type: application/json" -d '{"text":"test"}' --output test.wav`

---

## Customization

### Change Voice Personality

Edit `scripts/server.py` line 502:
```python
response.say("Your custom greeting here!")
```

### Adjust Voice Emotion

Edit `config/config.yaml`:
```yaml
generation_defaults:
  exaggeration: 1.5  # Higher = more emotional (0-2)
  temperature: 0.8   # Higher = more varied (0-2)
```

### Use Different Voice

```bash
# List available voices
curl http://localhost:8004/voices

# Upload custom voice
curl -X POST http://localhost:8004/upload-voice \
  -F "voice_name=MyVoice" \
  -F "audio_file=@my_voice_sample.wav"
```

---

## Production Checklist

Before going live to customers:

- [ ] Changed default database password
- [ ] Set ALLOWED_ORIGINS to your domain (not *)
- [ ] Enabled HTTPS/SSL
- [ ] Tested with multiple concurrent calls
- [ ] Set up monitoring alerts
- [ ] Backed up .env.production securely

---

## Cost Estimate

**For 100 calls/day (3 min average):**

- Twilio: $20-30/mo
- Anthropic API: $10-20/mo
- RunPod GPU: $290/mo (or $100-150 with spot instances)
- **Total: ~$320-400/mo**

**Cost Optimization:**
- Use spot instances (50% cheaper)
- Enable auto-shutdown when idle (70% savings)
- Start small, scale as needed

---

## Support

**Issues?**
1. Check logs: `docker-compose logs -f`
2. Run tests: `./test_twilio_webhook.sh`
3. Review: `MVP_PRODUCTION_SETUP.md`

**Need Help?**
- Twilio webhook logs: [console.twilio.com](https://console.twilio.com) → Monitor
- Check health: `curl localhost:8004/health`
- Server logs: `tail -f logs/server.log`

---

## Next Steps

Once live and working:

1. **Monitor Performance** - Track call duration, errors, latency
2. **Add Features** - Call transfer, voicemail, SMS follow-up
3. **Scale Up** - Multiple instances with load balancer
4. **Integrate** - Connect to your CRM, database, calendar

See [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md) for advanced features.

---

**🎉 You're ready! Call your number and talk to your AI!**
