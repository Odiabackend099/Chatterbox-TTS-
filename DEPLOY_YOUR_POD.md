# 🚀 Deploy to YOUR RunPod Pod

**Pod ID**: a288y3vpbfxwkk  
**Ready to deploy NOW!**

---

## ⚡ COPY & PASTE DEPLOYMENT (2 Minutes)

### Step 1: SSH to Your Pod

**Option A - RunPod SSH** (Recommended):
```bash
ssh a288y3vpbfxwkk-6441165c@ssh.runpod.io -i ~/.ssh/id_ed25519
```

**Option B - Direct SSH**:
```bash
ssh root@213.173.108.103 -p 14814 -i ~/.ssh/id_ed25519
```

---

### Step 2: Run Deployment Script

Once connected, copy and paste this ONE command:

```bash
curl -sSL https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh | bash
```

**That's it!** ✨

The script will:
- Install dependencies
- Clone your GitHub repo
- Setup environment
- Start TTS service on port 8004
- Test everything automatically

---

## 🎬 What You'll See

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Chatterbox TTS - RunPod Deployment
  Pod ID: a288y3vpbfxwkk
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ System dependencies installed
✓ Repository ready
✓ Python dependencies installed
✓ Environment configured
✓ Directories created
✓ GPU Check (CUDA available: True)
✓ TTS service started
✓ Service is responding

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ Deployment Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your TTS Service URLs:
  Local:  http://localhost:8004
  Public: https://a288y3vpbfxwkk-8004.proxy.runpod.net

🎉 Ready to use!
```

---

## ✅ Verify Deployment

### From RunPod Terminal:

```bash
# Check health
curl http://localhost:8004/health

# View logs
tail -f /workspace/chatterbox-twilio-integration/logs/tts.log

# Check process
ps aux | grep server_production
```

---

### From Your Mac:

```bash
# Test health endpoint
curl https://a288y3vpbfxwkk-8004.proxy.runpod.net/health

# Quick TTS test with auto-play!
./test_scripts/quick_test.sh
```

---

## 🎙️ Test Your TTS

After deployment succeeds, run this on your Mac:

```bash
./test_scripts/quick_test.sh
```

This will:
1. Generate TTS audio from RunPod
2. Save as `quick_test.mp3`
3. **Automatically play the audio!** 🔊

---

## 📞 Configure Twilio

After TTS is working, update Twilio:

1. Go to: https://console.twilio.com/us1/develop/phone-numbers/manage/incoming
2. Click: **(218) 400-3410**
3. Under **Voice Configuration** → **A call comes in**:
   ```
   URL: https://a288y3vpbfxwkk-8004.proxy.runpod.net/twilio/voice
   HTTP: POST
   ```
4. Click **Save configuration**

---

## 🔧 Troubleshooting

### If Deployment Fails

```bash
# On RunPod, check what went wrong
cd /workspace/chatterbox-twilio-integration
tail -f logs/tts.log

# Restart manually
python scripts/server_production.py
```

### If Port 8004 Already in Use

```bash
# Kill existing process
lsof -ti :8004 | xargs kill -9

# Start again
python scripts/server_production.py
```

### Keep Service Running After Disconnect

```bash
# Use screen
screen -S tts
python scripts/server_production.py
# Press Ctrl+A then D to detach

# Reattach later
screen -r tts
```

---

## 📊 Monitoring

### Check Service Status

```bash
# Is it running?
curl http://localhost:8004/health

# View real-time logs
tail -f logs/tts.log

# Check GPU usage
nvidia-smi

# Check process
ps aux | grep server_production
```

---

## 🎯 Complete System URLs

```
TTS Service:    https://a288y3vpbfxwkk-8004.proxy.runpod.net
Health Check:   https://a288y3vpbfxwkk-8004.proxy.runpod.net/health
TTS Endpoint:   https://a288y3vpbfxwkk-8004.proxy.runpod.net/synthesize
Twilio Voice:   https://a288y3vpbfxwkk-8004.proxy.runpod.net/twilio/voice
Twilio SMS:     https://a288y3vpbfxwkk-8004.proxy.runpod.net/twilio/sms
```

---

## ⏱️ Deployment Timeline

```
0:00 - SSH to RunPod
0:10 - Run deployment script
0:30 - Installing dependencies
1:00 - Cloning repository
1:30 - Installing Python packages
2:00 - Starting TTS service
2:10 - ✅ Service ready!
```

**Total**: ~2 minutes

---

## 🎉 Ready to Deploy!

**Copy this command** (Step 1):
```bash
ssh a288y3vpbfxwkk-6441165c@ssh.runpod.io -i ~/.ssh/id_ed25519
```

**Then run this** (Step 2):
```bash
curl -sSL https://raw.githubusercontent.com/Odiabackend099/Chatterbox-TTS-/main/runpod/DEPLOY_NOW.sh | bash
```

**Then test from your Mac**:
```bash
./test_scripts/quick_test.sh
```

Let's deploy! 🚀

