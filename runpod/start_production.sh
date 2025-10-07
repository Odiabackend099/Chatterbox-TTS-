#!/bin/bash
################################################################################
# RunPod Production TTS Server - Startup Script
# Pod ID: dmbt2v5xek8fou
#
# This script:
# 1. Kills any conflicting processes (JupyterLab on port 8888)
# 2. Starts TTS server in background with logging
# 3. Monitors startup and reports status
# 4. Provides health check endpoint
################################################################################

set -e

# Configuration
WORKSPACE_DIR="/workspace/chatterbox-tts"
LOG_FILE="${WORKSPACE_DIR}/logs/tts_server.log"
PID_FILE="${WORKSPACE_DIR}/logs/tts_server.pid"
PORT=8888

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}🚀 RunPod TTS Production Server${NC}"
echo -e "${GREEN}Pod: dmbt2v5xek8fou${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""

# Step 1: Setup directories
echo -e "${YELLOW}📁 Setting up directories...${NC}"
cd ${WORKSPACE_DIR}
mkdir -p logs outputs model_cache

# Step 2: Kill conflicting processes
echo -e "${YELLOW}🔄 Checking for processes on port ${PORT}...${NC}"
PID_ON_PORT=$(lsof -ti:${PORT} || echo "")
if [ -n "$PID_ON_PORT" ]; then
    echo -e "${YELLOW}   Found process(es) on port ${PORT}: ${PID_ON_PORT}${NC}"
    echo -e "${YELLOW}   Stopping conflicting processes...${NC}"
    kill -9 ${PID_ON_PORT}
    sleep 2
    echo -e "${GREEN}   ✓ Cleared port ${PORT}${NC}"
else
    echo -e "${GREEN}   ✓ Port ${PORT} is available${NC}"
fi

# Step 3: Kill any old TTS server instances
if [ -f "${PID_FILE}" ]; then
    OLD_PID=$(cat ${PID_FILE})
    if ps -p ${OLD_PID} > /dev/null 2>&1; then
        echo -e "${YELLOW}   Stopping old TTS server (PID: ${OLD_PID})...${NC}"
        kill -9 ${OLD_PID} || true
        sleep 2
    fi
    rm -f ${PID_FILE}
fi

# Step 4: Start TTS server in background
echo ""
echo -e "${YELLOW}✨ Starting TTS server...${NC}"
echo -e "${YELLOW}   Log file: ${LOG_FILE}${NC}"
echo -e "${YELLOW}   Port: ${PORT}${NC}"
echo ""

nohup python scripts/server_production.py > ${LOG_FILE} 2>&1 &
SERVER_PID=$!
echo ${SERVER_PID} > ${PID_FILE}

echo -e "${GREEN}   ✓ Server started (PID: ${SERVER_PID})${NC}"

# Step 5: Wait for server initialization
echo ""
echo -e "${YELLOW}⏳ Waiting for server to initialize (model loading takes ~25 seconds)...${NC}"

for i in {1..30}; do
    sleep 1
    if grep -q "SERVER READY" ${LOG_FILE} 2>/dev/null; then
        echo -e "${GREEN}   ✓ Server is ready!${NC}"
        break
    fi
    if ! ps -p ${SERVER_PID} > /dev/null 2>&1; then
        echo -e "${RED}   ✗ Server process died during startup!${NC}"
        echo -e "${RED}   Last 20 lines of log:${NC}"
        tail -20 ${LOG_FILE}
        exit 1
    fi
    echo -ne "   ${i}/30 seconds...\r"
done

# Step 6: Verify server is listening
echo ""
echo -e "${YELLOW}🔍 Verifying server is listening on port ${PORT}...${NC}"
sleep 2
if lsof -Pi :${PORT} -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${GREEN}   ✓ Server is listening on port ${PORT}${NC}"
else
    echo -e "${RED}   ✗ Server is NOT listening on port ${PORT}${NC}"
    echo -e "${RED}   Check logs: tail -f ${LOG_FILE}${NC}"
    exit 1
fi

# Step 7: Test health endpoint
echo ""
echo -e "${YELLOW}🏥 Testing health endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s http://localhost:${PORT}/api/health || echo "FAILED")
if echo "${HEALTH_RESPONSE}" | grep -q "healthy"; then
    echo -e "${GREEN}   ✓ Health check passed${NC}"
else
    echo -e "${RED}   ✗ Health check failed${NC}"
    echo -e "${RED}   Response: ${HEALTH_RESPONSE}${NC}"
fi

# Step 8: Display success summary
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}✅ SERVER IS RUNNING${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""
echo -e "📋 Server Details:"
echo -e "   PID: ${SERVER_PID}"
echo -e "   Port: ${PORT}"
echo -e "   Logs: ${LOG_FILE}"
echo ""
echo -e "🌐 Endpoints:"
echo -e "   Internal: http://localhost:${PORT}"
echo -e "   External: https://dmbt2v5xek8fou-${PORT}.proxy.runpod.net"
echo ""
echo -e "📡 API Routes:"
echo -e "   POST /api/tts         - Generate TTS"
echo -e "   GET  /api/voices      - List voices"
echo -e "   GET  /api/health      - Health check"
echo -e "   GET  /docs            - API documentation"
echo ""
echo -e "📝 Useful Commands:"
echo -e "   View logs:     tail -f ${LOG_FILE}"
echo -e "   Stop server:   kill ${SERVER_PID}"
echo -e "   Server status: ps -p ${SERVER_PID}"
echo ""
echo -e "🧪 Test TTS Generation:"
echo -e "   curl -X POST http://localhost:${PORT}/api/tts \\"
echo -e "     -H 'Content-Type: application/json' \\"
echo -e "     -d '{\"text\":\"Hello from RunPod!\",\"voice\":\"emily-en-us\"}' \\"
echo -e "     --output test.wav"
echo ""
echo -e "${GREEN}=================================${NC}"
