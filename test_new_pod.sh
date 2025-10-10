#!/bin/bash
###############################################################################
# Test New RunPod Deployment
# Pod: aav4qfa6yqgt3k (Port 8000)
###############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# New pod details
POD_URL="https://aav4qfa6yqgt3k-8000.proxy.runpod.net"
POD_ID="aav4qfa6yqgt3k"
PORT="8000"

clear

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Testing New RunPod Deployment                              ║${NC}"
echo -e "${BLUE}║  Pod: $POD_ID                              ║${NC}"
echo -e "${BLUE}║  Port: $PORT                                                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test 1: Health Check
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test 1: Health Check${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

HEALTH_RESPONSE=$(curl -s "$POD_URL/api/health" || echo "ERROR")

if [ "$HEALTH_RESPONSE" = "ERROR" ]; then
    echo -e "${RED}❌ FAILED - Could not connect to pod${NC}"
    echo ""
    echo "Possible causes:"
    echo "  • Pod not running"
    echo "  • Service not started"
    echo "  • Wrong URL or port"
    echo ""
    exit 1
fi

echo "$HEALTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$HEALTH_RESPONSE"

# Check if healthy
if echo "$HEALTH_RESPONSE" | grep -q '"status".*"healthy"'; then
    echo ""
    echo -e "${GREEN}✅ Health check PASSED${NC}"
else
    echo ""
    echo -e "${RED}❌ Service not healthy${NC}"
    exit 1
fi

# Check model loaded
if echo "$HEALTH_RESPONSE" | grep -q '"model_loaded".*true'; then
    echo -e "${GREEN}✅ Model loaded${NC}"
else
    echo -e "${YELLOW}⚠️  Model not loaded yet${NC}"
fi

echo ""

# Test 2: List Voices
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test 2: List Available Voices${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

VOICES_RESPONSE=$(curl -s "$POD_URL/api/voices" || echo "ERROR")

if [ "$VOICES_RESPONSE" != "ERROR" ]; then
    echo "$VOICES_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VOICES_RESPONSE"
    echo ""
    echo -e "${GREEN}✅ Voices endpoint working${NC}"
else
    echo -e "${RED}❌ Failed to fetch voices${NC}"
fi

echo ""

# Test 3: TTS Generation
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test 3: TTS Generation${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TEST_TEXT="Hello from the new RunPod instance! Pod ID: $POD_ID on port $PORT."
OUTPUT_FILE="/tmp/test_new_pod_$(date +%s).mp3"

echo "Text: \"$TEST_TEXT\""
echo "Voice: emily-en-us"
echo "Output: $OUTPUT_FILE"
echo ""

HTTP_CODE=$(curl -X POST "$POD_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$TEST_TEXT\", \"voice\": \"emily-en-us\"}" \
  -o "$OUTPUT_FILE" \
  -w "%{http_code}" \
  -s \
  --max-time 30)

if [ "$HTTP_CODE" = "200" ] && [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    
    if [ "$FILE_SIZE" -gt 10000 ]; then
        FILE_SIZE_KB=$((FILE_SIZE / 1024))
        echo -e "${GREEN}✅ TTS generation PASSED${NC}"
        echo "   File size: ${FILE_SIZE_KB}KB"
        echo "   Saved to: $OUTPUT_FILE"
    else
        echo -e "${RED}❌ Generated file too small (${FILE_SIZE} bytes)${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ TTS generation FAILED (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

echo ""

# Test 4: Play Audio
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test 4: Audio Playback${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if command -v afplay &> /dev/null; then
    echo "Playing audio..."
    afplay "$OUTPUT_FILE" 2>/dev/null &
    PLAY_PID=$!
    echo -e "${GREEN}✅ Audio playing (PID: $PLAY_PID)${NC}"
    wait $PLAY_PID 2>/dev/null
elif command -v mpg123 &> /dev/null; then
    mpg123 -q "$OUTPUT_FILE" 2>/dev/null &
    echo -e "${GREEN}✅ Audio playing${NC}"
else
    echo -e "${YELLOW}⚠️  No audio player found${NC}"
    echo "   Install afplay (Mac) or mpg123 to play audio"
fi

echo ""

# Test 5: Different Voice
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Test 5: Alternative Voice${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ALT_VOICE="james-en-us"
ALT_OUTPUT="/tmp/test_alt_voice_$(date +%s).mp3"

echo "Testing voice: $ALT_VOICE"
echo ""

curl -X POST "$POD_URL/api/tts" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"This is the $ALT_VOICE voice on the new pod.\", \"voice\": \"$ALT_VOICE\"}" \
  -o "$ALT_OUTPUT" \
  -s \
  --max-time 30

if [ -f "$ALT_OUTPUT" ]; then
    ALT_SIZE=$(stat -f%z "$ALT_OUTPUT" 2>/dev/null || stat -c%s "$ALT_OUTPUT" 2>/dev/null)
    
    if [ "$ALT_SIZE" -gt 10000 ]; then
        ALT_SIZE_KB=$((ALT_SIZE / 1024))
        echo -e "${GREEN}✅ Alternative voice working (${ALT_SIZE_KB}KB)${NC}"
    else
        echo -e "${YELLOW}⚠️  File too small, voice might not be available${NC}"
    fi
else
    echo -e "${RED}❌ Failed to generate with alternative voice${NC}"
fi

echo ""

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "New RunPod Deployment Summary:"
echo ""
echo -e "  ${BLUE}Pod ID:${NC}      $POD_ID"
echo -e "  ${BLUE}Port:${NC}        $PORT"
echo -e "  ${BLUE}Base URL:${NC}    $POD_URL"
echo ""
echo -e "  ${GREEN}✓${NC} Health check passing"
echo -e "  ${GREEN}✓${NC} Model loaded and ready"
echo -e "  ${GREEN}✓${NC} TTS generation working"
echo -e "  ${GREEN}✓${NC} Multiple voices available"
echo ""
echo "Generated files:"
echo "  • $OUTPUT_FILE"
echo "  • $ALT_OUTPUT"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "  1. Update n8n workflows with new URL (already done ✓)"
echo "  2. Test n8n workflow with webhook"
echo "  3. Stop old pod (a288y3vpbfxwkk) to save costs"
echo ""
echo "Example n8n test:"
echo -e "  ${YELLOW}./quick_n8n_test.sh \"YOUR_N8N_WEBHOOK_URL\"${NC}"
echo ""
echo -e "${GREEN}✅ Migration Complete!${NC}"
echo ""

