# Deploy to RunPod - GitHub Auto-Clone Method

Your code is now on GitHub and ready for automatic deployment to RunPod.

**Repository:** https://github.com/Odiabackend099/Chatterbox-TTS-

---

## 🚀 Quick Deploy (3 Steps)

### Step 1: Get Requirements

You need:
1. **RunPod Account**: https://www.runpod.io (sign up free)
2. **RunPod API Key**: https://www.runpod.io/console/user/settings
3. **Docker Hub Account**: https://hub.docker.com (sign up free)
4. **Your API Keys**: Twilio + Anthropic (or OpenAI)

### Step 2: Set RunPod API Key

```bash
export RUNPOD_API_KEY=your_runpod_api_key_here
```

Get it from: https://www.runpod.io/console/user/settings

### Step 3: Deploy

```bash
cd ~/chatterbox-twilio-integration/runpod
./deploy_github.sh
```

**The script will:**
1. Ask for your Docker Hub username
2. Build Docker image
3. Push to Docker Hub
4. Ask for GPU type (choose RTX 4090)
5. Ask for your API keys
6. Deploy to RunPod
7. Give you the pod URL

**Time:** 10-15 minutes

---

## 📋 What Happens on RunPod

When your pod starts, it will automatically:

1. ✅ Clone from https://github.com/Odiabackend099/Chatterbox-TTS-
2. ✅ Install all Python dependencies
3. ✅ Download Chatterbox TTS model (~2-3GB)
4. ✅ Start server on port 8004
5. ✅ Server ready at `https://your-pod-id-8004.proxy.runpod.net`

**No manual setup needed!**

---

## 🔑 API Keys Needed

During deployment, you'll be asked for:

```
TWILIO_ACCOUNT_SID       (from https://console.twilio.com)
TWILIO_AUTH_TOKEN        (same page)
TWILIO_PHONE_NUMBER      (your Twilio number)
ANTHROPIC_API_KEY        (from https://console.anthropic.com)
  OR
OPENAI_API_KEY           (from https://platform.openai.com/api-keys)
```

You can skip any of these and add them later in RunPod console.

---

## 💰 Cost

**Recommended GPU:** RTX 4090 (24GB)
- **Performance:** 500ms-1s latency
- **Cost:** ~$0.40/hour = ~$290/month (24/7)
- **Best for:** Production use

**Budget Option:** RTX 3090 (24GB)
- **Performance:** 2-3s latency
- **Cost:** ~$0.20/hour = ~$144/month (24/7)
- **Best for:** Testing/development

---

## 🌐 After Deployment

### 1. Get Your Pod URL

The deployment script will show your pod ID. To get the URL:

```bash
runpodctl get pod <pod-id>
```

Or check: https://www.runpod.io/console/pods

Your URL will look like:
```
https://xxxxx-8004.proxy.runpod.net
```

### 2. Test the API

```bash
curl https://your-pod-url/health
```

Should return:
```json
{
  "status": "healthy",
  "components": {
    "tts_model": true,
    "llm_client": true,
    "twilio_client": true
  }
}
```

### 3. Test TTS

```bash
curl -X POST https://your-pod-url/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Hello from RunPod!"}' \
  --output test.wav

afplay test.wav  # Mac
```

### 4. Configure Twilio

1. Go to: https://console.twilio.com/us1/develop/phone-numbers
2. Select your phone number
3. Under "Voice Configuration":
   - **A CALL COMES IN:** `https://your-pod-url/twilio/voice`
   - **HTTP:** POST
4. Save
5. Call your Twilio number!

---

## 📊 Monitoring

### View Logs

```bash
runpodctl logs <pod-id> -f
```

### Check Status

```bash
runpodctl get pod <pod-id>
```

### Web Console

https://www.runpod.io/console/pods

---

## 🔧 Management Commands

### Stop Pod

```bash
runpodctl stop pod <pod-id>
```

### Delete Pod

```bash
runpodctl delete pod <pod-id>
```

### Restart Pod

```bash
runpodctl restart pod <pod-id>
```

---

## 🆘 Troubleshooting

### Pod won't start?

Check logs:
```bash
runpodctl logs <pod-id>
```

### Server not responding?

Wait 5-10 minutes for:
- Model download (~2-3GB)
- Dependencies installation

### Need to update code?

Pod auto-clones from GitHub on every restart. Just:
1. Push changes to GitHub
2. Restart the pod
3. Latest code will be pulled automatically

---

## 🔄 Update Workflow

When you make changes to your code:

```bash
# 1. Make changes locally
cd ~/chatterbox-twilio-integration

# 2. Commit and push
git add .
git commit -m "Your changes"
git push origin main

# 3. Restart RunPod pod
runpodctl restart pod <pod-id>
```

Pod will automatically pull latest code from GitHub!

---

## 📝 Full Deployment Example

```bash
# Set API key
export RUNPOD_API_KEY=rpk_xxxxx

# Run deployment
cd ~/chatterbox-twilio-integration/runpod
./deploy_github.sh

# Follow prompts:
# - Docker Hub username: yourusername
# - GPU: NVIDIA GeForce RTX 4090
# - Enter your API keys
#
# Wait 10-15 minutes...
#
# Get pod URL from output or:
runpodctl get pod <pod-id>

# Test
curl https://your-pod-url/health

# Configure Twilio webhook
# Point to: https://your-pod-url/twilio/voice

# Call your Twilio number
# Enjoy your AI voice agent! 🎉
```

---

## ✅ Success Checklist

- [ ] RunPod account created
- [ ] RunPod API key obtained
- [ ] Docker Hub account created
- [ ] API keys ready (Twilio + Anthropic/OpenAI)
- [ ] RunPod API key exported
- [ ] Deployment script run
- [ ] Pod URL obtained
- [ ] Health check passes
- [ ] TTS generation tested
- [ ] Twilio webhook configured
- [ ] Test phone call successful

---

## 🎯 Next Steps

1. **Run the deployment:**
   ```bash
   cd ~/chatterbox-twilio-integration/runpod
   export RUNPOD_API_KEY=your_key
   ./deploy_github.sh
   ```

2. **Wait 10-15 minutes** for pod to start and download model

3. **Get your pod URL** from RunPod console

4. **Configure Twilio** to point to your pod URL

5. **Make a test call!**

---

**Questions?** Check the full documentation in the repository or RunPod docs.

**GitHub Repo:** https://github.com/Odiabackend099/Chatterbox-TTS-

**RunPod Docs:** https://docs.runpod.io
