# Get Started - Installation Options

## ⚠️ Current System Status

**Requirements Check Results:**
- ❌ Python 3.9.6 (need 3.10 or 3.11)
- ⚠️  Intel Mac (CPU mode - slower performance)
- ✅ Docker available
- ✅ 390GB disk space available
- ✅ Git available

---

## 🚀 Recommended: Use Docker (Easiest)

**Why Docker?** Bypasses Python version issue, everything pre-configured.

### Step 1: Create .env file

```bash
cd ~/chatterbox-twilio-integration
cp .env.example .env
nano .env
```

**Fill in your credentials:**
```bash
TWILIO_ACCOUNT_SID=ACxxxxx...
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=+15555551234
ANTHROPIC_API_KEY=sk-ant-xxxxx
```

Save with `Ctrl+O`, `Enter`, `Ctrl+X`

### Step 2: Start with Docker

```bash
docker-compose up -d
```

### Step 3: Check logs

```bash
docker-compose logs -f
```

Wait for: `✓ TTS model loaded successfully`

### Step 4: Test it

```bash
curl http://localhost:8004/health
```

**Done!** Server running at http://localhost:8004

---

## 🐍 Alternative: Install Python 3.11

If you prefer local installation without Docker:

### Option A: Install Homebrew + Python

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Python 3.11
brew install python@3.11

# 3. Verify
python3.11 --version

# 4. Run installation
./setup/install_local.sh
```

### Option B: Download Python directly

1. Download Python 3.11: https://www.python.org/downloads/release/python-3117/
2. Install the macOS installer
3. Verify: `python3.11 --version`
4. Run: `./setup/install_local.sh`

---

## ☁️ Best Option: Deploy to RunPod (Production)

**Why RunPod?** Gets you a real GPU (500ms-1s latency vs 10-30s on your Mac).

### Prerequisites

1. **RunPod Account:** https://www.runpod.io
2. **Docker Hub Account:** https://hub.docker.com
3. **Get RunPod API Key:** https://www.runpod.io/console/user/settings

### Deploy

```bash
# Set credentials
export RUNPOD_API_KEY=your_runpod_key
export TWILIO_ACCOUNT_SID=ACxxxxx
export TWILIO_AUTH_TOKEN=your_token
export ANTHROPIC_API_KEY=sk-ant-xxxxx

# Deploy
cd ~/chatterbox-twilio-integration/runpod
./deploy_runpod.sh
```

**Follow the prompts:**
- Choose GPU: RTX 4090 (recommended)
- Wait 5-10 minutes for deployment
- Get your pod URL
- Configure Twilio webhook to point to your pod

**Cost:** ~$290/month for RTX 4090 (unlimited usage)

---

## 📊 Comparison

| Option | Setup Time | Performance | Cost | Best For |
|--------|------------|-------------|------|----------|
| **Docker (Local)** | 5 min | Slow (CPU) | Free | Testing only |
| **Python 3.11 (Local)** | 15 min | Slow (CPU) | Free | Development |
| **RunPod (Cloud)** | 30 min | Fast (GPU) | $290/mo | Production ✅ |

---

## 🎯 What I Recommend

### For Testing (Today)
```bash
# Quick test with Docker
cd ~/chatterbox-twilio-integration
cp .env.example .env
# Edit .env with your keys
docker-compose up -d
curl http://localhost:8004/health
```

**Note:** Will be slow (10-30s per generation) but works for testing.

### For Production (This Week)
```bash
# Deploy to RunPod with GPU
cd ~/chatterbox-twilio-integration/runpod
./deploy_runpod.sh
```

**Benefits:**
- ✅ Fast (500ms-1s)
- ✅ No local setup needed
- ✅ Always-on server
- ✅ Easy monitoring
- ✅ Professional deployment

---

## 🆘 Need Help?

### Quick Start Guides
- **QUICKSTART.md** - Step-by-step for all options
- **README.md** - Complete documentation
- **runpod/RUNPOD_DEPLOYMENT.md** - Cloud deployment details

### Test Requirements
```bash
./check_requirements.sh
```

### Check Docker
```bash
docker ps
docker-compose logs chatterbox-tts
```

### Common Issues

**Docker won't start?**
```bash
docker-compose down
docker-compose up -d
```

**Can't connect to localhost:8004?**
```bash
docker-compose logs -f chatterbox-tts
# Look for errors
```

**Want to stop?**
```bash
docker-compose down
```

---

## 📞 Next Steps

1. **Choose your path:** Docker (today) or RunPod (production)
2. **Get API keys:** Twilio + Anthropic/OpenAI
3. **Follow QUICKSTART.md** for detailed instructions
4. **Test the API** once running
5. **Configure Twilio** webhook
6. **Make a test call!**

---

**Ready?** Pick Docker for quick test or RunPod for production → See QUICKSTART.md
