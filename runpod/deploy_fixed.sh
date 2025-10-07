#!/bin/bash
# Deploy to RunPod with correct port configuration

set -e

echo "=================================================="
echo "🚀 RunPod Deployment - Port 8888 (HTTP Proxy)"
echo "=================================================="
echo ""

# Build and push Docker image
IMAGE_NAME="your-dockerhub-username/chatterbox-tts-runpod"
IMAGE_TAG="latest"

echo "📦 Building Docker image..."
docker build -f runpod/Dockerfile.fixed -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo ""
echo "⬆️  Pushing to Docker Hub..."
docker push ${IMAGE_NAME}:${IMAGE_TAG}

echo ""
echo "✅ Image ready: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "=================================================="
echo "📋 RunPod Configuration"
echo "=================================================="
echo ""
echo "1. Go to: https://www.runpod.io/console/deploy"
echo ""
echo "2. Template Settings:"
echo "   - Container Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "   - Docker Command: (leave empty, uses CMD from Dockerfile)"
echo ""
echo "3. CRITICAL - HTTP Service Configuration:"
echo "   - Port: 8888"
echo "   - Service Name: Chatterbox TTS API"
echo ""
echo "4. Environment Variables (optional):"
echo "   - CHATTERBOX_PORT=8888"
echo "   - CHATTERBOX_DEVICE=cuda"
echo ""
echo "5. Volume Mounts (optional):"
echo "   - Container Path: /workspace/hf_cache"
echo "   - Size: 20GB (for model caching)"
echo ""
echo "=================================================="
echo "🧪 Testing After Deployment"
echo "=================================================="
echo ""
echo "Replace YOUR-POD-ID with your actual pod ID:"
echo ""
echo "# Health check"
echo "curl https://YOUR-POD-ID-8888.proxy.runpod.net/health"
echo ""
echo "# API docs"
echo "open https://YOUR-POD-ID-8888.proxy.runpod.net/docs"
echo ""
echo "# Generate TTS"
echo "curl -X POST https://YOUR-POD-ID-8888.proxy.runpod.net/api/tts \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"text\":\"Hello from RunPod!\",\"voice\":\"emily-en-us\"}' \\"
echo "  --output test.wav"
echo ""
echo "=================================================="

