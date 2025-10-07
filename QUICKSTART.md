# Quick Start Guide

Get your Chatterbox TTS + Twilio voice agent running in 15 minutes.

## Prerequisites Checklist

Before starting, make sure you have:

- [ ] Python 3.10 or 3.11 installed
- [ ] NVIDIA GPU with 8GB+ VRAM (or use CPU mode, slower)
- [ ] Twilio account ([Sign up](https://www.twilio.com/try-twilio))
- [ ] Twilio phone number ([Get one](https://console.twilio.com/us1/develop/phone-numbers))
- [ ] Anthropic API key ([Get one](https://console.anthropic.com/)) OR OpenAI API key

## Step 1: Installation (5 minutes)

### macOS / Linux

```bash
# Clone or download this repository
cd chatterbox-twilio-integration

# Run installation script
chmod +x setup/install_local.sh
./setup/install_local.sh

# Follow prompts, script will:
# ✓ Check Python version
# ✓ Create virtual environment
# ✓ Install PyTorch (GPU or CPU)
# ✓ Install Chatterbox TTS
# ✓ Install all dependencies
# ✓ Create config files
```

### Windows

```powershell
# Open PowerShell as Administrator
cd chatterbox-twilio-integration

# Run installation script
powershell -ExecutionPolicy Bypass -File setup\install_local.ps1

# Follow prompts
```

**Installation complete when you see:**
```
==================================================
Installation Complete!
==================================================
```

## Step 2: Configure API Keys (2 minutes)

### Edit .env file

```bash
# Open .env in your favorite editor
nano .env
```

### Fill in your credentials:

```bash
# Twilio (required for phone calls)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15555551234

# LLM - Choose ONE:
# Option A: Anthropic Claude (recommended)
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx

# Option B: OpenAI GPT
# OPENAI_API_KEY=sk-xxxxx

# Server (defaults are fine)
CHATTERBOX_HOST=0.0.0.0
CHATTERBOX_PORT=8004
CHATTERBOX_DEVICE=auto
```

**Where to find these:**

- **Twilio Account SID & Auth Token:** [Console Home](https://console.twilio.com)
- **Twilio Phone Number:** [Phone Numbers](https://console.twilio.com/us1/develop/phone-numbers/manage/incoming)
- **Anthropic API Key:** [Anthropic Console](https://console.anthropic.com/)
- **OpenAI API Key:** [OpenAI API Keys](https://platform.openai.com/api-keys)

### Save the file
```bash
# Save in nano: Ctrl+O, Enter, Ctrl+X
```

## Step 3: Test Installation (3 minutes)

### Activate environment

```bash
# macOS/Linux
source activate.sh

# Windows
.\activate.ps1
```

### Run installation test

```bash
python tests/test_installation.py
```

**Expected output:**
```
Testing Python version... ✓ Python 3.11.x
Testing PyTorch... ✓ PyTorch 2.x.x
  GPU: NVIDIA GeForce RTX 4090
Testing Chatterbox TTS... ✓ Chatterbox TTS installed
Testing model download...
  Loading model on cuda... ✓
  Testing generation... ✓ Generated 96000 samples
  Saved test audio to outputs/test_output.wav

✓ All required components are installed
```

**If you see warnings:**
- ⚠ "No GPU detected" → Will use CPU (slower, but works)
- ⚠ "Twilio credentials not found" → Fill in .env file
- ⚠ "No LLM API keys found" → Fill in .env file

## Step 4: Start Server (1 minute)

```bash
python scripts/server.py
```

**Server is ready when you see:**
```
INFO:     Started server process
INFO:     Waiting for application startup.
Starting Chatterbox TTS Server...
Loading Chatterbox TTS model on cuda...
✓ TTS model loaded successfully
✓ Anthropic LLM client initialized
✓ Twilio client initialized
Server startup complete
Device: cuda
Port: 8004
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8004
```

**Keep this terminal open!** Server is now running.

## Step 5: Test API (2 minutes)

Open a **new terminal** (keep server running in first terminal).

### Activate environment again

```bash
# New terminal
cd chatterbox-twilio-integration
source activate.sh  # or .\activate.ps1 on Windows
```

### Run API tests

```bash
python tests/test_api.py
```

**Expected output:**
```
Testing: Health Check
Status: healthy
Components: {'tts_model': True, 'llm_client': True, 'twilio_client': True}
✓ Health check passed

Testing: Basic TTS Generation
Generating audio for: This is a test of the Chatterbox TTS system.
Audio generated in 0.87s
✓ TTS generation passed (0.87s)

...

Results: 9/9 tests passed
🎉 All tests passed!
```

### Test TTS manually

```bash
curl -X POST http://localhost:8004/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Hello! This is Chatterbox TTS."}' \
  --output hello.wav

# Play the audio
# macOS: afplay hello.wav
# Linux: aplay hello.wav
# Windows: start hello.wav
```

You should hear: "Hello! This is Chatterbox TTS."

## Step 6: Configure Twilio Webhook (2 minutes)

### Option A: Local Testing with ngrok (Recommended for testing)

1. **Install ngrok** (if not installed):
   ```bash
   # macOS
   brew install ngrok

   # Linux
   curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
   echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
   sudo apt update && sudo apt install ngrok

   # Windows - download from https://ngrok.com/download
   ```

2. **Start ngrok**:
   ```bash
   ngrok http 8004
   ```

3. **Copy the HTTPS URL** (looks like `https://abc123.ngrok.io`)

4. **Configure Twilio**:
   - Go to [Twilio Console → Phone Numbers](https://console.twilio.com/us1/develop/phone-numbers/manage/incoming)
   - Click your phone number
   - Under "Voice Configuration":
     - **A CALL COMES IN:** Webhook
     - **URL:** `https://abc123.ngrok.io/twilio/voice`
     - **HTTP:** POST
   - Click **Save**

### Option B: Production Deployment

See [RunPod Deployment Guide](runpod/RUNPOD_DEPLOYMENT.md) for deploying to cloud.

## Step 7: Make Your First Call! (1 minute)

### Call your Twilio number

1. **Call** the phone number you configured in Twilio
2. **Listen** to the greeting: "Hello! I'm your AI assistant. How can I help you today?"
3. **Say something**: "What's the weather like?" or "Tell me a joke"
4. **Listen** to the AI response generated with LLM + TTS

**Check server logs** (in the terminal running the server):
```
INFO: Incoming call from +15555555555, SID: CA1234...
INFO: Call CA1234...: User said: What's the weather like?
INFO: Generated response audio: outputs/call_CA1234_20250107_123456.wav
```

🎉 **Congratulations! Your voice agent is working!**

## What Just Happened?

When you called your Twilio number:

1. Twilio received the call → sent webhook to your server
2. Server responded with greeting
3. You spoke → Twilio transcribed to text
4. Text → Claude LLM → generated response
5. Response → Chatterbox TTS → audio
6. Audio → Twilio → you heard it on phone

## Next Steps

### 1. Customize the Voice

Add your own voice samples:

```bash
# Add 10-20 second WAV files to voices/
cp my_voice.wav voices/CustomVoice.wav

# Use in config
nano config/config.yaml
# Change: default_voice: "CustomVoice.wav"
```

### 2. Customize the Assistant

Edit the greeting in `scripts/server.py` (line ~212):

```python
response.say("Hello! I'm your custom AI assistant. How can I help you?")
```

### 3. Adjust Voice Parameters

Edit `config/config.yaml`:

```yaml
generation_defaults:
  temperature: 0.8      # 0-2: Lower = consistent, Higher = varied
  exaggeration: 1.3     # 0-2: Lower = neutral, Higher = dramatic
  speed_factor: 1.0     # 0.5-2.0: Playback speed
```

Restart server to apply changes.

### 4. Change LLM Model

Edit `config/config.yaml`:

```yaml
llm:
  provider: anthropic
  model: claude-3-5-sonnet-20241022  # or claude-3-opus-20240229

  # OR for OpenAI:
  # provider: openai
  # model: gpt-4-turbo-preview
```

### 5. Deploy to Production

See [RunPod Deployment Guide](runpod/RUNPOD_DEPLOYMENT.md) for cloud deployment.

```bash
cd runpod/
export RUNPOD_API_KEY=your_key
./deploy_runpod.sh
```

## Troubleshooting

### Server won't start

**Error:** `TTS model not loaded`

```bash
# Check Python version
python --version  # Should be 3.10 or 3.11

# Check PyTorch
python -c "import torch; print(torch.__version__)"

# Reinstall
pip install --force-reinstall chatterbox-tts
```

### No GPU detected

```bash
# Check NVIDIA GPU
nvidia-smi

# If no GPU, use CPU mode (slower)
export CHATTERBOX_DEVICE=cpu
python scripts/server.py
```

### Twilio webhook not working

**Check:**
- Server is running
- ngrok is running (for local testing)
- Webhook URL is correct (HTTPS)
- Webhook URL ends with `/twilio/voice`

**Test webhook manually:**
```bash
curl -X POST http://localhost:8004/twilio/voice \
  -d "CallSid=test123" \
  -d "From=+15555555555"
```

Should return XML with `<Say>` tag.

### Audio quality is poor

**Improve voice cloning:**
- Use longer reference audio (15-20 seconds)
- Use high-quality microphone
- Remove background noise
- Use 24kHz sample rate:
  ```bash
  ffmpeg -i input.mp3 -ar 24000 -ac 1 output.wav
  ```

### Latency is high

**Check device:**
```bash
curl http://localhost:8004/health | jq .config.device
```

**If CPU:**
- Get a GPU (8GB+ VRAM recommended)
- Or deploy to RunPod with GPU

**If CUDA:**
- Upgrade to better GPU (RTX 4090 recommended)
- Lower temperature/exaggeration in config

## Getting Help

- **Documentation:** See [README.md](README.md)
- **API Reference:** http://localhost:8004/docs (when server running)
- **Issues:** [GitHub Issues](your-repo-issues-url)
- **Community:** [Discord](your-discord-url)

## Quick Reference

### Start/Stop Server

```bash
# Start
source activate.sh
python scripts/server.py

# Stop
Ctrl+C
```

### View Logs

```bash
# Real-time
tail -f logs/server.log

# Last 50 lines
tail -n 50 logs/server.log
```

### Test Endpoints

```bash
# Health check
curl http://localhost:8004/health

# Generate TTS
curl -X POST http://localhost:8004/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Test"}' \
  --output test.wav

# List voices
curl http://localhost:8004/voices
```

### Update Configuration

1. Edit `config/config.yaml` or `.env`
2. Restart server (Ctrl+C, then restart)

---

**Ready to build amazing voice agents! 🎉**

Need help? See [README.md](README.md) for full documentation.
