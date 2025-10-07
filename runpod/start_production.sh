#!/bin/bash
# Production-Ready RunPod Deployment
# Fixes all known issues and optimizes for RunPod environment

set -e

echo "=================================================="
echo "🚀 Chatterbox TTS - Production Deployment"
echo "=================================================="
echo ""

# Navigate to workspace
cd /workspace

# Clean previous installation
if [ -d "chatterbox-tts" ]; then
    echo "🗑️  Removing old installation..."
    rm -rf chatterbox-tts
fi

# Clone latest code
echo "📥 Cloning from GitHub..."
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-tts
cd chatterbox-tts

echo "✓ Code cloned"
echo ""

# Verify latest fixes
echo "📋 Checking version..."
git log --oneline -3
echo ""

# Create directories
echo "📁 Setting up directories..."
mkdir -p outputs logs model_cache voices reference_audio
echo "✓ Directories created"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
pip install -q -r requirements.txt
echo "✓ Dependencies installed"
echo ""

# Kill any conflicting processes
echo "🔪 Stopping conflicting services..."
pkill -f jupyter || true
pkill -f server || true
sleep 2
echo "✓ Clean environment"
echo ""

# Set environment variables
echo "⚙️  Configuring environment..."
export CHATTERBOX_PORT=8888
export CHATTERBOX_HOST=0.0.0.0
export CHATTERBOX_DEVICE=cuda
export PYTHONUNBUFFERED=1
# Disable HF_TRANSFER to avoid dependency issues
unset HF_HUB_ENABLE_HF_TRANSFER
echo "✓ Environment configured"
echo ""

# Bootstrap voices
echo "🎤 Setting up default voices..."
python scripts/bootstrap_voices.py
echo "✓ Voices ready"
echo ""

# Display configuration
echo "=================================================="
echo "📊 Configuration Summary"
echo "=================================================="
echo "  Port: 8888 (RunPod HTTP Proxy)"
echo "  Host: 0.0.0.0"
echo "  Device: CUDA"
echo "  Voices: 5 default voices"
echo "  Latest Fixes:"
echo "    ✓ /health endpoint for healthcheck"
echo "    ✓ Port 8888 for RunPod proxy"
echo "    ✓ WAV encoding optimized"
echo "    ✓ TTS parameter fixes"
echo "=================================================="
echo ""

# Start server
echo "🚀 Starting Chatterbox TTS Server..."
echo "=================================================="
echo ""
exec python scripts/server_production.py
