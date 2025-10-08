# 🔧 Simple Troubleshooting Guide for Ayeye

**When something goes wrong, follow these steps in order.**

---

## 🚨 Quick Decision Tree

```
START: Something is broken
         │
         ▼
    Is it urgent?
    (Customers affected?)
         │
    ┌────┴────┐
   YES       NO
    │         │
    ▼         ▼
Call Boss   Try to fix
            (15 min max)
                │
           ┌────┴────┐
      Fixed it    Still broken
           │              │
           ▼              ▼
      Document      Call Boss
```

---

## ❓ Problem: "I don't know what's wrong"

**Step 1: Check the basics**

```bash
# Run this command
docker-compose ps
```

**Look at the output:**

✅ **Good - Everything says "Up":**
```
NAME               STATUS
chatterbox-tts     Up 2 hours
postgres           Up 2 hours (healthy)
redis              Up 2 hours (healthy)
```
→ Services are running, skip to next section

❌ **Bad - Something says "Exit" or "Restarting":**
```
NAME               STATUS
chatterbox-tts     Exit 1
```
→ Go to "Services Won't Start" section below

---

## Problem 1: Services Won't Start

**When:** `docker-compose ps` shows "Exit" or not listed

### Fix Attempt 1: Simple Restart

```bash
# Stop everything
docker-compose down

# Wait 5 seconds
sleep 5

# Start everything
docker-compose up -d

# Check again
docker-compose ps
```

**Did it work?**
- ✅ YES: Everything shows "Up" → Problem solved!
- ❌ NO: Still showing "Exit" → Try Fix Attempt 2

### Fix Attempt 2: Check What's Wrong

```bash
# Look at the error messages
docker-compose logs chatterbox-tts | tail -50
```

**Common errors and fixes:**

| Error Message | What it Means | Fix |
|---------------|---------------|-----|
| `Port 8004 already in use` | Something else using port | Run: `sudo lsof -i :8004` then kill that process |
| `Cannot connect to database` | Database not ready | Wait 30 seconds, try again |
| `Out of memory` | Not enough RAM | Close other programs, restart |
| `Permission denied` | Docker permissions | Run: `sudo chmod 666 /var/run/docker.sock` |

### Fix Attempt 3: Fresh Start

```bash
# Nuclear option - start completely fresh
docker-compose down
docker-compose rm -f
docker-compose pull
docker-compose up -d
```

**Still not working?** → Call Boss 📞

---

## Problem 2: Calls Not Connecting

**When:** Someone calls but nothing happens

### Quick Checks:

#### Check 1: Is server running?

```bash
docker-compose ps
```
→ All services should show "Up"

#### Check 2: Is server reachable from internet?

```bash
# Test your webhook URL
curl https://your-url-here.com/twilio/voice

# Should return XML starting with: <Response>
```

If you get error:
- `Connection refused` → ngrok not running or server down
- `404 Not Found` → Wrong URL
- `Timeout` → Firewall blocking

#### Check 3: Is Twilio configured correctly?

1. Go to: https://console.twilio.com
2. Click: Phone Numbers → Your Number
3. Verify webhook URL is: `https://YOUR-URL/twilio/voice`
4. Verify method is: `POST`

**Common mistakes:**
- ❌ `http://` instead of `https://`
- ❌ Forgot `/twilio/voice` at the end
- ❌ Method is GET instead of POST

### Fix: Update Twilio webhook

1. If using **ngrok** (testing):
   ```bash
   # In terminal, check ngrok is running
   # Should see: Forwarding https://xxxx.ngrok.io

   # Copy that URL + /twilio/voice
   # Update in Twilio console
   ```

2. If using **RunPod** (production):
   - Get URL from RunPod console
   - Should look like: `https://xxxxx-8004.proxy.runpod.net`
   - Update in Twilio console

**Still not working?** → Call Boss 📞

---

## Problem 3: AI Not Responding or Responding Badly

**When:** Call connects but AI gives weird answers or no answer

