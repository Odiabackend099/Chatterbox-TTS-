#!/bin/bash
# Quick TTS API Test Script

set -e

API_KEY="cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU"
BASE_URL="http://localhost:8004"

echo "==================================================================="
echo "CallWaiting TTS API - Quick Test"
echo "==================================================================="
echo ""

# Check if server is running
echo "1. Checking server health..."
if curl -s -f "${BASE_URL}/health" > /dev/null 2>&1; then
    echo "✓ Server is running"
    curl -s "${BASE_URL}/health" | python3 -m json.tool || curl -s "${BASE_URL}/health"
    echo ""
else
    echo "✗ Server is NOT running on port 8004"
    echo ""
    echo "To start the server, run:"
    echo "  docker-compose up -d"
    echo ""
    echo "Or without Docker:"
    echo "  python3 scripts/server.py"
    echo ""
    exit 1
fi

# Get voices
echo "2. Fetching available voices..."
VOICES_JSON=$(curl -s "${BASE_URL}/v1/voices" -H "x-api-key: ${API_KEY}")

if echo "$VOICES_JSON" | grep -q "detail"; then
    echo "✗ Authentication failed or voices not available"
    echo "$VOICES_JSON"
    echo ""
    echo "Make sure:"
    echo "  1. Database is running (docker-compose up -d postgres redis)"
    echo "  2. API keys are inserted into database"
    echo ""
    exit 1
fi

echo "$VOICES_JSON" | python3 -m json.tool || echo "$VOICES_JSON"
echo ""

# Extract first voice ID
VOICE_ID=$(echo "$VOICES_JSON" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data[0]['id'] if data else 'NOT_FOUND')" 2>/dev/null || echo "NOT_FOUND")

if [ "$VOICE_ID" = "NOT_FOUND" ]; then
    echo "✗ No voices found in catalog"
    echo ""
    echo "To add voices, run:"
    echo "  docker exec -it chatterbox-postgres psql -U postgres -d chatterbox"
    echo "  Then check: SELECT * FROM voices;"
    echo ""
    exit 1
fi

echo "Using voice ID: $VOICE_ID"
echo ""

# Generate TTS
echo "3. Generating TTS audio..."
HTTP_CODE=$(curl -s -w "%{http_code}" -o test_audio.wav \
    -X POST "${BASE_URL}/v1/tts" \
    -H "x-api-key: ${API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
        \"text\": \"Hello, this is a test of the Chatterbox TTS system!\",
        \"voice_id\": \"${VOICE_ID}\",
        \"format\": \"wav\",
        \"speed\": 1.0
    }")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Audio generated successfully!"
    echo "  File: test_audio.wav"
    echo "  Size: $(ls -lh test_audio.wav | awk '{print $5}')"
    echo ""
    echo "To play:"
    echo "  open test_audio.wav    # macOS"
    echo "  aplay test_audio.wav   # Linux"
    echo ""
else
    echo "✗ Generation failed (HTTP $HTTP_CODE)"
    cat test_audio.wav
    echo ""
fi

# Get usage stats
echo "4. Checking usage statistics..."
curl -s "${BASE_URL}/v1/usage" -H "x-api-key: ${API_KEY}" | python3 -m json.tool || echo "No usage data yet"
echo ""

echo "==================================================================="
echo "Test complete!"
echo "==================================================================="

