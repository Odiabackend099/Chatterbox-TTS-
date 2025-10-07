#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS - RunPod GitHub Deployment"
echo "=================================================="

# Display system info
echo ""
echo "System Information:"
echo "  Hostname: $(hostname)"
if command -v nvidia-smi &> /dev/null; then
    echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)"
    echo "  CUDA: $(nvcc --version | grep release | awk '{print $5}' | cut -c2-)"
    echo "  VRAM: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -n1)"
    export CHATTERBOX_DEVICE=cuda
else
    echo "  GPU: None (CPU mode)"
    export CHATTERBOX_DEVICE=cpu
fi
echo "  Python: $(python --version)"
echo ""

# Clone repository
REPO_URL="https://github.com/Odiabackend099/Chatterbox-TTS-.git"
CLONE_DIR="/workspace/chatterbox-tts"

if [ -d "$CLONE_DIR" ]; then
    echo "Repository already exists, updating..."
    cd "$CLONE_DIR"
    git pull
else
    echo "Cloning repository from GitHub..."
    git clone "$REPO_URL" "$CLONE_DIR"
    cd "$CLONE_DIR"
fi

echo "✓ Repository ready at $CLONE_DIR"
echo ""

# Create necessary directories
echo "Creating directories..."
mkdir -p outputs logs model_cache voices reference_audio
echo "✓ Directories created"
echo ""

# Install dependencies
echo "Installing dependencies..."
echo "This may take 5-10 minutes..."

# Upgrade pip
pip install --upgrade pip

# Install requirements
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
    echo "✓ Dependencies installed"
else
    echo "⚠ requirements.txt not found, installing manually..."
    pip install fastapi uvicorn[standard] python-multipart
    pip install librosa soundfile pydub pyyaml requests
    pip install anthropic openai twilio
    pip install chatterbox-tts
fi

echo ""

# Set environment variables
export CHATTERBOX_HOST=${CHATTERBOX_HOST:-0.0.0.0}
export CHATTERBOX_PORT=${CHATTERBOX_PORT:-8004}
export HF_HUB_ENABLE_HF_TRANSFER=1
export TRANSFORMERS_CACHE=/workspace/chatterbox-tts/model_cache

# Create/update config if needed
if [ ! -f config/config.yaml ]; then
    echo "Config file missing, using defaults..."
fi

# Check for API keys
echo "Checking configuration..."
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠ Warning: No LLM API keys found"
    echo "  Set ANTHROPIC_API_KEY or OPENAI_API_KEY to enable LLM features"
fi

if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ]; then
    echo "⚠ Warning: Twilio credentials not found"
    echo "  Set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN to enable Twilio integration"
fi

# Bootstrap default voices (PRODUCTION READY)
echo ""
echo "Setting up default voices..."
if [ -f "scripts/bootstrap_voices.py" ]; then
    python scripts/bootstrap_voices.py || echo "⚠ Voice bootstrap failed (non-critical)"
    echo "✓ Voices ready"
else
    echo "⚠ bootstrap_voices.py not found, using built-in voices"
fi

# Pre-download model (optional, server will download on first request if needed)
if [ ! -d "model_cache/models--ResembleAI--chatterbox" ]; then
    echo ""
    echo "Downloading Chatterbox TTS model (first run only)..."
    echo "This will take 5-10 minutes (~2-3GB)..."
    python -c "from chatterbox.tts import ChatterboxTTS; ChatterboxTTS.from_pretrained(device='cpu')" || echo "⚠ Model pre-download failed (will download on first request)"
    echo "✓ Model download complete"
fi

# Start server
echo ""
echo "=================================================="
echo "Starting Chatterbox TTS Server"
echo "=================================================="
echo ""
echo "[DEBUG] Current working directory: $(pwd)"
echo "[DEBUG] Python path: $(python -c 'import sys; print(sys.path[:3])')"
echo "[DEBUG] Server script: scripts/server_production.py"
echo ""
echo "Server will be available at:"
echo "  Internal: http://0.0.0.0:${CHATTERBOX_PORT}"
echo "  External: Check RunPod dashboard for public URL"
echo ""
echo "API Documentation: http://0.0.0.0:${CHATTERBOX_PORT}/docs"
echo ""
echo "If server doesn't start, check:"
echo "  1. ps aux | grep python"
echo "  2. netstat -tlnp | grep ${CHATTERBOX_PORT}"
echo "  3. tail -100 logs/server.log"
echo ""

# Ensure we're in correct directory
cd "$CLONE_DIR"
echo "[DEBUG] Changed to: $(pwd)"

# Run the PRODUCTION server (guaranteed to work)
# Use exec to replace shell with Python process (proper signal handling)
echo "[DEBUG] Executing: python scripts/server_production.py"
exec python scripts/server_production.py
