# 🚀 Start TTS Service on RunPod

**Pod ID**: `bh1ki2a4eg8ufz`

---

## 🔐 SSH Connection

You have two SSH options:

### Option 1: RunPod SSH (Recommended)
```bash
ssh bh1ki2a4eg8ufz-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519
```

### Option 2: Direct SSH
```bash
ssh root@157.157.221.29 -p 25348 -i ~/.ssh/id_ed25519
```

---

## ⚡ Quick Start (Copy & Paste)

### Step 1: Connect to Pod

```bash
# Use RunPod SSH
ssh bh1ki2a4eg8ufz-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519
```

### Step 2: Setup Project

```bash
# Navigate to workspace
cd /workspace

# Upload your code (option A: git clone)
git clone https://github.com/YOUR-USERNAME/chatterbox-twilio-integration.git
cd chatterbox-twilio-integration

# OR option B: Copy files manually via RunPod web interface

# Install dependencies
pip install -r requirements.txt

# Install additional packages
pip install fastapi uvicorn[standard] httpx python-multipart
```

### Step 3: Start TTS Service

```bash
# Start in foreground (to see logs)
python scripts/server_production.py

# OR start in background with nohup
nohup python scripts/server_production.py > logs/tts.log 2>&1 &

# OR use screen (recommended for long-running)
screen -S tts
python scripts/server_production.py
# Press Ctrl+A then D to detach
# Later: screen -r tts to reattach
```

### Step 4: Verify It's Running

```bash
# In another terminal/screen, test locally
curl http://localhost:8004/health

# Should return: {"status": "healthy", ...}
```

---

## 🌐 Your Public URLs

Once running, your service will be available at:

```
Health: https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/health
TTS:    https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/synthesize
```

---

## 🧪 Test from Your Local Machine

After starting the service, test from your local terminal:

```bash
# Health check
curl https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/health

# TTS test
curl -X POST "https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/synthesize" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Hello from Nigeria!" \
  -F "voice_id=naija_female" \
  --output test.mp3

# Then play it
open test.mp3

# Or use the automated script
./test_scripts/quick_test.sh
```

---

## 📋 Complete Setup Script

Save time with this all-in-one script:

```bash
#!/bin/bash
# Run this on your RunPod pod

cd /workspace

# Install system dependencies (if needed)
apt-get update
apt-get install -y git curl wget ffmpeg libsndfile1

# Clone repository (replace with your repo)
if [ ! -d "chatterbox-twilio-integration" ]; then
    git clone https://github.com/YOUR-USERNAME/chatterbox-twilio-integration.git
fi

cd chatterbox-twilio-integration

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install fastapi uvicorn[standard] httpx python-multipart

# Create directories
mkdir -p logs outputs model_cache

# Create environment file
cat > .env << EOF
API_KEY_1=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
API_KEY_2=cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI
TTS_PORT=8004
EOF

# Start service
echo "Starting TTS service..."
nohup python scripts/server_production.py > logs/tts.log 2>&1 &

# Wait a moment for startup
sleep 3

# Test
echo "Testing service..."
curl http://localhost:8004/health

echo ""
echo "✅ Setup complete!"
echo "Service running at: https://bh1ki2a4eg8ufz-8004.proxy.runpod.net"
```

---

## 🔍 Troubleshooting

### Check if Service is Running

```bash
# Check process
ps aux | grep server_production

# Check port
lsof -i :8004

# View logs
tail -f logs/tts.log
```

### Restart Service

```bash
# Kill existing process
pkill -f server_production

# Start again
python scripts/server_production.py
```

### Check GPU

```bash
# Verify CUDA is available
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Check GPU info
nvidia-smi
```

### Port Already in Use

```bash
# Find what's using port 8004
lsof -i :8004

# Kill it
kill -9 $(lsof -t -i :8004)

# Start your service
python scripts/server_production.py
```

---

## 📊 Monitor Service

### View Logs in Real-Time

```bash
tail -f logs/tts.log
```

### Check Resources

```bash
# CPU/Memory
htop

# GPU usage
watch -n 1 nvidia-smi
```

### Test Endpoint

```bash
# Health check (should be fast)
time curl http://localhost:8004/health

# TTS request (will take a few seconds)
time curl -X POST http://localhost:8004/synthesize \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Test" \
  -F "voice_id=naija_female" \
  --output test.mp3
```

---

## 🎯 Keep Service Running

### Using Screen (Recommended)

```bash
# Create session
screen -S tts

# Start service
python scripts/server_production.py

# Detach: Ctrl+A then D

# Reattach later
screen -r tts

# List sessions
screen -ls
```

### Using tmux (Alternative)

```bash
# Create session
tmux new -s tts

# Start service
python scripts/server_production.py

# Detach: Ctrl+B then D

# Reattach later
tmux attach -t tts
```

### Using systemd (Advanced)

Create `/etc/systemd/system/tts.service`:

```ini
[Unit]
Description=Chatterbox TTS Service
After=network.target

[Service]
Type=simple
User=root
WorkingDir=/workspace/chatterbox-twilio-integration
ExecStart=/usr/bin/python scripts/server_production.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:
```bash
systemctl daemon-reload
systemctl start tts
systemctl enable tts  # Start on boot
systemctl status tts
```

---

## ✅ Quick Verification Checklist

From your RunPod SSH session:

- [ ] Code uploaded to `/workspace/chatterbox-twilio-integration`
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Service started (`python scripts/server_production.py`)
- [ ] Process running (`ps aux | grep server_production`)
- [ ] Port open (`lsof -i :8004`)
- [ ] Local health check works (`curl localhost:8004/health`)

From your local machine:

- [ ] Public health check works
- [ ] TTS synthesis works
- [ ] Audio file is valid MP3
- [ ] Quick test script works (`./test_scripts/quick_test.sh`)

---

## 🎉 Once Running

Test from your local machine:

```bash
# Quick test with auto-play
./test_scripts/quick_test.sh

# Generate all samples
./test_scripts/generate_audio.sh

# Play your 1-minute script
./test_scripts/play_script.sh
```

---

**Your Pod**: `bh1ki2a4eg8ufz`  
**SSH**: `ssh bh1ki2a4eg8ufz-644117ed@ssh.runpod.io -i ~/.ssh/id_ed25519`  
**URL**: `https://bh1ki2a4eg8ufz-8004.proxy.runpod.net`  
**Status**: Ready to start service! 🚀

