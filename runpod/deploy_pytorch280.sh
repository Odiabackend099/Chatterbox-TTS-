#!/bin/bash

##############################################################################
# Deploy Chatterbox TTS to RunPod
# PyTorch 2.8.0 + CUDA 12.8.1 + Ubuntu 24.04
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Chatterbox TTS - RunPod Deployment${NC}"
echo -e "${BLUE}  PyTorch 2.8.0 + CUDA 12.8.1${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Configuration
DOCKER_IMAGE="chatterbox-tts:runpod-pytorch280"
DOCKERFILE="runpod/Dockerfile.pytorch280"

echo -e "${YELLOW}Configuration:${NC}"
echo -e "  Docker Image: $DOCKER_IMAGE"
echo -e "  Dockerfile: $DOCKERFILE"
echo -e "  Base Image: runpod/pytorch:1.0.1-cu1281-torch280-ubuntu2404"
echo -e ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    echo -e "${YELLOW}  Please start Docker and try again${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}\n"

# Build Docker image
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 1: Building Docker Image${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

docker build -f "$DOCKERFILE" -t "$DOCKER_IMAGE" .

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✓ Docker image built successfully${NC}\n"
else
    echo -e "\n${RED}✗ Docker build failed${NC}"
    exit 1
fi

# Test the image locally (optional)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 2: Test Locally (Optional)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}To test locally, run:${NC}"
echo -e "  docker run --gpus all -p 8004:8004 $DOCKER_IMAGE"
echo -e ""
echo -e "${YELLOW}Then test:${NC}"
echo -e "  curl http://localhost:8004/health"
echo -e ""

# Push to registry (if configured)
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 3: Push to Registry${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ -n "$DOCKER_REGISTRY" ]; then
    REGISTRY_IMAGE="$DOCKER_REGISTRY/$DOCKER_IMAGE"
    
    echo -e "${YELLOW}Tagging image for registry...${NC}"
    docker tag "$DOCKER_IMAGE" "$REGISTRY_IMAGE"
    
    echo -e "${YELLOW}Pushing to $DOCKER_REGISTRY...${NC}"
    docker push "$REGISTRY_IMAGE"
    
    echo -e "${GREEN}✓ Image pushed to registry${NC}\n"
    echo -e "${BLUE}Registry Image:${NC} $REGISTRY_IMAGE"
else
    echo -e "${YELLOW}⚠ DOCKER_REGISTRY not set - skipping push${NC}"
    echo -e "${YELLOW}  Set DOCKER_REGISTRY to push to a registry:${NC}"
    echo -e "  export DOCKER_REGISTRY=your-registry.com/your-username"
    echo -e "  Then run this script again"
fi

echo -e ""

# RunPod deployment instructions
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 4: Deploy to RunPod${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}RunPod Deployment Instructions:${NC}\n"

echo -e "1. ${GREEN}Go to RunPod Console${NC}"
echo -e "   https://www.runpod.io/console/pods\n"

echo -e "2. ${GREEN}Click 'Deploy' or '+ GPU Pod'${NC}\n"

echo -e "3. ${GREEN}Select GPU:${NC}"
echo -e "   - Recommended: RTX 4090, A4000, or better"
echo -e "   - Minimum: RTX 3060 12GB\n"

echo -e "4. ${GREEN}Configure Pod:${NC}"
if [ -n "$DOCKER_REGISTRY" ]; then
    echo -e "   - Container Image: ${BLUE}$REGISTRY_IMAGE${NC}"
else
    echo -e "   - Container Image: ${BLUE}$DOCKER_IMAGE${NC}"
    echo -e "     ${YELLOW}(Push to registry first or upload image)${NC}"
fi
echo -e "   - Container Disk: ${BLUE}20 GB${NC}"
echo -e "   - Volume Disk: ${BLUE}50 GB${NC} (for model cache)"
echo -e "   - Volume Path: ${BLUE}/workspace${NC}\n"

echo -e "5. ${GREEN}Expose Ports:${NC}"
echo -e "   - HTTP Port: ${BLUE}8004${NC}\n"

echo -e "6. ${GREEN}Environment Variables:${NC}"
echo -e "   Add your API keys:"
echo -e "   ${BLUE}API_KEY_1${NC}=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU"
echo -e "   ${BLUE}API_KEY_2${NC}=cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI"
echo -e "   ${BLUE}TTS_PORT${NC}=8004"
echo -e "   ${BLUE}PRELOAD_MODEL${NC}=true (optional, speeds up startup)\n"

echo -e "7. ${GREEN}Deploy and Wait${NC}"
echo -e "   - Initial startup: ~3-5 minutes"
echo -e "   - Model download: ~2-3 minutes (first time)\n"

echo -e "8. ${GREEN}Get Your Pod URL${NC}"
echo -e "   - Format: ${BLUE}https://YOUR-POD-ID-8004.proxy.runpod.net${NC}"
echo -e "   - Test: ${BLUE}https://YOUR-POD-ID-8004.proxy.runpod.net/health${NC}\n"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Build Complete!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Push image to Docker registry (if not done)"
echo -e "  2. Deploy to RunPod using instructions above"
echo -e "  3. Get your pod URL"
echo -e "  4. Update scripts with your pod URL"
echo -e ""

