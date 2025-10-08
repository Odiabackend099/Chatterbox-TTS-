#!/bin/bash

##############################################################################
# RUNPOD DEPLOYMENT - AUTOMATED SETUP
##############################################################################
# This script automates the complete deployment on RunPod
# Run this ON YOUR RUNPOD POD after SSH'ing in
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
echo -e "${BLUE}  Pod ID: a288y3vpbfxwkk${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check if we're on RunPod
if [ ! -d "/workspace" ]; then
    echo -e "${YELLOW}⚠ Warning: /workspace not found. Are you on RunPod?${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

cd /workspace

##############################################################################
# Step 1: System Dependencies
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 1: Installing System Dependencies${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

apt-get update -qq
apt-get install -y -qq git curl wget ffmpeg libsndfile1 > /dev/null 2>&1

echo -e "${GREEN}✓ System dependencies installed${NC}\n"

##############################################################################
# Step 2: Clone Repository
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 2: Cloning Repository${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ -d "chatterbox-twilio-integration" ]; then
    echo -e "${YELLOW}Directory exists. Updating...${NC}"
    cd chatterbox-twilio-integration
    git pull origin main
else
    echo -e "${BLUE}Cloning from GitHub...${NC}"
    git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-twilio-integration
    cd chatterbox-twilio-integration
fi

echo -e "${GREEN}✓ Repository ready${NC}\n"

##############################################################################
# Step 3: Python Dependencies
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 3: Installing Python Dependencies${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

pip install --upgrade pip -q
pip install -r requirements.txt -q
pip install fastapi uvicorn[standard] httpx python-multipart -q

echo -e "${GREEN}✓ Python dependencies installed${NC}\n"

##############################################################################
# Step 4: Create Environment File
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 4: Configuring Environment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

cat > .env << 'EOF'
# TTS Configuration
TTS_PORT=8004
PYTHONUNBUFFERED=1

# API Keys
API_KEY_1=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
API_KEY_2=cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI
API_KEY_3=cw_live_9rSEdn-4tfW-blbihfBsm08S1Zggs0OaJuLbCFXGKd8

# Model Cache
TRANSFORMERS_CACHE=/workspace/model_cache
HF_HOME=/workspace/model_cache
EOF

echo -e "${GREEN}✓ Environment configured${NC}\n"

##############################################################################
# Step 5: Create Directories
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 5: Creating Directories${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

mkdir -p logs outputs model_cache

echo -e "${GREEN}✓ Directories created${NC}\n"

##############################################################################
# Step 6: Check GPU
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 6: GPU Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

python3 << 'PYEOF'
import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
else:
    print("⚠ WARNING: No GPU detected!")
PYEOF

echo ""

##############################################################################
# Step 7: Start TTS Service
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 7: Starting TTS Service${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Kill any existing service on port 8004
lsof -ti :8004 | xargs kill -9 2>/dev/null || true

# Start in background
nohup python scripts/server_production.py > logs/tts.log 2>&1 &
PID=$!

echo -e "${GREEN}✓ TTS service started (PID: $PID)${NC}\n"

# Wait for service to start
echo -e "${YELLOW}Waiting for service to start...${NC}"
sleep 5

##############################################################################
# Step 8: Test Service
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Step 8: Testing Service${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Test health endpoint
if curl -s http://localhost:8004/health > /dev/null; then
    echo -e "${GREEN}✓ Service is responding${NC}"
    curl -s http://localhost:8004/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:8004/health
else
    echo -e "${RED}✗ Service not responding${NC}"
    echo -e "${YELLOW}Check logs: tail -f logs/tts.log${NC}"
fi

echo ""

##############################################################################
# Summary
##############################################################################

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Deployment Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Your TTS Service URLs:${NC}"
echo -e "  Local:  ${GREEN}http://localhost:8004${NC}"
echo -e "  Public: ${GREEN}https://a288y3vpbfxwkk-8888.proxy.runpod.net${NC}\n"

echo -e "${BLUE}Quick Commands:${NC}"
echo -e "  Check health:  ${YELLOW}curl http://localhost:8004/health${NC}"
echo -e "  View logs:     ${YELLOW}tail -f logs/tts.log${NC}"
echo -e "  Check process: ${YELLOW}ps aux | grep server_production${NC}"
echo -e "  Restart:       ${YELLOW}pkill -f server_production && python scripts/server_production.py &${NC}\n"

echo -e "${BLUE}Test from your local machine:${NC}"
echo -e "  ${YELLOW}curl https://a288y3vpbfxwkk-8888.proxy.runpod.net/health${NC}\n"

echo -e "${GREEN}🎉 Ready to use!${NC}\n"