### Check 1: Is LLM working?

```bash
# Test the AI directly
curl -X POST http://localhost:8004/llm \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Say hello"}'
```

**Expected:** Should return JSON with AI response

**If error:**
- `LLM client not initialized` → API key not set
- `Authentication failed` → API key wrong
- `Rate limit exceeded` → Used too many requests

### Fix 1: Check API Key

```bash
# View environment variables
cat .env.production | grep ANTHROPIC_API_KEY

# Should show: ANTHROPIC_API_KEY=sk-ant-xxxxx
# If empty or wrong, fix it:
nano .env.production

# Save, then restart:
docker-compose restart chatterbox-tts
```

### Fix 2: Check Credits

1. Go to: https://console.anthropic.com
2. Check "Usage" page
3. Make sure you have credits left
4. If out of credits, add payment method

**Still not working?** → Call Boss 📞

---

## Problem 4: Voice Quality Bad or No Voice

**When:** AI speaks but sounds bad or caller hears nothing

### Check 1: Test TTS directly

```bash
# Generate test audio
curl -X POST http://localhost:8004/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"This is a test"}' \
  --output test.wav

# Play it
afplay test.wav  # Mac
# OR
aplay test.wav   # Linux
```

**If audio is good:** Problem is with Twilio, not TTS
**If audio is bad/silent:** Problem is with TTS

### Fix 1: Check GPU is being used

```bash
# Check if GPU is available
docker-compose exec chatterbox-tts python -c "import torch; print('GPU:', torch.cuda.is_available())"
```

**Expected:** `GPU: True`

**If shows False:** Running on CPU (too slow)
- Solution: Deploy to RunPod with GPU

### Fix 2: Adjust voice settings

```bash
# Edit config
nano config/config.yaml

# Find these lines and adjust:
generation_defaults:
  exaggeration: 1.0  # Lower = more neutral (try 0.8-1.5)
  temperature: 0.8   # Lower = more consistent

# Save and restart
docker-compose restart chatterbox-tts
```

**Still not working?** → Call Boss 📞

---

## Problem 5: System Too Slow

**When:** Takes more than 10 seconds to respond

### Check response time:

```bash
# Watch logs while making a call
docker-compose logs -f chatterbox-tts | grep "Generated"

# Look for lines like:
# Generated 2.5s audio in 800ms ✅ Good (under 1 second)
# Generated 2.5s audio in 15000ms ❌ Bad (15 seconds!)
```

### Fix 1: Check what's slow

**If TTS is slow (>5 seconds):**
- Running on CPU instead of GPU
- Solution: Deploy to RunPod

**If LLM is slow (>5 seconds):**
- Anthropic API might be slow
- Check: https://status.anthropic.com
- Try reducing max_tokens in config

**If everything is slow:**
- Server overloaded
- Check: `docker stats` to see CPU/memory usage
- Solution: Upgrade server or use RunPod

**Still not working?** → Call Boss 📞

---

## Problem 6: Costs Too High

**When:** Bills are higher than expected

### Check 1: Count calls

```bash
# Count calls in last 24 hours
docker-compose logs --since 24h | grep "Incoming call" | wc -l
```

**Expected:** Should match your business volume

**If unexpectedly high:** Someone might be spam calling

### Check 2: Review costs

1. **Twilio:** https://console.twilio.com → Monitor → Usage
2. **Anthropic:** https://console.anthropic.com → Usage
3. **RunPod:** https://runpod.io → Billing

### Fix 1: Enable auto-shutdown (RunPod)

If running 24/7 but only need business hours:

1. Go to RunPod console
2. Click on your pod
3. Settings → Auto-Stop
4. Enable: "Stop after 1 hour of no activity"

**Savings:** Up to 70% reduction in costs!

### Fix 2: Use spot instances (RunPod)

1. When deploying pod, choose "Spot" instead of "On-Demand"
2. Cost: $0.20/hr instead of $0.40/hr
3. Risk: May be interrupted (auto-restarts)

