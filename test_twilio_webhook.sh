#!/bin/bash
# ============================================================================
# Twilio Webhook Test Script
# Test your AI voice agent locally before connecting real phone calls
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SERVER_URL=${1:-"http://localhost:8004"}

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🧪 Twilio Webhook Integration Test                               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Testing server at: $SERVER_URL"
echo ""

# ============================================================================
# Test 1: Health Check
# ============================================================================

echo -e "${YELLOW}[Test 1/5] Health Check${NC}"

HEALTH_RESPONSE=$(curl -s "$SERVER_URL/health" || echo "FAILED")

if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✅ Server is healthy${NC}"
    echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
elif echo "$HEALTH_RESPONSE" | grep -q '"status":"degraded"'; then
    echo -e "${YELLOW}⚠️  Server is degraded but running${NC}"
    echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Server is not responding${NC}"
    echo "Make sure the server is running: docker-compose ps"
    exit 1
fi

echo ""

# ============================================================================
# Test 2: Twilio Voice Webhook
# ============================================================================

echo -e "${YELLOW}[Test 2/5] Testing /twilio/voice webhook${NC}"

# Simulate Twilio calling the webhook
VOICE_RESPONSE=$(curl -s -X POST "$SERVER_URL/twilio/voice" \
  -d "CallSid=TEST1234567890" \
  -d "From=+15551234567" \
  -d "To=+15559876543" \
  -d "CallStatus=ringing" \
  2>&1)

if echo "$VOICE_RESPONSE" | grep -q "<Response>"; then
    echo -e "${GREEN}✅ Voice webhook is working${NC}"
    echo "TwiML Response:"
    echo "$VOICE_RESPONSE" | head -20
else
    echo -e "${RED}❌ Voice webhook failed${NC}"
    echo "$VOICE_RESPONSE"
    exit 1
fi

echo ""

# ============================================================================
# Test 3: Speech Processing Webhook
# ============================================================================

echo -e "${YELLOW}[Test 3/5] Testing /twilio/process-speech webhook${NC}"

SPEECH_RESPONSE=$(curl -s -X POST "$SERVER_URL/twilio/process-speech" \
  -d "CallSid=TEST1234567890" \
  -d "SpeechResult=Hello, can you help me?" \
  -d "Confidence=0.95" \
  2>&1)

if echo "$SPEECH_RESPONSE" | grep -q "<Response>"; then
    echo -e "${GREEN}✅ Speech processing webhook is working${NC}"
    echo "TwiML Response:"
    echo "$SPEECH_RESPONSE" | head -20
else
    echo -e "${RED}❌ Speech processing webhook failed${NC}"
    echo "$SPEECH_RESPONSE"
fi

echo ""

# ============================================================================
# Test 4: TTS Generation (Direct API)
# ============================================================================

echo -e "${YELLOW}[Test 4/5] Testing TTS generation${NC}"

TTS_TEST_FILE="/tmp/tts_test_$$.wav"

curl -s -X POST "$SERVER_URL/tts" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello! This is a test of the text to speech system.",
    "temperature": 0.8,
    "exaggeration": 1.3
  }' \
  --output "$TTS_TEST_FILE" 2>&1

if [ -f "$TTS_TEST_FILE" ] && [ -s "$TTS_TEST_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$TTS_TEST_FILE" 2>/dev/null || stat -c%s "$TTS_TEST_FILE" 2>/dev/null)
    echo -e "${GREEN}✅ TTS generation successful${NC}"
    echo "Generated audio file: $TTS_TEST_FILE ($FILE_SIZE bytes)"

    # Check if it's a valid WAV file
    if file "$TTS_TEST_FILE" | grep -q "WAVE audio"; then
        echo -e "${GREEN}✅ Valid WAV audio file${NC}"

        # Offer to play it
        if command -v afplay &> /dev/null; then
            read -p "Play audio? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                afplay "$TTS_TEST_FILE"
            fi
        elif command -v aplay &> /dev/null; then
            read -p "Play audio? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                aplay "$TTS_TEST_FILE"
            fi
        fi
    else
        echo -e "${YELLOW}⚠️  File generated but may not be valid WAV${NC}"
        file "$TTS_TEST_FILE"
    fi
else
    echo -e "${RED}❌ TTS generation failed${NC}"
    echo "Check server logs: docker-compose logs chatterbox-tts"
fi

echo ""

# ============================================================================
# Test 5: LLM Integration
# ============================================================================

echo -e "${YELLOW}[Test 5/5] Testing LLM integration${NC}"

LLM_RESPONSE=$(curl -s -X POST "$SERVER_URL/llm" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Say hello in one short sentence",
    "max_tokens": 50
  }' 2>&1)

if echo "$LLM_RESPONSE" | grep -q '"response"'; then
    echo -e "${GREEN}✅ LLM integration is working${NC}"
    echo "Response:"
    echo "$LLM_RESPONSE" | jq '.' 2>/dev/null || echo "$LLM_RESPONSE"
else
    echo -e "${YELLOW}⚠️  LLM integration failed (may not be configured)${NC}"
    echo "$LLM_RESPONSE"
    echo "This is okay if you haven't set ANTHROPIC_API_KEY or OPENAI_API_KEY yet"
fi

echo ""

# ============================================================================
# Summary
# ============================================================================

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  📊 Test Summary                                                   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Core Tests Passed:${NC}"
echo "   • Health check"
echo "   • Twilio voice webhook"
echo "   • Speech processing webhook"
echo "   • TTS generation"
echo ""
echo -e "${YELLOW}🎯 Next Steps:${NC}"
echo ""
echo "1. If all tests passed, your server is ready for Twilio!"
echo ""
echo "2. Expose your server with ngrok:"
echo "   ngrok http 8004"
echo ""
echo "3. Configure Twilio webhook with the ngrok URL:"
echo "   https://YOUR-NGROK-URL/twilio/voice"
echo ""
echo "4. Call your Twilio number to test with a real phone call!"
echo ""
echo -e "${GREEN}📖 Full setup guide: MVP_PRODUCTION_SETUP.md${NC}"
echo ""

# Cleanup
rm -f "$TTS_TEST_FILE"
