# RunPod Deployment Guide

Complete guide for deploying Chatterbox TTS Server on RunPod.

## Prerequisites

1. **RunPod Account**
   - Sign up at https://www.runpod.io
   - Add payment method and credits
   - Get API key from https://www.runpod.io/console/user/settings

2. **Docker Hub Account**
   - Sign up at https://hub.docker.com
   - Create a repository: `your-username/chatterbox-tts`

3. **API Keys**
   - Twilio: Account SID, Auth Token, Phone Number
   - Anthropic API key OR OpenAI API key

## Method 1: Automated Deployment (Recommended)

### Step 1: Set Environment Variables

```bash
export RUNPOD_API_KEY=your_runpod_api_key
export TWILIO_ACCOUNT_SID=your_twilio_sid
export TWILIO_AUTH_TOKEN=your_twilio_token
export ANTHROPIC_API_KEY=your_anthropic_key
```

### Step 2: Run Deployment Script

```bash
cd runpod/
chmod +x deploy_runpod.sh
./deploy_runpod.sh
```

The script will:
- Install RunPod CLI if needed
- Build Docker image
- Push to Docker Hub
- Create and deploy pod
- Configure environment variables

### Step 3: Get Pod URL

```bash
# Get pod status and URL
runpodctl get pod <pod-id>

# Or view in web console
# https://www.runpod.io/console/pods
```

## Method 2: Manual Deployment via Web Console

### Step 1: Build and Push Docker Image

```bash
# Build image
docker build -t your-username/chatterbox-tts:latest -f runpod/Dockerfile.runpod .

# Login to Docker Hub
docker login

# Push image
docker push your-username/chatterbox-tts:latest
```

### Step 2: Create Pod in RunPod Console

1. Go to https://www.runpod.io/console/pods
2. Click **"+ Deploy"**
3. Select GPU type:
   - **RTX 4090** (24GB) - Recommended for production
   - **RTX A5000** (24GB) - Good balance
   - **RTX 3090** (24GB) - Budget option
   - **A100** (40GB/80GB) - High performance

### Step 3: Configure Pod

**Container Image:**
```
your-username/chatterbox-tts:latest
```

**Container Disk:**
```
50 GB
```

**Expose HTTP Ports:**
```
8004
```

**Environment Variables:**
```
CHATTERBOX_HOST=0.0.0.0
CHATTERBOX_PORT=8004
CHATTERBOX_DEVICE=cuda
HF_HUB_ENABLE_HF_TRANSFER=1
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=your_twilio_number
ANTHROPIC_API_KEY=your_anthropic_key
```

**Docker Command (optional):**
```
python /app/scripts/server.py
```

### Step 4: Deploy Pod

1. Click **"Deploy"**
2. Wait for pod to start (2-5 minutes)
3. First run will download model (~2-3GB, adds 5-10 minutes)

## Method 3: RunPod Template (One-Click Deploy)

### Step 1: Create Template

1. Go to https://www.runpod.io/console/templates
2. Click **"+ New Template"**
3. Fill in details:

**Template Name:**
```
Chatterbox TTS Server
```

**Container Image:**
```
your-username/chatterbox-tts:latest
```

**Container Disk:**
```
50 GB
```

**Expose HTTP Ports:**
```
8004
```

**Environment Variables:**
```json
[
  {"key": "CHATTERBOX_HOST", "value": "0.0.0.0"},
  {"key": "CHATTERBOX_PORT", "value": "8004"},
  {"key": "CHATTERBOX_DEVICE", "value": "cuda"},
  {"key": "HF_HUB_ENABLE_HF_TRANSFER", "value": "1"}
]
```

**Start Command:**
```
python /app/scripts/server.py
```

### Step 2: Deploy from Template

1. Go to **Pods** → **+ Deploy**
2. Select your template
3. Choose GPU type
4. Add secrets for API keys (recommended over env vars)
5. Click **Deploy**

## Post-Deployment Setup

### 1. Verify Deployment

```bash
# Get pod URL from RunPod console
POD_URL="https://your-pod-id-8004.proxy.runpod.net"

# Test health endpoint
curl $POD_URL/health

# Expected response:
# {
#   "status": "healthy",
#   "components": {
#     "tts_model": true,
#     "llm_client": true,
#     "twilio_client": true
#   }
# }
```

### 2. Test TTS Generation

```bash
curl -X POST "$POD_URL/v1/audio/speech" \
  -H "Content-Type: application/json" \
  -d '{"input": "Hello from RunPod!", "voice": "Emily.wav"}' \
  --output test.wav

# Play audio
ffplay test.wav
```

### 3. Configure Twilio Webhook

1. Go to Twilio Console: https://console.twilio.com
2. Navigate to **Phone Numbers** → **Manage** → **Active numbers**
3. Select your phone number
4. Under **Voice Configuration**:
   - **A CALL COMES IN**: Webhook
   - **URL**: `https://your-pod-id-8004.proxy.runpod.net/twilio/voice`
   - **HTTP**: POST
5. Click **Save**

### 4. Test Phone Call