**Savings:** 50% reduction in GPU costs!

**Still too expensive?** → Call Boss 📞

---

## Problem 7: Database Issues

**When:** Services won't start, database errors in logs

### Fix 1: Restart database

```bash
# Restart just the database
docker-compose restart postgres

# Wait 30 seconds
sleep 30

# Restart main service
docker-compose restart chatterbox-tts
```

### Fix 2: Check database is healthy

```bash
# Check database status
docker-compose exec postgres pg_isready -U postgres

# Should show: accepting connections
```

### Fix 3: Restore from backup

**Only if database is corrupted!**

```bash
# Stop services
docker-compose down

# Start only database
docker-compose up -d postgres

# Wait for it to start
sleep 10

# Restore latest backup
ls -lt backup_*.sql.gz | head -1  # Shows latest backup
gunzip < backup_YYYYMMDD.sql.gz | docker-compose exec -T postgres psql -U postgres chatterbox

# Restart everything
docker-compose down
docker-compose up -d
```

**Still not working?** → Call Boss 📞

---

## 🆘 When to Call Boss Immediately

Call boss RIGHT AWAY if:

1. **System is down and customers are calling** (urgent!)
2. **You tried fixes for 15 minutes and nothing works**
3. **You see security warnings or "hacked" messages**
4. **Costs suddenly spiked 10x normal**
5. **Database won't start after restore**
6. **You're not sure what's wrong and it's affecting customers**

---

## 📝 Template for Reporting Issues to Boss

**When you call boss, have this information ready:**

```
ISSUE REPORT:
-------------
Date/Time: _______________
Problem: (describe in 1 sentence)
_________________________________

What happened before the problem:
_________________________________

What I tried:
1.
2.
3.

Current status:
- Services running? Yes/No
- Customers affected? Yes/No
- Error messages:
_________________________________

Logs (copy and paste):
```
docker-compose logs --tail 50
```
```

**This helps boss fix it faster!**

---

## ✅ Daily Prevention Checklist

**Do this every morning to catch problems early:**

```
DAILY CHECK - Date: ___/___/___

1. [ ] Run: docker-compose ps
   Result: All "Up"? _____

2. [ ] Run: curl localhost:8004/health
   Result: "healthy"? _____

3. [ ] Check logs for errors:
   docker-compose logs --since 12h | grep ERROR
   Any errors? _____

4. [ ] Make test call
   Working? _____

5. [ ] Check costs
   Within budget? _____

If ALL checks pass: ✅ Everything OK!
If ANY check fails: 🔧 Fix it or call boss
```

---

## 🎯 Summary: Most Common Problems

| Symptom | Most Likely Cause | Quick Fix |
|---------|-------------------|-----------|
| Services won't start | Port conflict or Docker issue | `docker-compose down && docker-compose up -d` |
| Calls not connecting | Webhook URL wrong | Check Twilio console, update URL |
| AI not responding | API key missing/wrong | Check .env.production file |
| Very slow responses | Running on CPU not GPU | Deploy to RunPod |
| No voice on call | Webhook not HTTPS | Change http:// to https:// in Twilio |
| High costs | Running 24/7 unnecessarily | Enable auto-shutdown on RunPod |

---

## 📞 Emergency Contact Card

**Print this and keep at your desk:**

```
╔═══════════════════════════════════════════╗
║     EMERGENCY CONTACT INFORMATION         ║
╠═══════════════════════════════════════════╣
║                                           ║
║  Boss Name: _______________               ║
║  Boss Phone: _______________              ║
║  Boss Email: _______________              ║
║                                           ║
║  Server URL: _______________              ║
║  Twilio #: _______________                ║
║                                           ║
║  EMERGENCY SHUTDOWN:                      ║
║  docker-compose down                      ║
║                                           ║
╚═══════════════════════════════════════════╝
```

---

**Remember: It's okay to call boss if you're stuck! Better to ask than to break something!**

🎉 **You got this Ayeye!**
