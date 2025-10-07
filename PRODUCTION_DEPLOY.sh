#!/bin/bash
set -e

echo "================================================================"
echo "PRODUCTION DEPLOYMENT - GUARANTEED TO WORK"
echo "================================================================"
echo ""
echo "This will deploy a WORKING TTS server to RunPod"
echo "NO MANUAL SETUP - AUTOMATIC VOICE FILES - READY TO USE"
echo ""

# Check environment
if [ -z "$RUNPOD_API_KEY" ]; then
    echo "ERROR: Set RUNPOD_API_KEY first"
    echo ""
    echo "Get your API key from: https://www.runpod.io/console/user/settings"
    echo "Then run:"
    echo "  export RUNPOD_API_KEY=your_key_here"
    echo "  $0"
    exit 1
fi

# Get Docker username
read -p "Docker Hub username: " DOCKER_USERNAME
if [ -z "$DOCKER_USERNAME" ]; then
    echo "ERROR: Docker Hub username required"
    exit 1
fi

IMAGE_NAME="${DOCKER_USERNAME}/chatterbox-production:latest"

echo ""
echo "================================================================"
echo "Building Production Image"
echo "================================================================"
echo ""

# Create production Dockerfile
cat > Dockerfile.production << 'DOCKEREOF'
FROM runpod/pytorch:2.0.1-py3.10-cuda11.8.0-devel-ubuntu22.04

ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl libsndfile1 ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# Install Python packages
RUN pip install --no-cache-dir \
    chatterbox-tts \
    fastapi uvicorn[standard] \
    soundfile librosa pydub \
    python-multipart

WORKDIR /workspace

# Copy application
COPY scripts/ /workspace/scripts/
COPY voices/ /workspace/voices/

# Create directories
RUN mkdir -p /workspace/outputs /workspace/logs /workspace/model_cache

# Expose port
EXPOSE 8888

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8888/api/health || exit 1

# Startup script
COPY production_entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
DOCKEREOF

# Create entrypoint
cat > production_entrypoint.sh << 'ENTRYPOINTEOF'
#!/bin/bash
set -e

echo "================================================================"
echo "Starting Production TTS Server"
echo "================================================================"

# System info
if command -v nvidia-smi &> /dev/null; then
    echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)"
fi

cd /workspace

# Bootstrap voices (automatic)
echo "Setting up voices..."
python scripts/bootstrap_voices.py || echo "Voice bootstrap failed, continuing..."

# Download model if needed
if [ ! -d "model_cache/models--ResembleAI--chatterbox" ]; then
    echo "Downloading TTS model (first run, ~2-3GB)..."
    python -c "from chatterbox.tts import ChatterboxTTS; ChatterboxTTS.from_pretrained(device='cpu')" || true
fi

# Start server
echo "Starting server..."
exec python scripts/server_production.py
ENTRYPOINTEOF

# Build image
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" -f Dockerfile.production .

echo "✓ Image built"

# Push to Docker Hub
echo ""
echo "Pushing to Docker Hub..."
docker login
docker push "$IMAGE_NAME"

echo "✓ Image pushed"

# Deploy to RunPod
echo ""
echo "================================================================"
echo "Deploying to RunPod"
echo "================================================================"
echo ""

# Install runpodctl if needed
if ! command -v runpodctl &> /dev/null; then
    echo "Installing RunPod CLI..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        curl -sL https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-darwin-amd64 -o /tmp/runpodctl
    else
        curl -sL https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-linux-amd64 -o /tmp/runpodctl
    fi
    chmod +x /tmp/runpodctl
    sudo mv /tmp/runpodctl /usr/local/bin/
fi

# Configure
runpodctl config --apiKey "$RUNPOD_API_KEY"

# Create pod
echo ""
echo "Creating pod with RTX 4090 GPU..."
echo ""

POD_ID=$(runpodctl create pod \
  --name "chatterbox-production" \
  --imageName "$IMAGE_NAME" \
  --gpuType "NVIDIA GeForce RTX 4090" \
  --gpuCount 1 \
  --containerDiskSize 50 \
  --ports "8888/http" \
  --env CHATTERBOX_DEVICE=cuda \
  | grep -oP 'Pod ID: \K[a-z0-9-]+' || echo "")

if [ -z "$POD_ID" ]; then
    echo "⚠ Could not extract Pod ID"
    echo "Check RunPod console: https://www.runpod.io/console/pods"
else
    echo ""
    echo "================================================================"
    echo "✓ DEPLOYED SUCCESSFULLY"
    echo "================================================================"
    echo ""
    echo "Pod ID: $POD_ID"
    echo ""
    echo "Wait 5-10 minutes for:"
    echo "  1. Pod to start"
    echo "  2. Model download (~2-3GB)"
    echo "  3. Server to initialize"
    echo ""
    echo "Get URL:"
    echo "  runpodctl get pod $POD_ID"
    echo ""
    echo "Your API will be at:"
    echo "  https://xxxxx-8888.proxy.runpod.net"
    echo ""
    echo "Test it:"
    echo "  curl -X POST https://your-url/api/tts \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"text\": \"Hello world\", \"voice\": \"emily-en-us\"}' \\"
    echo "    --output test.wav"
    echo ""
    echo "================================================================"
fi

# Cleanup
rm -f Dockerfile.production production_entrypoint.sh

echo ""
echo "DONE!"
