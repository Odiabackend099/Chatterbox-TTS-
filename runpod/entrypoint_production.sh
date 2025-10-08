#!/bin/bash

##############################################################################
# Chatterbox TTS - RunPod Production Entrypoint
# For PyTorch 2.8.0 + CUDA 12.8.1 + Ubuntu 24.04
##############################################################################

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Chatterbox TTS - Starting on RunPod"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Display system information
echo "📊 System Information:"
echo "  - Python: $(python --version)"
echo "  - PyTorch: $(python -c 'import torch; print(torch.__version__)')"
echo "  - CUDA Available: $(python -c 'import torch; print(torch.cuda.is_available())')"
if python -c 'import torch; exit(0 if torch.cuda.is_available() else 1)' 2>/dev/null; then
    echo "  - CUDA Version: $(python -c 'import torch; print(torch.version.cuda)')"
    echo "  - GPU: $(python -c 'import torch; print(torch.cuda.get_device_name(0))' 2>/dev/null || echo 'N/A')"
fi
echo "  - Working Directory: $(pwd)"
echo ""

# Create directories if they don't exist
echo "📁 Setting up directories..."
mkdir -p /workspace/outputs /workspace/logs /workspace/model_cache /workspace/hf_cache
chmod -R 777 /workspace/outputs /workspace/logs /workspace/model_cache /workspace/hf_cache
echo "✓ Directories ready"
echo ""

# Set environment variables
export PYTHONUNBUFFERED=1
export HF_HOME=/workspace/hf_cache
export TRANSFORMERS_CACHE=/workspace/model_cache
export TORCH_HOME=/workspace/model_cache

# Check for API keys in environment
echo "🔑 Checking configuration..."
if [ -n "$API_KEY_1" ]; then
    echo "✓ API keys detected in environment"
else
    echo "⚠ No API keys in environment - using config file"
fi
echo ""

# Test imports
echo "🧪 Testing Python imports..."
python -c "import torch; import fastapi; import uvicorn; print('✓ Core dependencies OK')"
echo ""

# Pre-download model if not cached (optional)
if [ "$PRELOAD_MODEL" = "true" ]; then
    echo "📦 Pre-loading TTS model..."
    python -c "from transformers import AutoModel; AutoModel.from_pretrained('ResembleAI/chatterbox', cache_dir='/workspace/model_cache')" || echo "⚠ Model preload skipped"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Starting TTS Service on Port ${TTS_PORT:-8004}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Execute the command passed to the container
exec "$@"

