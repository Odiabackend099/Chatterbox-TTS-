#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS - RunPod GitHub Deployment"
echo "=================================================="
echo ""
echo "This will:"
echo "  1. Build Docker image that clones from GitHub"
echo "  2. Push to Docker Hub"
echo "  3. Deploy to RunPod"
echo "  4. Server will auto-start with TTS ready"
echo ""

# Check requirements
if [ -z "$RUNPOD_API_KEY" ]; then
    echo "❌ Error: RUNPOD_API_KEY not set"
    echo ""
    echo "Get your API key from: https://www.runpod.io/console/user/settings"
    echo "Then run:"
    echo "  export RUNPOD_API_KEY=your_key_here"
    echo "  $0"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker not found"
    echo "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

echo "✓ Docker is running"
echo "✓ RunPod API key found"
echo ""

# Get Docker Hub username
read -p "Enter your Docker Hub username: " DOCKER_USERNAME

if [ -z "$DOCKER_USERNAME" ]; then
    echo "❌ Error: Docker Hub username required"
    exit 1
fi

IMAGE_NAME="${DOCKER_USERNAME}/chatterbox-tts-github:latest"

# Build Docker image
echo ""
echo "=================================================="
echo "Building Docker Image"
echo "=================================================="
echo ""
echo "Image: $IMAGE_NAME"
echo ""

cd "$(dirname "$0")"

docker build -t "$IMAGE_NAME" -f Dockerfile.github .

echo ""
echo "✓ Image built successfully"
echo ""

# Login to Docker Hub
echo "=================================================="
echo "Pushing to Docker Hub"
echo "=================================================="
echo ""
echo "Please login to Docker Hub..."
echo ""

docker login

echo ""
echo "Pushing image..."
docker push "$IMAGE_NAME"

echo ""
echo "✓ Image pushed successfully"
echo ""

# Install RunPod CLI if needed
if ! command -v runpodctl &> /dev/null; then
    echo "Installing RunPod CLI..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        curl -sL https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-darwin-amd64 -o /tmp/runpodctl
    else
        curl -sL https://github.com/runpod/runpodctl/releases/latest/download/runpodctl-linux-amd64 -o /tmp/runpodctl
    fi
    chmod +x /tmp/runpodctl
    sudo mv /tmp/runpodctl /usr/local/bin/runpodctl
    echo "✓ RunPod CLI installed"
fi

# Configure RunPod CLI
runpodctl config --apiKey "$RUNPOD_API_KEY"

# Deploy to RunPod
echo ""
echo "=================================================="
echo "Deploying to RunPod"
echo "=================================================="
echo ""
echo "Available GPU types:"
echo "  - RTX 3090 (24GB)  - ~\$0.20/hr - Good for testing"
echo "  - RTX 4090 (24GB)  - ~\$0.40/hr - Recommended for production"
echo "  - A100 (40GB/80GB) - ~\$1.00/hr - High performance"
echo ""
read -p "Enter GPU type (e.g., 'NVIDIA GeForce RTX 4090'): " GPU_TYPE

if [ -z "$GPU_TYPE" ]; then
    GPU_TYPE="NVIDIA GeForce RTX 4090"
    echo "Using default: $GPU_TYPE"
fi

# Get API keys for environment
echo ""
echo "Enter your API keys (these will be set as environment variables):"
echo ""
read -p "TWILIO_ACCOUNT_SID (or press Enter to skip): " TWILIO_SID
read -p "TWILIO_AUTH_TOKEN (or press Enter to skip): " TWILIO_TOKEN
read -p "TWILIO_PHONE_NUMBER (or press Enter to skip): " TWILIO_PHONE
read -p "ANTHROPIC_API_KEY (or press Enter to skip): " ANTHROPIC_KEY
read -p "OPENAI_API_KEY (or press Enter to skip): " OPENAI_KEY

# Build environment variables
ENV_VARS="--env CHATTERBOX_DEVICE=cuda --env HF_HUB_ENABLE_HF_TRANSFER=1"

if [ ! -z "$TWILIO_SID" ]; then
    ENV_VARS="$ENV_VARS --env TWILIO_ACCOUNT_SID=$TWILIO_SID"
fi
if [ ! -z "$TWILIO_TOKEN" ]; then
    ENV_VARS="$ENV_VARS --env TWILIO_AUTH_TOKEN=$TWILIO_TOKEN"
fi
if [ ! -z "$TWILIO_PHONE" ]; then
    ENV_VARS="$ENV_VARS --env TWILIO_PHONE_NUMBER=$TWILIO_PHONE"
fi
if [ ! -z "$ANTHROPIC_KEY" ]; then
    ENV_VARS="$ENV_VARS --env ANTHROPIC_API_KEY=$ANTHROPIC_KEY"
fi
if [ ! -z "$OPENAI_KEY" ]; then
    ENV_VARS="$ENV_VARS --env OPENAI_API_KEY=$OPENAI_KEY"
fi

echo ""
echo "Creating RunPod pod..."

# Create pod
POD_CREATE_CMD="runpodctl create pod \
  --name 'chatterbox-tts-github' \
  --imageName '$IMAGE_NAME' \
  --gpuType '$GPU_TYPE' \
  --gpuCount 1 \
  --containerDiskSize 50 \
  --ports '8004/http' \
  --volumeSize 20 \
  $ENV_VARS"

echo ""
echo "Running: $POD_CREATE_CMD"
echo ""

POD_ID=$(eval $POD_CREATE_CMD | grep -oP 'Pod ID: \K[a-z0-9-]+' || echo "")

if [ -z "$POD_ID" ]; then
    echo "⚠ Could not extract Pod ID automatically"
    echo "Please check RunPod console: https://www.runpod.io/console/pods"
else
    echo ""
    echo "=================================================="
    echo "✓ Deployment Complete!"
    echo "=================================================="
    echo ""
    echo "Pod ID: $POD_ID"
    echo ""
    echo "Next steps:"
    echo "  1. Wait 2-5 minutes for pod to start"
    echo "  2. Get pod URL:"
    echo "     runpodctl get pod $POD_ID"
    echo ""
    echo "  3. Or check web console:"
    echo "     https://www.runpod.io/console/pods"
    echo ""
    echo "  4. Once running, find your pod's public URL (looks like):"
    echo "     https://xxxxx-8004.proxy.runpod.net"
    echo ""
    echo "  5. Test the API:"
    echo "     curl https://your-pod-url/health"
    echo ""
    echo "  6. Configure Twilio webhook:"
    echo "     https://your-pod-url/twilio/voice"
    echo ""
    echo "Monitor logs:"
    echo "  runpodctl logs $POD_ID -f"
    echo ""
    echo "Stop pod:"
    echo "  runpodctl stop pod $POD_ID"
    echo ""
fi

echo "=================================================="
echo ""
