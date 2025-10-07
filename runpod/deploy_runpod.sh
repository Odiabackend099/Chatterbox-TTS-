#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS RunPod Deployment Script"
echo "=================================================="
echo ""

# Check for RunPod CLI
if ! command -v runpodctl &> /dev/null; then
    echo "RunPod CLI not found. Installing..."
    curl -sL https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-linux-amd64 -o runpodctl
    chmod +x runpodctl
    sudo mv runpodctl /usr/local/bin/
    echo "✓ RunPod CLI installed"
fi

# Check for API key
if [ -z "$RUNPOD_API_KEY" ]; then
    echo "Error: RUNPOD_API_KEY environment variable not set"
    echo "Get your API key from: https://www.runpod.io/console/user/settings"
    echo "Then run: export RUNPOD_API_KEY=your_key_here"
    exit 1
fi

# Configure RunPod CLI
runpodctl config --apiKey "$RUNPOD_API_KEY"

# Build Docker image
echo ""
echo "Building Docker image..."
docker build -t chatterbox-tts:runpod -f runpod/Dockerfile.runpod .

# Tag for registry
echo "Tagging image for Docker Hub..."
read -p "Enter your Docker Hub username: " DOCKER_USERNAME
docker tag chatterbox-tts:runpod ${DOCKER_USERNAME}/chatterbox-tts:latest

# Push to Docker Hub
echo "Pushing to Docker Hub..."
docker login
docker push ${DOCKER_USERNAME}/chatterbox-tts:latest

echo "✓ Image pushed to ${DOCKER_USERNAME}/chatterbox-tts:latest"

# Create RunPod template
echo ""
echo "Creating RunPod pod template..."

cat > runpod_template.json << EOF
{
  "name": "Chatterbox TTS Server",
  "imageName": "${DOCKER_USERNAME}/chatterbox-tts:latest",
  "dockerArgs": "",
  "containerDiskInGb": 50,
  "volumeInGb": 0,
  "volumeMountPath": "/workspace",
  "ports": "8004/http",
  "env": [
    {
      "key": "CHATTERBOX_HOST",
      "value": "0.0.0.0"
    },
    {
      "key": "CHATTERBOX_PORT",
      "value": "8004"
    },
    {
      "key": "CHATTERBOX_DEVICE",
      "value": "cuda"
    },
    {
      "key": "HF_HUB_ENABLE_HF_TRANSFER",
      "value": "1"
    }
  ],
  "startScript": "python /app/scripts/server.py"
}
EOF

echo "✓ Template created: runpod_template.json"

# Deploy pod
echo ""
echo "Deploying pod to RunPod..."
echo ""
echo "Available GPU types:"
echo "  - RTX 4090 (24GB) - Recommended for production"
echo "  - RTX A5000 (24GB) - Good balance of performance and cost"
echo "  - RTX 3090 (24GB) - Budget option"
echo "  - A100 (40GB/80GB) - High performance, higher cost"
echo ""
read -p "Enter GPU type (e.g., 'NVIDIA GeForce RTX 4090'): " GPU_TYPE
read -p "Enter number of GPUs (1 recommended): " GPU_COUNT

# Create pod
POD_ID=$(runpodctl create pod \
  --name "chatterbox-tts-prod" \
  --imageName "${DOCKER_USERNAME}/chatterbox-tts:latest" \
  --gpuType "$GPU_TYPE" \
  --gpuCount "$GPU_COUNT" \
  --containerDiskSize 50 \
  --ports "8004/http" \
  --env CHATTERBOX_DEVICE=cuda \
  --env HF_HUB_ENABLE_HF_TRANSFER=1 \
  --env TWILIO_ACCOUNT_SID="$TWILIO_ACCOUNT_SID" \
  --env TWILIO_AUTH_TOKEN="$TWILIO_AUTH_TOKEN" \
  --env ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  | grep -oP 'Pod ID: \K[a-z0-9-]+')

echo ""
echo "=================================================="
echo "Deployment Complete!"
echo "=================================================="
echo ""
echo "Pod ID: $POD_ID"
echo ""
echo "Next steps:"
echo "1. Wait for pod to start (check status with: runpodctl get pod $POD_ID)"
echo "2. Get pod URL: runpodctl get pod $POD_ID | grep 'Connect URL'"
echo "3. Test API: curl https://your-pod-url.runpod.net:8004/health"
echo "4. Configure Twilio webhook to point to: https://your-pod-url.runpod.net:8004/twilio/voice"
echo ""
echo "Monitor logs: runpodctl logs $POD_ID"
echo "Stop pod: runpodctl stop pod $POD_ID"
echo "Delete pod: runpodctl delete pod $POD_ID"
echo ""
