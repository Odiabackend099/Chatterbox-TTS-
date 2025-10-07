#!/bin/bash
# Deploy to RunPod via API (if you have API key)

POD_ID="98d23be3611b"
RUNPOD_API_KEY="${RUNPOD_API_KEY:-your_api_key_here}"

echo "Deploying to RunPod pod: $POD_ID"

# Execute commands via RunPod API
curl -X POST "https://api.runpod.io/v2/${POD_ID}/exec" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "command": "cd /workspace/chatterbox-tts && git pull origin main && nohup python3 scripts/server.py > server.log 2>&1 &"
  }'

echo ""
echo "Checking deployment status..."
sleep 5

# Check if server is running
curl -s https://98d23be3611b-8004.proxy.runpod.net/health || echo "Server not responding yet"


