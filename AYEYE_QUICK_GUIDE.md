# 👤 Ayeye Quick Guide - AI Voice System

**Everything you need in under 10 pages**

---

## 🎯 What This System Does

An AI robot that answers phone calls automatically:
1. Answers calls on Twilio number
2. Listens to caller's speech
3. Thinks (using Claude AI)
4. Responds with natural voice
5. Continues conversation until hangup

---

## ✅ Setup Checklist (Day 1-2)

### Step 1: Create Accounts (30 min)

**Twilio** - Phone service ($20-30/mo)
- Go to: https://console.twilio.com
- Sign up, verify email/phone
- Get phone number (free trial or $1/mo)
- Copy Account SID (starts with AC...)
- Copy Auth Token (click to reveal)
- Save in `credentials.txt`

**Anthropic** - AI brain ($10-20/mo)
- Go to: https://console.anthropic.com
- Sign up, verify email
- Click API Keys → Create Key
- Copy IMMEDIATELY (can't see again!)
- Save in `credentials.txt`

**RunPod** - GPU server ($290/mo, can reduce to $100)
- Go to: https://runpod.io
- Sign up, add payment method
- Get API key from Settings
- Save in `credentials.txt`

### Step 2: Install Software (10 min)

```bash
# Check Docker is installed
docker --version
docker-compose --version

# If not: Download from https://docs.docker.com/get-docker/
```

### Step 3: Configure (5 min)

```bash
# Copy template
cp .env.production.template .env.production

# Edit with your credentials
nano .env.production
```

Add your keys:
```bash
TWILIO_ACCOUNT_SID=ACxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxx
TWILIO_PHONE_NUMBER=+15551234567
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxx
```

Save: `Ctrl+X` → `Y` → `Enter`

### Step 4: Deploy (10 min)

```bash
# Run automatic deployment
./deploy_mvp.sh

# Wait for: "DEPLOYMENT SUCCESSFUL"
```

### Step 5: Expose to Internet (5 min)

**For testing (use ngrok):**
```bash
# In NEW terminal window
ngrok http 8004

# Copy the https:// URL shown
```

### Step 6: Connect Twilio (5 min)

1. Go to: https://console.twilio.com → Phone Numbers
2. Click your number
3. Set "A CALL COMES IN":
   - Webhook: `https://YOUR-NGROK-URL/twilio/voice`
   - Method: POST
4. Set "Status Callback":
   - URL: `https://YOUR-NGROK-URL/twilio/status`
5. Save

### Step 7: Test (5 min)

```bash
# Run tests
./test_twilio_webhook.sh

# Call your Twilio number from phone
# Should hear: "Hello! I'm your AI assistant..."
```

---

## 📅 Daily Operations (5 min/day)

### Morning Check

```bash
# 1. Check services running
docker-compose ps
# All should show "Up"

# 2. Check health
curl localhost:8004/health
# Should return: "status": "healthy"

# 3. Check for errors
docker-compose logs --since 12h | grep ERROR
# Should be empty or minor warnings

# 4. Make test call
# Call your number, verify AI answers
```

---

## 🔧 Common Problems & Fixes

### Problem: Services Won't Start

```bash
# Restart everything
docker-compose down
docker-compose up -d

# Still broken? Check logs
docker-compose logs chatterbox-tts | tail -50
```

**Common fixes:**
- Port busy: `sudo lsof -i :8004` → kill that process
- Out of memory: Close other programs
- Docker not running: Start Docker Desktop

### Problem: Calls Not Connecting

**Check webhook URL:**
1. Go to Twilio console
2. Verify webhook is: `https://YOUR-URL/twilio/voice`
3. Must be HTTPS (not HTTP)
4. Must be POST method

**Check server reachable:**
```bash
curl https://your-url/twilio/voice
# Should return XML with <Response>
```

### Problem: AI Not Responding

**Check API key:**
```bash
# View environment
cat .env.production | grep ANTHROPIC_API_KEY

# Should show: ANTHROPIC_API_KEY=sk-ant-xxxxx
# If wrong, edit and restart:
nano .env.production
docker-compose restart chatterbox-tts
```

**Check credits:**
- Go to: https://console.anthropic.com → Usage
- Make sure you have credits

### Problem: Slow Responses (>10 sec)

**Check if using GPU:**
```bash
docker-compose exec chatterbox-tts python -c "import torch; print('GPU:', torch.cuda.is_available())"

# Should show: GPU: True
# If False: Need to deploy to RunPod
```

**Check logs for timing:**
```bash
docker-compose logs -f | grep "Generated"
# Look for: Generated X.Xs audio in XXXms
# Good: < 1000ms, Bad: > 5000ms
```

### Problem: No Voice on Call

**Test TTS directly:**
```bash
curl -X POST http://localhost:8004/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"Test"}' \
  --output test.wav

afplay test.wav  # Mac
aplay test.wav   # Linux
```

If audio plays fine locally but not on call:
- Webhook must be HTTPS
- Check Twilio webhook logs

---

## 🚨 Emergency Procedures

### Stop Everything Now

```bash
docker-compose down

# If that doesn't work:
docker-compose kill
```

### Revoke Compromised API Keys

**Twilio:**
1. Go to: https://console.twilio.com → Settings → API
2. Delete Auth Token
3. Generate new one
4. Update .env.production

**Anthropic:**
1. Go to: https://console.anthropic.com → API Keys
2. Delete old key
3. Create new key
4. Update .env.production

```bash
# After updating keys:
docker-compose restart chatterbox-tts
```

### Restore Database

```bash
# Stop services
docker-compose down

# Start database only
docker-compose up -d postgres
sleep 10

# Restore backup (find latest with: ls -lt backup_*)
gunzip < backup_YYYYMMDD.sql.gz | \
  docker-compose exec -T postgres psql -U postgres chatterbox

# Restart everything
docker-compose up -d
```

---

## 📖 Useful Commands

### Service Management

```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart one service
docker-compose restart chatterbox-tts

# View status
docker-compose ps

# View logs (live)
docker-compose logs -f chatterbox-tts

# View recent logs
docker-compose logs --tail 100 chatterbox-tts
```

### Monitoring

```bash
# Health check
curl localhost:8004/health

# Count today's calls
docker-compose logs --since 24h | grep "Incoming call" | wc -l

# Find errors
docker-compose logs | grep ERROR | tail -20

# Check costs
# Twilio: https://console.twilio.com → Monitor → Usage
# Anthropic: https://console.anthropic.com → Usage
# RunPod: https://runpod.io → Billing
```

### Backups

```bash
# Create backup
docker-compose exec -T postgres pg_dump -U postgres chatterbox | \
  gzip > backup_$(date +%Y%m%d).sql.gz

# Restore backup
gunzip < backup_20251007.sql.gz | \
  docker-compose exec -T postgres psql -U postgres chatterbox

# Delete old backups (keep 30 days)
find . -name "backup_*.sql.gz" -mtime +30 -delete
```

---

## 💰 Cost Management

**Current costs (100 calls/day):**
- Twilio: $20-30/mo
- Anthropic: $10-20/mo
- RunPod: $290/mo
- **Total: ~$320-400/mo**

**Reduce costs:**

**1. Use Spot Instances (50% savings)**
```
RunPod console → Deploy → Choose "Spot" instead of "On-Demand"
Cost: $100-150/mo instead of $290/mo
```

**2. Auto-shutdown (70% savings)**
```
RunPod console → Pod Settings → Auto-Stop
Set: Stop after 1 hour of no activity
Cost: ~$90/mo (only runs when needed)
```

**3. Business hours only**
```bash
# Stop at 6pm, start at 8am (Linux cron)
0 18 * * * cd /path/to/chatterbox && docker-compose down
0 8 * * * cd /path/to/chatterbox && docker-compose up -d
```

---

## 🎯 Customization

### Change Greeting

Edit `scripts/server.py` line 502:
```python
response.say("Hello! I'm your AI assistant...")
```

Change to:
```python
response.say("Thanks for calling [COMPANY]! How can I help?")
```

Restart:
```bash
docker-compose restart chatterbox-tts
```

### Adjust Voice Emotion

Edit `config/config.yaml`:
```yaml
generation_defaults:
  exaggeration: 1.3  # 0.5=neutral, 2.0=very emotional
  temperature: 0.8   # 0.5=consistent, 1.5=varied
```

Restart:
```bash
docker-compose restart chatterbox-tts
```

### Upload Custom Voice

```bash
# Record 10-20 seconds of clear speech
# Save as voice.wav

# Upload
curl -X POST http://localhost:8004/upload-voice \
  -F "voice_name=CustomVoice" \
  -F "audio_file=@voice.wav"

# Use it: Edit config/config.yaml
# default_voice: "CustomVoice.wav"
```

---

## 📞 When to Call Boss

**Call Immediately:**
- 🚨 System down, customers affected
- 🚨 Security warning/"hacked" message
- 🚨 Costs 10x higher than normal
- 🚨 Tried fixing for 15+ minutes, still broken

**Call End of Day:**
- Questions about operations
- Something seems wrong but not urgent
- Want to confirm you did something right

**Weekly Report (Email):**
- System status summary
- Total calls this week
- Costs breakdown
- Any issues encountered

---

## ✅ Weekly Checklist

**Every Monday:**
```
[ ] Create database backup
[ ] Check Twilio costs
[ ] Check Anthropic costs
[ ] Check RunPod costs
[ ] Review error logs: docker-compose logs --since 7d | grep ERROR
[ ] Test call still working
[ ] Report to boss via email
```

---

## 🎓 Production Deployment (RunPod)

**For 24/7 operation with real customers:**

### Option 1: Via Web Console (Easier)

1. Go to: https://runpod.io/console/pods
2. Click: Deploy → GPU Pod
3. Select: RTX 4090 (or RTX 3090 for cheaper)
4. Template: Docker
5. Image: `<your-dockerhub-username>/chatterbox-tts:latest`
6. Port: 8004 (HTTP)
7. Environment Variables:
   ```
   TWILIO_ACCOUNT_SID=ACxxx
   TWILIO_AUTH_TOKEN=xxx
   TWILIO_PHONE_NUMBER=+1xxx
   ANTHROPIC_API_KEY=sk-ant-xxx
   POSTGRES_PASSWORD=<secure-password>
   ```
8. Click: Deploy
9. Wait 2-3 minutes
10. Copy URL: `https://xxxxx-8004.proxy.runpod.net`

### Option 2: Via Script (Automated)

```bash
cd runpod/
export RUNPOD_API_KEY=your_api_key
./deploy_runpod.sh
```

### Update Twilio Webhook

Use RunPod URL instead of ngrok:
- Webhook: `https://xxxxx-8004.proxy.runpod.net/twilio/voice`
- Status: `https://xxxxx-8004.proxy.runpod.net/twilio/status`

---

## 📝 credentials.txt Template

**Create this file, keep it SAFE:**

```
TWILIO CREDENTIALS:
Account SID: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Auth Token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Phone Number: +15551234567

ANTHROPIC CREDENTIALS:
API Key: sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

RUNPOD CREDENTIALS:
API Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Pod ID: xxxxxxxxxxxxx

SERVER URLS:
ngrok (testing): https://xxxx.ngrok.io
RunPod (production): https://xxxxx-8004.proxy.runpod.net

BOSS CONTACT:
Name: _______________
Phone: _______________
Email: _______________

LAST UPDATED: _______________
```

---

## 🎉 Success Checklist

**You're ready when:**
- [ ] All services show "Up" in `docker-compose ps`
- [ ] Health check returns "healthy"
- [ ] Test call works (AI answers and responds)
- [ ] Webhook configured in Twilio
- [ ] Can view logs and understand them
- [ ] Know how to restart services
- [ ] Know when to call boss vs. fix yourself
- [ ] Daily check takes < 5 minutes
- [ ] Credentials saved securely

---

## 🔗 Quick Links

**Consoles:**
- Twilio: https://console.twilio.com
- Anthropic: https://console.anthropic.com
- RunPod: https://runpod.io

**Status Pages:**
- Twilio: https://status.twilio.com
- Anthropic: https://status.anthropic.com
- RunPod: https://status.runpod.io

**Documentation:**
- Full setup: MVP_PRODUCTION_SETUP.md
- Security: SECURITY_CHECKLIST_MVP.md
- API docs: API_REFERENCE.md

---

**Questions? Check the full guide: AYEYE_COMPLETE_GUIDE.md**

**Boss Contact:** _______________

**Last Updated:** 2025-10-07

---

🎯 **YOU GOT THIS!** 🎯
