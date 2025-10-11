#!/bin/bash
# Deploy Maya Voice Optimization to RunPod
# Updates voice configuration and restarts TTS service

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Deploy Maya Voice to RunPod${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Configuration
POD_ID="aav4qfa6yqgt3k"
POD_SSH="root@ssh.runpod.io"
WORKSPACE="/workspace/chatterbox-twilio-integration"

echo -e "${YELLOW}Step 1: Copying updated files to RunPod...${NC}"

# Copy bootstrap_voices.py
echo "  - bootstrap_voices.py"
scp scripts/bootstrap_voices.py "${POD_SSH}:${WORKSPACE}/scripts/" || {
    echo -e "${RED}✗ Failed to copy bootstrap_voices.py${NC}"
    echo "  Try manual deployment (see instructions below)"
    exit 1
}

# Copy voice_manager.py
echo "  - voice_manager.py"
scp scripts/voice_manager.py "${POD_SSH}:${WORKSPACE}/scripts/" || {
    echo -e "${RED}✗ Failed to copy voice_manager.py${NC}"
    exit 1
}

# Copy api_production.py
echo "  - api_production.py"
scp scripts/api_production.py "${POD_SSH}:${WORKSPACE}/scripts/" || {
    echo -e "${RED}✗ Failed to copy api_production.py${NC}"
    exit 1
}

echo -e "${GREEN}✓ Files copied successfully${NC}\n"

echo -e "${YELLOW}Step 2: Regenerating voice configurations on RunPod...${NC}"

ssh "${POD_SSH}" << 'ENDSSH'
cd /workspace/chatterbox-twilio-integration
echo "Bootstrapping new voices..."
python3 scripts/bootstrap_voices.py
echo "✓ Voices regenerated"
ENDSSH

echo -e "${GREEN}✓ Voice configurations updated${NC}\n"

echo -e "${YELLOW}Step 3: Restarting TTS service...${NC}"

ssh "${POD_SSH}" << 'ENDSSH'
# Kill existing server
echo "Stopping old server..."
pkill -f server_production || echo "No existing server found"
sleep 2

# Start new server
cd /workspace/chatterbox-twilio-integration
echo "Starting server with new voice configuration..."
nohup python3 scripts/server_production.py > logs/tts.log 2>&1 &
sleep 3

# Check if started
if ps aux | grep -v grep | grep server_production > /dev/null; then
    echo "✓ Server restarted successfully"
else
    echo "✗ Server failed to start - check logs"
    exit 1
fi
ENDSSH

echo -e "${GREEN}✓ TTS service restarted${NC}\n"

echo -e "${YELLOW}Step 4: Verifying deployment...${NC}"

sleep 5

# Test health endpoint
HEALTH_RESPONSE=$(curl -s --max-time 10 "https://${POD_ID}-8888.proxy.runpod.net/api/health")
if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✓ Service is healthy${NC}"
else
    echo -e "${RED}✗ Service not responding correctly${NC}"
    echo "$HEALTH_RESPONSE"
    exit 1
fi

# Test voice list
VOICES_RESPONSE=$(curl -s --max-time 10 "https://${POD_ID}-8888.proxy.runpod.net/api/voices")
if echo "$VOICES_RESPONSE" | grep -q 'maya-professional'; then
    echo -e "${GREEN}✓ Maya voice is available${NC}"
    echo "$VOICES_RESPONSE" | jq -r '.voices[] | select(.slug=="maya-professional") | "  Name: \(.name)\n  Slug: \(.slug)\n  Description: \(.description)"' 2>/dev/null || echo "  (jq not available for formatting)"
else
    echo -e "${RED}✗ Maya voice not found in voice list${NC}"
    echo "$VOICES_RESPONSE"
    exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ DEPLOYMENT COMPLETE!${NC}\n"
echo -e "${BLUE}Maya voice is now live on:${NC}"
echo "  https://${POD_ID}-8888.proxy.runpod.net/api/tts"
echo ""
echo -e "${BLUE}Test it:${NC}"
echo "  ./test_maya_voice_quality.sh"
echo ""
echo -e "${BLUE}View logs:${NC}"
echo "  ssh ${POD_SSH}"
echo "  tail -f ${WORKSPACE}/logs/tts.log"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