1. Call your Twilio number
2. You should hear: "Hello! I'm your AI assistant. How can I help you today?"
3. Speak to the assistant
4. It will respond using LLM + TTS

## Monitoring and Logs

### View Logs

**Via RunPod CLI:**
```bash
runpodctl logs <pod-id>
```

**Via Web Console:**
1. Go to https://www.runpod.io/console/pods
2. Click on your pod
3. Click **"Logs"** tab

### Monitor GPU Usage

**Via RunPod CLI:**
```bash
runpodctl exec <pod-id> nvidia-smi
```

**Via Web Console:**
- GPU usage shown in pod details
- Real-time graphs available

### Check Server Logs

```bash
# SSH into pod
runpodctl exec <pod-id> bash

# View server logs
cd /app
tail -f logs/server.log
```

## Cost Optimization

### GPU Selection by Use Case

| Use Case | Recommended GPU | Cost/hr* | Latency |
|----------|----------------|----------|---------|
| Development | RTX 3090 (24GB) | $0.20 | ~2-5s |
| Production (Medium) | RTX 4090 (24GB) | $0.40 | ~500ms-1s |
| Production (High) | A100 (40GB) | $1.00 | ~300-500ms |

*Prices approximate, check current RunPod pricing

### Cost-Saving Tips

1. **Use Spot Instances**
   - 50-80% cheaper than on-demand
   - Enable "Auto-restart on termination"

2. **Auto-shutdown**
   - Set idle timeout in pod settings
   - Automatically stop when not in use

3. **Shared vs Dedicated**
   - Use Community Cloud for dev/testing
   - Use Secure Cloud for production

4. **Pre-download Models**
   - Uncomment model download in Dockerfile
   - Saves time and network costs on pod restart

## Troubleshooting

### Pod Won't Start

**Check logs:**
```bash
runpodctl logs <pod-id>
```

**Common issues:**
- Out of disk space (increase container disk)
- Model download timeout (check network, increase timeout)
- Missing environment variables (check secrets)

### TTS Not Working

**Verify model loaded:**
```bash
curl $POD_URL/health
```

**Check device:**
```bash
runpodctl exec <pod-id> python -c "import torch; print(torch.cuda.is_available())"
```

### High Latency

**Causes:**
- CPU mode instead of GPU
- Insufficient VRAM
- Network latency
- Model not cached

**Solutions:**
- Verify CUDA device: check logs for "using CUDA"
- Upgrade to GPU with more VRAM
- Use RunPod location closer to users
- Pre-download model in Dockerfile

### Twilio Integration Not Working

**Check webhook configuration:**
- Correct URL with HTTPS
- Port 8004 exposed
- POST method selected

**Verify credentials:**
```bash
runpodctl exec <pod-id> env | grep TWILIO
```

**Test webhook manually:**
```bash
curl -X POST "$POD_URL/twilio/voice" \
  -d "CallSid=test123" \
  -d "From=+15555555555"
```

## Scaling

### Horizontal Scaling

Deploy multiple pods with load balancer:

1. Deploy 2-3 identical pods
2. Use Nginx or Cloudflare Load Balancer
3. Configure health checks
4. Route traffic based on availability

### Vertical Scaling

Upgrade GPU:
1. Stop current pod
2. Deploy new pod with larger GPU
3. Update Twilio webhook URL
4. Delete old pod

## Security Best Practices

### 1. Use Secrets for API Keys

Don't put API keys in environment variables:

```bash
# Add secret in RunPod console
# Settings → Secrets → + Add Secret
```

Then reference in pod:
```bash
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
```

### 2. Enable Authentication

Edit `config/config.yaml`:
```yaml
security:
  enable_auth: true
  username: your_username
  password: your_secure_password
```

### 3. Use HTTPS Only

RunPod provides HTTPS by default via proxy.

### 4. Restrict CORS

Edit `config/config.yaml`:
```yaml
security:
  enable_cors: true
  allowed_origins:
    - "https://yourdomain.com"
```

### 5. Rate Limiting

Consider adding rate limiting for production:
- Use Cloudflare for DDoS protection
- Implement API key authentication
- Add request throttling in code

## Backup and Recovery

### Backup Voice Files

```bash
# Download voices from pod
runpodctl exec <pod-id> tar -czf /tmp/voices.tar.gz /app/voices
runpodctl cp <pod-id>:/tmp/voices.tar.gz ./voices_backup.tar.gz
```

### Backup Configuration

Store config in git repository or RunPod volume.

### Restore

```bash
# Upload to new pod
runpodctl cp ./voices_backup.tar.gz <new-pod-id>:/tmp/
runpodctl exec <new-pod-id> tar -xzf /tmp/voices.tar.gz -C /app/
```

## Support

- RunPod Docs: https://docs.runpod.io
- RunPod Discord: https://discord.gg/runpod
- Chatterbox GitHub: https://github.com/resemble-ai/chatterbox
- This project issues: [GitHub Issues URL]

## Next Steps

1. ✅ Deploy pod on RunPod
2. ✅ Configure Twilio webhook
3. ✅ Test phone call
4. 📊 Monitor performance and costs
5. 🔒 Implement additional security
6. 📈 Scale as needed
