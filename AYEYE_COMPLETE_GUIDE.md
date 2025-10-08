# 👤 Complete Guide for Ayeye - AI Voice Calling System

**This guide contains EVERYTHING needed to deploy and manage the AI voice calling system.**

---

## 📋 Table of Contents

1. [What This System Does](#what-this-system-does)
2. [Requirements Checklist](#requirements-checklist)
3. [Account Setup (Do Once)](#account-setup-do-once)
4. [Deployment Steps](#deployment-steps)
5. [Testing & Verification](#testing--verification)
6. [Daily Operations](#daily-operations)
7. [Troubleshooting Common Issues](#troubleshooting-common-issues)
8. [Emergency Procedures](#emergency-procedures)
9. [Useful Commands Reference](#useful-commands-reference)

---

## 🎯 What This System Does

**Simple Explanation:**
This is an AI robot that answers phone calls automatically. When someone calls a phone number, the AI:
1. Answers the call
2. Listens to what they say
3. Thinks of a smart response (using Claude AI)
4. Speaks back with a natural human-like voice
5. Continues the conversation until they hang up

**Example conversation:**
```
Caller: "Hello, I need help with my order"
AI: "Hello! I'm here to help. What's your order number?"
Caller: "It's 12345"
AI: "Thank you! Let me look that up for you..."
```

---

## ✅ Requirements Checklist

### 1️⃣ **Accounts You Must Create (Free to start)**

| Account | Why Needed | Cost | Link |
|---------|------------|------|------|
| **Twilio** | Phone number & call handling | ~$20-30/mo | https://console.twilio.com |
| **Anthropic** | AI brain (Claude) | ~$10-20/mo | https://console.anthropic.com |
| **RunPod** | GPU server (for voice) | ~$290/mo (can optimize to $100) | https://runpod.io |
| **ngrok** (testing) | Expose server to internet | Free tier OK | https://ngrok.com |

**Total Cost: ~$320-340/month** (can reduce to $130-200 with optimization)

### 2️⃣ **Software You Must Install**

On your computer (Mac or Linux):

```bash
# Check if Docker is installed
docker --version

# If not installed, install from:
# https://docs.docker.com/get-docker/

# Check if Docker Compose is installed
docker-compose --version

# Usually comes with Docker Desktop
```

### 3️⃣ **Information You Must Collect**

Create a file called `credentials.txt` and save these (KEEP THIS FILE SAFE!):

```
TWILIO CREDENTIALS:
-------------------
Account SID: ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Auth Token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Phone Number: +15551234567

ANTHROPIC CREDENTIALS:
----------------------
API Key: sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

RUNPOD CREDENTIALS (if using cloud):
------------------------------------
API Key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxx

SERVER URL (will get this later):
----------------------------------
Ngrok URL: https://xxxx-xxx-xxx-xxx.ngrok.io
OR
Your Domain: https://voice.yourdomain.com
```

---

## 🔐 Account Setup (Do Once)

### Step 1: Create Twilio Account (15 minutes)

1. **Go to:** https://www.twilio.com/try-twilio
2. **Sign up** with your email
3. **Verify** your email and phone number
4. **Get a phone number:**
   - Click "Get a Trial Number" (or buy one for $1/month)
   - Choose a US number (starts with +1)
   - **SAVE THIS NUMBER** in your credentials.txt

5. **Get your credentials:**
   - Go to: https://console.twilio.com
   - Find "Account Info" section
   - Copy **Account SID** (starts with AC...)
   - Copy **Auth Token** (click to reveal)
   - **SAVE THESE** in your credentials.txt

**Screenshot of where to find credentials:**
```
Twilio Console → Dashboard → Account Info
┌─────────────────────────────┐
│ Account SID: ACxxxxxx       │  ← Copy this
│ Auth Token: [Show]          │  ← Click & copy this
└─────────────────────────────┘
```

### Step 2: Create Anthropic Account (10 minutes)

1. **Go to:** https://console.anthropic.com
2. **Sign up** with your email
3. **Get free credits:**
   - New accounts get $5 free credits
   - Enough for ~500-1000 AI responses

4. **Create API key:**
   - Click "API Keys" in left menu
   - Click "Create Key"
   - Give it a name: "Production TTS"
   - **COPY THE KEY IMMEDIATELY** (you can't see it again!)
   - **SAVE THIS** in your credentials.txt (starts with sk-ant-)

### Step 3: Create RunPod Account (10 minutes)

**Note:** Only needed for production. For testing, you can run locally on Mac.

1. **Go to:** https://runpod.io
2. **Sign up** with your email
3. **Add payment method** (credit card required)
4. **Get API key:**
   - Click your profile → Settings
   - Click "API Keys"
   - Create new key
   - **SAVE THIS** in your credentials.txt

### Step 4: Install ngrok (5 minutes)

**For testing only - makes your local server accessible from internet**

1. **Go to:** https://ngrok.com/download
2. **Download** for your operating system (Mac/Linux)
3. **Install:**
   ```bash
   # Mac
   brew install ngrok

   # Or download and unzip manually
   ```

4. **Sign up** (free account) at https://dashboard.ngrok.com
5. **Get auth token** from dashboard
6. **Configure:**
   ```bash
   ngrok authtoken YOUR_AUTH_TOKEN
   ```

---

## 🚀 Deployment Steps

### Option A: Quick Test (Local Computer - 20 minutes)

**Use this to test before deploying to production**

#### Step 1: Download the Code

```bash
# Open Terminal
cd ~
git clone <repository-url> chatterbox-ai
cd chatterbox-ai
```

**If you don't have git:**
- Download ZIP from repository
- Extract to folder called `chatterbox-ai`
- Open Terminal in that folder

#### Step 2: Configure Your Credentials

```bash
# Copy the template
cp .env.production.template .env.production

# Open in text editor
nano .env.production
```

**Fill in these values** (copy from your credentials.txt):

```bash
# Twilio
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+15551234567

# Anthropic
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Database password (auto-generated by script, or create your own)
POSTGRES_PASSWORD=<will be filled by script>

# Leave these as default for now
CHATTERBOX_PORT=8004
ENVIRONMENT=production
```

**Save and exit:**
- Press `Ctrl + X`
- Press `Y` to confirm
- Press `Enter`

#### Step 3: Deploy Automatically

```bash
# Run the one-command deployment script
./deploy_mvp.sh
```

**What this script does:**
1. ✅ Checks Docker is installed
2. ✅ Verifies your credentials are set
3. ✅ Generates secure database password
4. ✅ Builds and starts all services
5. ✅ Waits for everything to be ready
6. ✅ Shows you next steps

**Expected output:**
```
[1/7] Running pre-flight checks...
✅ Docker and Docker Compose are installed

[2/7] Configuring environment...
✅ Environment configured

[3/7] Applying security hardening...
✅ Security checks completed

[4/7] Creating required directories...
✅ Directories created

[5/7] Building and starting Docker services...
✅ Services started

[6/7] Waiting for services to be ready...
  ✅ Database is ready
  ✅ Redis is ready
  ✅ TTS server is ready

[7/7] Verifying deployment...
✅ Health check passed

╔════════════════════════════════════════════════════════════════════════╗
║  ✅ DEPLOYMENT SUCCESSFUL!                                             ║
╚════════════════════════════════════════════════════════════════════════╝
```

**If script fails, see [Troubleshooting Section](#troubleshooting-common-issues)**

#### Step 4: Expose to Internet (Testing)

**Open a NEW terminal window** (keep the first one running):

```bash
# Start ngrok
ngrok http 8004
```

**You'll see something like:**
```
Forwarding   https://a1b2-123-456-789.ngrok.io -> http://localhost:8004
```

**COPY THIS URL** - this is your webhook URL!

#### Step 5: Configure Twilio Webhook

1. **Go to:** https://console.twilio.com/us1/develop/phone-numbers/manage/incoming
2. **Click** on your phone number
3. **Scroll down** to "Voice Configuration"
4. **Find** "A CALL COMES IN" section
5. **Set:**
   - **Webhook:** `https://YOUR-NGROK-URL.ngrok.io/twilio/voice`
     - Example: `https://a1b2-123-456-789.ngrok.io/twilio/voice`
   - **HTTP Method:** POST
6. **Set** "Status Callback URL":
   - **URL:** `https://YOUR-NGROK-URL.ngrok.io/twilio/status`
7. **Click "Save"**

**Screenshot reference:**
```
Phone Numbers → Active Numbers → (Your Number)

Voice Configuration:
┌──────────────────────────────────────────────────┐
│ A CALL COMES IN                                  │
│ ● Webhook  ○ TwiML App  ○ Function              │
│                                                  │
│ URL: https://YOUR-URL.ngrok.io/twilio/voice     │
│ HTTP: [POST ▼]                                   │
│                                                  │
│ Status Callback URL:                             │
│ https://YOUR-URL.ngrok.io/twilio/status         │
└──────────────────────────────────────────────────┘
           [Save Configuration]
```

#### Step 6: Test the System

```bash
# Run automated tests
./test_twilio_webhook.sh

# Should show:
# ✅ Health check passed
# ✅ Voice webhook working
# ✅ Speech processing working
# ✅ TTS generation working
# ✅ LLM integration working
```

**Then make a real test call:**
1. Call your Twilio number from your phone
2. You should hear: "Hello! I'm your AI assistant. How can I help you today?"
3. Say something: "Hello, can you hear me?"
4. AI should respond!

**Check logs while testing:**
```bash
# In another terminal window
docker-compose logs -f chatterbox-tts
```

You should see:
```
Incoming call from +15551234567, SID: CAxxxx
Call CAxxxx: User said: Hello, can you hear me?
Generated audio saved to outputs/call_CAxxxx_20251007.wav
```

---

### Option B: Production (RunPod Cloud - 30 minutes)

**Use this for real customers, available 24/7**

#### Prerequisites:
- RunPod account created
- Payment method added
- API key saved

#### Step 1: Prepare Docker Image

```bash
# Login to Docker Hub (create account at hub.docker.com if needed)
docker login

# Build production image
docker build -t yourusername/chatterbox-tts:latest .

# Push to Docker Hub
docker push yourusername/chatterbox-tts:latest
```

#### Step 2: Deploy to RunPod

**Automated way:**
```bash
cd runpod/
export RUNPOD_API_KEY=your_api_key_here
./deploy_runpod.sh
```

**Manual way (via RunPod web console):**

1. **Go to:** https://runpod.io/console/pods
2. **Click:** "Deploy" → "GPU Pod"
3. **Choose GPU:**
   - Recommended: RTX 4090 (24GB) - ~$0.40/hr
   - Budget: RTX 3090 (24GB) - ~$0.20/hr
4. **Configure:**
   - **Template:** Docker
   - **Image:** `yourusername/chatterbox-tts:latest`
   - **Port:** 8004 (HTTP)
   - **Environment Variables:** (click "Add")
     ```
     TWILIO_ACCOUNT_SID=ACxxxx
     TWILIO_AUTH_TOKEN=xxxx
     TWILIO_PHONE_NUMBER=+1xxxx
     ANTHROPIC_API_KEY=sk-ant-xxxx
     POSTGRES_PASSWORD=your_secure_password
     ```
5. **Click:** "Deploy"

#### Step 3: Get Your RunPod URL

After deployment:
1. Wait ~2-3 minutes for pod to start
2. Go to "My Pods"
3. Click on your pod
4. Find "Connect" button
5. Copy the HTTPS URL (looks like: `https://xxxxx-8004.proxy.runpod.net`)

#### Step 4: Configure Twilio with RunPod URL

Same as testing setup, but use RunPod URL instead of ngrok:
- Webhook: `https://xxxxx-8004.proxy.runpod.net/twilio/voice`
- Status: `https://xxxxx-8004.proxy.runpod.net/twilio/status`

---

## 🧪 Testing & Verification

### Pre-Launch Testing Checklist

**Run these tests BEFORE giving number to customers:**

#### 1. Automated Tests

```bash
./test_twilio_webhook.sh https://your-server-url.com
```

**Expected result:** All 5 tests pass ✅

#### 2. Manual Call Test

| Test | What to Do | Expected Result |
|------|------------|-----------------|
| **Basic Call** | Call the number | Hear greeting within 2 seconds |
| **Speech Recognition** | Say "Hello" | AI responds appropriately |
| **Voice Quality** | Listen to AI voice | Clear, natural, no distortion |
| **Response Time** | Ask a question | AI responds within 5 seconds |
| **Long Conversation** | Talk for 5 minutes | No crashes or disconnects |
| **Concurrent Calls** | Have 2 people call at once | Both calls work simultaneously |
| **Error Handling** | Say gibberish | AI handles gracefully |
| **Hang Up** | End the call | Call ends properly, no errors in logs |

#### 3. Check Logs

```bash
# View logs
docker-compose logs -f chatterbox-tts

# Look for these messages:
✓ "Incoming call from..." - Call received
✓ "User said: ..." - Speech recognized
✓ "Generated audio saved..." - TTS working
✓ No ERROR messages

# Check for errors
docker-compose logs | grep ERROR
# Should return nothing or only minor warnings
```

#### 4. Monitor Performance

```bash
# Check health endpoint
curl https://your-url/health

# Should return:
{
  "status": "healthy",
  "components": {
    "tts_model": true,
    "llm_client": true,
    "twilio_client": true,
    "database": true,
    "redis": true
  }
}
```

---

## 📅 Daily Operations

### Morning Routine (5 minutes)

**Check everything is running:**

```bash
# 1. Check services status
docker-compose ps

# Should show:
# chatterbox-tts       Up
# postgres             Up (healthy)
# redis                Up (healthy)

# 2. Check health
curl https://your-url/health

# 3. View overnight logs for errors
docker-compose logs --since 12h | grep ERROR
```

### Monitor Calls

**View active calls:**
```bash
# Real-time log monitoring
docker-compose logs -f chatterbox-tts | grep "Incoming call"
```

**Check Twilio Console:**
- Go to: https://console.twilio.com → Monitor → Logs → Calls
- See all calls, durations, costs
- Listen to call recordings (if enabled)

### Weekly Maintenance (15 minutes)

**Every Monday:**

1. **Check costs:**
   - Twilio: https://console.twilio.com → Monitor → Usage
   - Anthropic: https://console.anthropic.com → Usage
   - RunPod: https://runpod.io → Billing

2. **Review logs:**
   ```bash
   # Check for repeated errors
   docker-compose logs --since 7d | grep ERROR | sort | uniq -c | sort -rn
   ```

3. **Backup database:**
   ```bash
   # Create backup
   docker-compose exec -T postgres pg_dump -U postgres chatterbox | gzip > backup_$(date +%Y%m%d).sql.gz

   # Keep last 30 days
   find . -name "backup_*.sql.gz" -mtime +30 -delete
   ```

4. **Update dependencies:**
   ```bash
   # Check for updates
   docker-compose pull
   docker-compose up -d
   ```

---

## 🔧 Troubleshooting Common Issues

### Issue 1: "Services won't start"

**Symptoms:**
```bash
docker-compose ps
# Shows "Exit" or "Restarting"
```

**Fix:**
```bash
# Check what's wrong
docker-compose logs chatterbox-tts

# Common causes:
# 1. Port already in use
sudo lsof -i :8004
# Kill the process using port 8004

# 2. Not enough memory
# Close other applications

# 3. Docker daemon not running
# Start Docker Desktop application

# Restart services
docker-compose down
docker-compose up -d
```

### Issue 2: "Twilio webhook times out"

**Symptoms:**
- Call connects but hangs
- Twilio shows "11200 HTTP retrieval failure" error

**Check latency:**
```bash
# Monitor response times
docker-compose logs -f | grep "Generated"

# Look for timing like:
# Generated 2.5s audio in 500ms ✅ Good
# Generated 2.5s audio in 15000ms ❌ Too slow
```

**Fix:**
```bash
# If on CPU (too slow):
# 1. Deploy to RunPod with GPU
# 2. Or reduce text length in responses

# Check GPU is being used:
docker-compose exec chatterbox-tts python -c "import torch; print(torch.cuda.is_available())"
# Should print: True
```

### Issue 3: "No audio on call"

**Symptoms:**
- Call connects
- AI speaks but caller hears nothing

**Debug steps:**

1. **Test TTS directly:**
   ```bash
   curl -X POST http://localhost:8004/tts \
     -H "Content-Type: application/json" \
     -d '{"text":"This is a test"}' \
     --output test.wav

   # Play the file
   afplay test.wav  # Mac
   aplay test.wav   # Linux

   # If this works, TTS is fine
   ```

2. **Check webhook URL:**
   ```bash
   # Test webhook from Twilio's perspective
   curl -X POST https://your-url/twilio/voice \
     -d "CallSid=TEST123" \
     -d "From=+15551234567"

   # Should return XML like:
   # <Response><Say>Hello! I'm your AI assistant...</Say>...</Response>
   ```

3. **Verify HTTPS:**
   - Webhook MUST be HTTPS (not HTTP)
   - Check Twilio console webhook URL starts with `https://`

### Issue 4: "AI gives wrong responses"

**Symptoms:**
- AI doesn't understand questions
- Gives irrelevant answers

**Fix:**

1. **Check LLM connection:**
   ```bash
   curl -X POST http://localhost:8004/llm \
     -H "Content-Type: application/json" \
     -d '{"prompt":"Say hello"}'

   # Should return JSON with response
   ```

2. **Verify API key:**
   ```bash
   # Check environment
   docker-compose exec chatterbox-tts env | grep ANTHROPIC_API_KEY
   # Should show your key (sk-ant-...)
   ```

3. **Improve AI personality:**
   ```bash
   # Edit the system prompt
   nano scripts/server.py

   # Find line 454 and add:
   messages=[
       {
           "role": "system",
           "content": "You are a helpful assistant for [YOUR COMPANY]. Be concise and professional."
       },
       {"role": "user", "content": request.prompt}
   ]

   # Restart
   docker-compose restart chatterbox-tts
   ```

### Issue 5: "High costs"

**Symptoms:**
- Unexpected bills from Twilio/Anthropic/RunPod

**Check usage:**
```bash
# Count calls today
docker-compose logs --since 24h | grep "Incoming call" | wc -l

# Check average call duration
# Go to: https://console.twilio.com → Monitor → Usage
```

**Reduce costs:**

1. **Use spot instances (RunPod):**
   - 50% cheaper than on-demand
   - May be interrupted (auto-restart)

2. **Auto-shutdown (RunPod):**
   ```bash
   # In RunPod console:
   # Pod Settings → Auto-Stop → Enable
   # Set: Stop after 1 hour of no activity
   ```

3. **Shorter responses:**
   ```python
   # In config/config.yaml
   llm:
     max_tokens: 75  # Reduce from 150
   ```

4. **Business hours only:**
   - Stop services outside business hours
   ```bash
   # Cron job to stop at 6pm, start at 8am
   0 18 * * * cd /path/to/chatterbox && docker-compose down
   0 8 * * * cd /path/to/chatterbox && docker-compose up -d
   ```

---

## 🚨 Emergency Procedures

### Emergency 1: Need to Stop Everything NOW

**Situation:** System under attack, too many calls, or other emergency

```bash
# STOP ALL SERVICES IMMEDIATELY
docker-compose down

# If that doesn't work:
docker-compose kill

# Block all incoming traffic (Linux)
sudo ufw deny 8004
```

**To restart later:**
```bash
docker-compose up -d
```

### Emergency 2: Database Corrupted

**Symptoms:** Can't start services, database errors in logs

```bash
# Restore from backup
docker-compose down
docker-compose up -d postgres

# Wait for postgres to start
sleep 10

# Restore latest backup
gunzip < backup_20251007.sql.gz | docker-compose exec -T postgres psql -U postgres chatterbox

# Restart services
docker-compose restart
```

### Emergency 3: Compromised API Keys

**If you suspect API keys were stolen:**

1. **Immediately revoke Twilio token:**
   - Go to: https://console.twilio.com → Settings → API Credentials
   - Click "Delete" on Auth Token
   - Generate new one

2. **Rotate Anthropic key:**
   - Go to: https://console.anthropic.com → API Keys
   - Delete old key
   - Create new key

3. **Update system:**
   ```bash
   # Edit .env.production with new keys
   nano .env.production

   # Restart services
   docker-compose down
   docker-compose up -d
   ```

### Emergency 4: Server Crashed

**If entire server is down:**

```bash
# Check what's using resources
top
# Press 'q' to quit

# Check disk space
df -h
# If disk is full (>90%), clean up:
docker system prune -a  # Remove unused Docker data
find outputs/ -type f -mtime +1 -delete  # Delete old audio files

# Check Docker daemon
sudo systemctl status docker
sudo systemctl restart docker

# Restart services
cd /path/to/chatterbox
docker-compose down
docker-compose up -d
```

---

## 📖 Useful Commands Reference

### Service Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart specific service
docker-compose restart chatterbox-tts

# View status
docker-compose ps

# View logs (live)
docker-compose logs -f

# View logs (last 100 lines)
docker-compose logs --tail=100

# View logs from last 24 hours
docker-compose logs --since 24h
```

### Monitoring

```bash
# Check health
curl http://localhost:8004/health

# Test TTS
curl -X POST http://localhost:8004/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello world"}' \
  --output test.wav

# Count today's calls
docker-compose logs --since 24h | grep "Incoming call" | wc -l

# Check errors
docker-compose logs | grep ERROR | tail -20
```

### Database

```bash
# Access database
docker-compose exec postgres psql -U postgres chatterbox

# Common queries:
SELECT COUNT(*) FROM request_logs WHERE created_at > NOW() - INTERVAL '24 hours';
SELECT * FROM api_keys WHERE status='active';

# Exit database
\q
```

### Backup & Restore

```bash
# Create backup
docker-compose exec -T postgres pg_dump -U postgres chatterbox | gzip > backup_$(date +%Y%m%d).sql.gz

# Restore backup
gunzip < backup_20251007.sql.gz | docker-compose exec -T postgres psql -U postgres chatterbox

# List backups
ls -lh backup_*.sql.gz
```

### Configuration

```bash
# View current config
cat .env.production

# Edit config
nano .env.production

# View application config
cat config/config.yaml

# After changing config:
docker-compose restart chatterbox-tts
```

---

## 📞 Quick Contact Info

### Support Resources

**Documentation:**
- Quick Start: `QUICK_START_MVP.md`
- Security: `SECURITY_CHECKLIST_MVP.md`
- Full Setup: `MVP_PRODUCTION_SETUP.md`

**External Services:**
- Twilio Console: https://console.twilio.com
- Anthropic Console: https://console.anthropic.com
- RunPod Console: https://runpod.io
- ngrok Dashboard: https://dashboard.ngrok.com

**Checking Service Status:**
- Twilio Status: https://status.twilio.com
- Anthropic Status: https://status.anthropic.com
- RunPod Status: https://status.runpod.io

---

## ✅ Final Checklist for Ayeye

**Before handing off to customers:**

- [ ] All accounts created (Twilio, Anthropic, RunPod)
- [ ] Credentials saved securely in `credentials.txt`
- [ ] System deployed and tested
- [ ] Test call successful
- [ ] Monitoring set up
- [ ] Backup automation configured
- [ ] Emergency procedures understood
- [ ] Daily check routine established
- [ ] Boss contact info for escalations saved

**Daily Tasks:**
- [ ] Check services are running (5 min)
- [ ] Review error logs (5 min)
- [ ] Monitor costs (2 min)

**Weekly Tasks:**
- [ ] Create database backup (5 min)
- [ ] Review all logs for patterns (10 min)
- [ ] Check for software updates (5 min)

---

## 📝 Notes Section for Ayeye

**Use this space to keep track of important information:**

```
IMPORTANT CONTACTS:
-------------------
Boss Phone: _______________
Boss Email: _______________
Emergency Contact: _______________

SERVER INFORMATION:
-------------------
Server URL: _______________
Twilio Number: _______________
Last Backup Date: _______________

KNOWN ISSUES:
-------------
1.
2.
3.

CUSTOMER FEEDBACK:
------------------
Date | Feedback | Action Taken
-----|----------|-------------
     |          |
     |          |
     |          |
```

---

**🎉 You're all set! If you can follow these steps, the system will run smoothly.**

**Remember:**
- Check logs daily
- Back up weekly
- Call boss if something breaks that you can't fix
- Keep credentials.txt safe and secret!

---

*Created: 2025-10-07*
*For: Ayeye (Assistant)*
*By: Boss (Expat)*
