# ✅ Ayeye's Setup Checklist - Print This!

**Date Started: _______________**

---

## 📋 PHASE 1: Account Setup (Day 1)

### Twilio Account
- [ ] Created account at twilio.com
- [ ] Verified email address
- [ ] Verified phone number
- [ ] Got trial phone number (or purchased for $1)
- [ ] Phone number: _______________________
- [ ] Copied Account SID (starts with AC...)
- [ ] Copied Auth Token (click to reveal)
- [ ] Saved both in credentials.txt file

### Anthropic Account
- [ ] Created account at console.anthropic.com
- [ ] Verified email
- [ ] Created API key (starts with sk-ant-)
- [ ] Copied key IMMEDIATELY (can't see again!)
- [ ] Saved in credentials.txt file
- [ ] Checked I have $5 free credits

### RunPod Account (for production)
- [ ] Created account at runpod.io
- [ ] Added credit card for billing
- [ ] Created API key
- [ ] Saved API key in credentials.txt
- [ ] Understood cost: ~$290/month for 24/7

### ngrok (for testing)
- [ ] Downloaded from ngrok.com
- [ ] Installed on computer
- [ ] Created free account
- [ ] Got auth token from dashboard
- [ ] Ran: `ngrok authtoken YOUR_TOKEN`

---

## 🔐 PHASE 2: Security (Day 1)

### Credentials File
- [ ] Created credentials.txt file
- [ ] Saved all account info
- [ ] Put file in safe place (NOT on public computer)
- [ ] Made backup copy
- [ ] Did NOT commit to git
- [ ] Did NOT share with anyone except boss

### Passwords
- [ ] Used strong passwords (12+ characters)
- [ ] Each service has different password
- [ ] Saved passwords in password manager

---

## 💻 PHASE 3: Software Setup (Day 1)

### Check Installations
- [ ] Ran: `docker --version`
  - Result: _______________
- [ ] Ran: `docker-compose --version`
  - Result: _______________
- [ ] If not installed, installed Docker Desktop
- [ ] Docker Desktop is running (icon in menu bar)

### Download Code
- [ ] Downloaded code to computer
- [ ] Extracted to folder: chatterbox-ai
- [ ] Can open Terminal in that folder
- [ ] Ran: `ls` and see files listed

---

## 🚀 PHASE 4: First Deployment (Day 1-2)

### Configure Environment
- [ ] Ran: `cp .env.production.template .env.production`
- [ ] Opened .env.production in text editor
- [ ] Added TWILIO_ACCOUNT_SID
- [ ] Added TWILIO_AUTH_TOKEN
- [ ] Added TWILIO_PHONE_NUMBER
- [ ] Added ANTHROPIC_API_KEY
- [ ] Saved file

### Run Deployment Script
- [ ] Ran: `chmod +x deploy_mvp.sh`
- [ ] Ran: `./deploy_mvp.sh`
- [ ] Script showed: "DEPLOYMENT SUCCESSFUL"
- [ ] No red error messages
- [ ] Services are running

### Check Services Started
- [ ] Ran: `docker-compose ps`
- [ ] See chatterbox-tts: Up
- [ ] See postgres: Up (healthy)
- [ ] See redis: Up (healthy)

---

## 🌐 PHASE 5: Expose to Internet (Day 2)

### Start ngrok
- [ ] Opened NEW terminal window
- [ ] Ran: `ngrok http 8004`
- [ ] See "Forwarding" line with https:// URL
- [ ] Copied the https:// URL
- [ ] ngrok URL: _______________________
- [ ] Left this terminal window open

### Configure Twilio Webhook
- [ ] Went to: console.twilio.com → Phone Numbers
- [ ] Clicked my phone number
- [ ] Found "Voice Configuration" section
- [ ] Set "A CALL COMES IN" to Webhook
- [ ] Pasted ngrok URL + /twilio/voice
  - Example: https://abc123.ngrok.io/twilio/voice
- [ ] Set HTTP method to POST
- [ ] Set "Status Callback URL" to ngrok URL + /twilio/status
- [ ] Clicked Save
- [ ] Saw "Saved" confirmation

---

## 🧪 PHASE 6: Testing (Day 2)

### Automated Tests
- [ ] Ran: `./test_twilio_webhook.sh`
- [ ] Test 1: Health Check - PASSED ✅
- [ ] Test 2: Voice Webhook - PASSED ✅
- [ ] Test 3: Speech Processing - PASSED ✅
- [ ] Test 4: TTS Generation - PASSED ✅
- [ ] Test 5: LLM Integration - PASSED ✅

### Manual Test Call
- [ ] Called Twilio number from my phone
- [ ] Heard greeting within 3 seconds
- [ ] Greeting was clear and natural
- [ ] Said: "Hello, can you hear me?"
- [ ] AI responded appropriately
- [ ] Voice was clear and natural
- [ ] Response time was under 5 seconds

### Check Logs
- [ ] Ran: `docker-compose logs -f chatterbox-tts`
- [ ] Saw "Incoming call from..." message
- [ ] Saw "User said: ..." message
- [ ] Saw "Generated audio..." message
- [ ] No ERROR messages in red

---

## 🎯 PHASE 7: Production Deployment (Day 3)

**Only if test was successful!**

### RunPod Deployment
- [ ] Logged into runpod.io
- [ ] Clicked "Deploy" → "GPU Pod"
- [ ] Selected RTX 4090 (or RTX 3090)
- [ ] Set Docker image name
- [ ] Added all environment variables
- [ ] Clicked Deploy
- [ ] Waited 3 minutes for startup
- [ ] Got RunPod URL: _______________________

### Update Twilio for Production
- [ ] Went to Twilio console
- [ ] Updated webhook URL to RunPod URL
  - Old: ngrok URL
  - New: RunPod URL + /twilio/voice
- [ ] Updated status callback to RunPod URL + /twilio/status
- [ ] Clicked Save

### Final Production Test
- [ ] Called number again
- [ ] AI answered (using RunPod now)
- [ ] Had full conversation (2+ minutes)
- [ ] Checked RunPod logs for errors
- [ ] Everything working!

---

## 📊 PHASE 8: Monitoring Setup (Day 3)

### Daily Monitoring
- [ ] Created bookmark: https://console.twilio.com
- [ ] Created bookmark: https://console.anthropic.com
- [ ] Created bookmark: https://runpod.io
- [ ] Created bookmark: Server health URL
- [ ] Set up phone reminder to check daily

### Cost Tracking
- [ ] Checked Twilio usage page
- [ ] Checked Anthropic usage page
- [ ] Checked RunPod billing
- [ ] Current costs: $______/day
- [ ] Projected monthly: $______/month

---

## 📚 PHASE 9: Learn Operations (Week 1)

### Commands Practiced
- [ ] `docker-compose ps` - Check status
- [ ] `docker-compose logs -f` - View logs
- [ ] `docker-compose restart` - Restart service
- [ ] `docker-compose down` - Stop everything
- [ ] `docker-compose up -d` - Start everything
- [ ] `curl localhost:8004/health` - Check health

### Troubleshooting Practice
- [ ] Read AYEYE_COMPLETE_GUIDE.md fully
- [ ] Practiced stopping/starting services
- [ ] Practiced viewing logs
- [ ] Know where to find error messages
- [ ] Know when to call boss

---

## 🎓 PHASE 10: Handoff Complete (Week 1)

### Documentation
- [ ] Read all .md files in project
- [ ] Understand what each file does
- [ ] Bookmarked important documentation
- [ ] Created notes in AYEYE_COMPLETE_GUIDE.md

### Confidence Check
- [ ] Can start/stop services
- [ ] Can read logs
- [ ] Can check if system is healthy
- [ ] Can make test calls
- [ ] Know what to do if system crashes
- [ ] Know when to escalate to boss

### Boss Handoff
- [ ] Showed boss system is working
- [ ] Demonstrated daily check routine
- [ ] Explained cost structure
- [ ] Boss approved operation plan
- [ ] Boss gave contact info for emergencies
- [ ] Boss confirmed I can manage this

---

## 📅 ONGOING: Daily Tasks

**Print this and check daily:**

### Morning Check (5 minutes) - Every Day
```
Date: ___/___/___

- [ ] Ran: docker-compose ps (all Up?)
- [ ] Ran: curl localhost:8004/health (healthy?)
- [ ] Checked logs for errors: docker-compose logs --since 12h | grep ERROR
- [ ] Result: ✅ Everything OK  or  ❌ Issue found: _______________
```

### Weekly Backup (15 minutes) - Every Monday
```
Week of: ___/___/___

- [ ] Created database backup
- [ ] Checked all costs (Twilio, Anthropic, RunPod)
- [ ] Reviewed error logs for patterns
- [ ] Updated boss on status
```

### Monthly Review (30 minutes) - First of Month
```
Month: _______________

- [ ] Reviewed total costs: $_______
- [ ] Reviewed total calls: _______
- [ ] Checked for software updates
- [ ] Tested emergency shutdown procedure
- [ ] Verified backups are working
```

---

## 🚨 EMERGENCY CONTACTS

**Fill this out and keep nearby:**

```
BOSS CONTACT:
Name: _______________________
Phone: ______________________
Email: ______________________
Best time to call: ___________

ESCALATION PROCEDURE:
1. Try to fix using AYEYE_COMPLETE_GUIDE.md
2. If can't fix in 15 minutes, call boss
3. If boss unavailable and system down, run: docker-compose down

CRITICAL NUMBERS:
Server URL: _______________________
Twilio Number: ____________________
RunPod Pod ID: ____________________
```

---

## ✅ FINAL SIGN-OFF

**When all phases complete:**

```
I, _________________ (name), confirm that:

- [ ] All phases completed successfully
- [ ] System is running and answering calls
- [ ] I understand how to operate the system
- [ ] I know when to escalate to boss
- [ ] I can handle daily operations independently

Signed: _______________  Date: _______________

Boss Approval: _______________  Date: _______________
```

---

## 📱 Quick Reference Card (Cut this out and keep at desk)

```
╔══════════════════════════════════════════════════════╗
║  AI VOICE SYSTEM - QUICK REFERENCE                   ║
╠══════════════════════════════════════════════════════╣
║                                                      ║
║  CHECK HEALTH:                                       ║
║  curl localhost:8004/health                          ║
║                                                      ║
║  VIEW LOGS:                                          ║
║  docker-compose logs -f                              ║
║                                                      ║
║  RESTART SYSTEM:                                     ║
║  docker-compose restart chatterbox-tts               ║
║                                                      ║
║  STOP EVERYTHING (Emergency):                        ║
║  docker-compose down                                 ║
║                                                      ║
║  START EVERYTHING:                                   ║
║  docker-compose up -d                                ║
║                                                      ║
║  TEST CALL:                                          ║
║  Call: _________________ (Twilio number)             ║
║                                                      ║
║  BOSS PHONE: _________________                       ║
║                                                      ║
╚══════════════════════════════════════════════════════╝
```

---

**🎉 Good luck Ayeye! You can do this!**

*Remember: Read AYEYE_COMPLETE_GUIDE.md when you need detailed help*
