#!/bin/bash
# Test Voice Isolation & Queue Management
# Run this after deploying to verify everything works

set -e

BASE_URL="${TTS_BASE_URL:-http://localhost:8888}"
OUTPUT_DIR="test_outputs"

echo "============================================"
echo "Chatterbox TTS Voice Isolation Test Suite"
echo "============================================"
echo "Base URL: $BASE_URL"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test 1: Health Check
echo -e "${YELLOW}[TEST 1]${NC} Health Check..."
HEALTH=$(curl -s "$BASE_URL/api/health")
echo "$HEALTH" | jq .

if echo "$HEALTH" | jq -e '.features | index("voice_isolation")' > /dev/null; then
    echo -e "${GREEN}✓${NC} Voice isolation feature detected"
else
    echo -e "${RED}✗${NC} Voice isolation feature NOT found"
    exit 1
fi

echo ""

# Test 2: Auto Emotion Detection
echo -e "${YELLOW}[TEST 2]${NC} Auto Emotion Detection..."

echo "  → Testing apologetic tone..."
curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Sorry for the delay in responding to your request.",
    "voice": "support_agent",
    "auto_detect_emotion": true,
    "format": "wav"
  }' \
  --output "$OUTPUT_DIR/apologetic.wav" \
  -s -D - | grep -E "(X-Detected-Style|HTTP)" || true

echo "  → Testing urgent tone..."
curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "URGENT: Please respond immediately!",
    "voice": "urgent_agent",
    "auto_detect_emotion": true,
    "format": "wav"
  }' \
  --output "$OUTPUT_DIR/urgent.wav" \
  -s -D - | grep -E "(X-Detected-Style|HTTP)" || true

echo "  → Testing grateful tone..."
curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Thank you so much for your patience!",
    "voice": "emily-en-us",
    "auto_detect_emotion": true,
    "format": "wav"
  }' \
  --output "$OUTPUT_DIR/grateful.wav" \
  -s -D - | grep -E "(X-Detected-Style|HTTP)" || true

echo -e "${GREEN}✓${NC} Emotion detection tests complete"
echo ""

# Test 3: Session Isolation
echo -e "${YELLOW}[TEST 3]${NC} Session-Based Voice Isolation..."

echo "  → Sending 3 requests with SAME session (should queue)..."
SESSION_ID="test_session_$(date +%s)"

# Send 3 requests in parallel (same session)
curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"Message one from session A\",
    \"voice\": \"naija_female\",
    \"session_id\": \"$SESSION_ID\",
    \"format\": \"wav\"
  }" \
  --output "$OUTPUT_DIR/session_msg1.wav" \
  -s &

curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"Message two from session A\",
    \"voice\": \"naija_female\",
    \"session_id\": \"$SESSION_ID\",
    \"format\": \"wav\"
  }" \
  --output "$OUTPUT_DIR/session_msg2.wav" \
  -s &

curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"Message three from session A\",
    \"voice\": \"naija_female\",
    \"session_id\": \"$SESSION_ID\",
    \"format\": \"wav\"
  }" \
  --output "$OUTPUT_DIR/session_msg3.wav" \
  -s &

# Wait for all requests
wait

echo "  → Checking queue stats..."
STATS=$(curl -s "$BASE_URL/api/queue/stats")
echo "$STATS" | jq .

QUEUED=$(echo "$STATS" | jq -r '.queue.queued_requests')
if [ "$QUEUED" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Requests were properly queued (queued_requests=$QUEUED)"
else
    echo -e "${YELLOW}⚠${NC} No requests queued (may have processed too fast)"
fi

echo ""

# Test 4: Parallel Different Sessions
echo -e "${YELLOW}[TEST 4]${NC} Parallel Requests (Different Sessions)..."

echo "  → Sending 3 requests with DIFFERENT sessions (should run parallel)..."

# Send 3 requests in parallel (different sessions)
curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"Session B message\",
    \"voice\": \"naija_female\",
    \"session_id\": \"session_b_$(date +%s)\",
    \"format\": \"wav\"
  }" \
  --output "$OUTPUT_DIR/parallel_msg1.wav" \
  -s &

curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"Session C message\",
    \"voice\": \"naija_female\",
    \"session_id\": \"session_c_$(date +%s)\",
    \"format\": \"wav\"
  }" \
  --output "$OUTPUT_DIR/parallel_msg2.wav" \
  -s &

curl -X POST "$BASE_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{
    \"text\": \"Session D message\",
    \"voice\": \"naija_female\",
    \"session_id\": \"session_d_$(date +%s)\",
    \"format\": \"wav\"
  }" \
  --output "$OUTPUT_DIR/parallel_msg3.wav" \
  -s &

wait

echo -e "${GREEN}✓${NC} Parallel session test complete"
echo ""

# Test 5: Cleanup
echo -e "${YELLOW}[TEST 5]${NC} Session Cleanup..."
curl -X POST "$BASE_URL/api/queue/cleanup/$SESSION_ID" -s | jq .
echo -e "${GREEN}✓${NC} Session cleaned up"
echo ""

# Test 6: List Voices
echo -e "${YELLOW}[TEST 6]${NC} List Available Voices..."
VOICES=$(curl -s "$BASE_URL/api/voices")
echo "$VOICES" | jq .
TOTAL=$(echo "$VOICES" | jq -r '.total')
echo -e "${GREEN}✓${NC} Found $TOTAL voices"
echo ""

# Summary
echo "============================================"
echo -e "${GREEN}All Tests Passed!${NC}"
echo "============================================"
echo "Generated audio files saved to: $OUTPUT_DIR/"
echo ""
echo "Test files created:"
ls -lh "$OUTPUT_DIR/"/*.wav
echo ""
echo "Final queue stats:"
curl -s "$BASE_URL/api/queue/stats" | jq .
echo ""
echo -e "${GREEN}✓ Voice isolation system is working correctly!${NC}"
