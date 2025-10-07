#!/bin/bash
set -e

echo "=================================================="
echo "Starting Chatterbox TTS Server on RunPod"
echo "=================================================="

# Display system info
echo ""
echo "System Information:"
echo "  Hostname: $(hostname)"
echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)"
echo "  CUDA: $(nvcc --version | grep release | awk '{print $5}' | cut -c2-)"
echo "  VRAM: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -n1)"
echo "  Python: $(python --version)"
echo ""

# Set device to CUDA if available
if command -v nvidia-smi &> /dev/null; then
    export CHATTERBOX_DEVICE=cuda
    echo "✓ NVIDIA GPU detected, using CUDA"
else
    export CHATTERBOX_DEVICE=cpu
    echo "⚠ No GPU detected, using CPU mode"
fi

# Create directories if they don't exist
mkdir -p /app/outputs /app/logs /app/model_cache /app/hf_cache

# Check for API keys
echo ""
echo "Checking configuration..."
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠ Warning: No LLM API keys found"
    echo "  Set ANTHROPIC_API_KEY or OPENAI_API_KEY to enable LLM features"
fi

if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ]; then
    echo "⚠ Warning: Twilio credentials not found"
    echo "  Set TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN to enable Twilio integration"
fi

# Pre-download model if not cached
if [ ! -d "/app/hf_cache/models--ResembleAI--chatterbox" ]; then
    echo ""
    echo "Downloading Chatterbox TTS model (first run only)..."
    echo "This may take 5-10 minutes depending on network speed..."
    python -c "from chatterbox.tts import ChatterboxTTS; ChatterboxTTS.from_pretrained(device='cpu')"
    echo "✓ Model downloaded successfully"
fi

# Start server
echo ""
echo "=================================================="
echo "Starting server on port ${CHATTERBOX_PORT:-8004}..."
echo "=================================================="
echo ""

# Execute the command passed to the container
exec "$@"
