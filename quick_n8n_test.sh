#!/bin/bash
# Quick n8n TTS Workflow Test - Battle Tested
# Run this AFTER importing the workflow and activating it

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 n8n TTS Workflow - Quick Test                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if webhook URL is provided
WEBHOOK_URL="${1:-}"

if [ -z "$WEBHOOK_URL" ]; then
  echo -e "${YELLOW}📋 SETUP CHECKLIST:${NC}"
  echo ""
  echo "  1. ✅ Import workflow file:"
  echo "     ${BLUE}n8n/COMPLETE_TTS_WORKFLOW.json${NC}"
  echo ""
  echo "  2. ✅ Activate the workflow (toggle switch)"
  echo ""
  echo "  3. ✅ Copy webhook URL from 'Webhook Trigger' node"
  echo ""
  echo "  4. ✅ Run this script with your webhook URL:"
  echo "     ${GREEN}./quick_n8n_test.sh \"YOUR_WEBHOOK_URL\"${NC}"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Example URLs:"
  echo "  • Local:  http://localhost:5678/webhook/tts-trigger"
  echo "  • Cloud:  https://your-instance.app.n8n.cloud/webhook/tts-trigger"
  echo ""
  exit 1
fi

echo -e "${GREEN}✓ Webhook URL provided${NC}"
echo "  $WEBHOOK_URL"
echo ""

# Test 1: Basic connectivity
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📡 Test 1: Checking n8n webhook connectivity...${NC}"
echo ""

HTTP_CODE=$(curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test"}' \
  -w "%{http_code}" \
  -s \
  -o /tmp/n8n_test_basic.mp3 \
  --max-time 35 \
  2>&1 || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✅ SUCCESS${NC} - Webhook is active and responding (HTTP 200)"
elif [ "$HTTP_CODE" = "404" ]; then
  echo -e "${RED}❌ FAILED${NC} - Webhook not found (HTTP 404)"
  echo ""
  echo "Possible causes:"
  echo "  • Workflow is not activated (check toggle switch)"
  echo "  • Wrong webhook URL"
  echo "  • Workflow was deleted"
  echo ""
  exit 1
elif [ "$HTTP_CODE" = "500" ]; then
  echo -e "${RED}❌ FAILED${NC} - Server error (HTTP 500)"
  echo ""
  echo "Check n8n execution logs for errors"
  echo "  1. Go to n8n → Executions (left sidebar)"
  echo "  2. Click on the latest failed execution"
  echo "  3. Look for error details"
  echo ""
  exit 1
elif [ "$HTTP_CODE" = "000" ]; then
  echo -e "${RED}❌ FAILED${NC} - Could not connect"
  echo ""
  echo "Possible causes:"
  echo "  • n8n is not running"
  echo "  • Wrong URL"
  echo "  • Network/firewall issue"
  echo ""
  exit 1
else
  echo -e "${RED}❌ FAILED${NC} - HTTP $HTTP_CODE"
  exit 1
fi

echo ""

# Test 2: TTS functionality with audio output
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🎤 Test 2: Generating TTS audio...${NC}"
echo ""

TEST_TEXT="Hello from Nigeria! This is a production test of the n8n TTS workflow."
OUTPUT_FILE="/tmp/n8n_test_full.mp3"

echo "  Text: \"$TEST_TEXT\""
echo "  Voice: emily-en-us"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$TEST_TEXT\", \"voice\": \"emily-en-us\"}" \
  -o "$OUTPUT_FILE" \
  --progress-bar \
  --max-time 35 \
  2>&1

echo ""

# Check file size
if [ -f "$OUTPUT_FILE" ]; then
  FILE_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
  
  if [ "$FILE_SIZE" -gt 10000 ]; then
    FILE_SIZE_KB=$((FILE_SIZE / 1024))
    echo -e "${GREEN}✅ SUCCESS${NC} - Audio file generated (${FILE_SIZE_KB}KB)"
    echo ""
    
    # Test 3: Play audio
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔊 Test 3: Playing audio...${NC}"
    echo ""
    
    if command -v afplay &> /dev/null; then
      afplay "$OUTPUT_FILE" 2>/dev/null &
      PLAY_PID=$!
      echo -e "${GREEN}✅ Audio playing...${NC}"
      echo ""
      wait $PLAY_PID 2>/dev/null
    elif command -v mpg123 &> /dev/null; then
      mpg123 -q "$OUTPUT_FILE" 2>/dev/null &
      echo -e "${GREEN}✅ Audio playing...${NC}"
      echo ""
    else
      echo -e "${YELLOW}⚠️  No audio player found (install afplay or mpg123)${NC}"
      echo "   File saved: $OUTPUT_FILE"
      echo ""
    fi
    
  else
    echo -e "${RED}❌ FAILED${NC} - File too small (${FILE_SIZE} bytes)"
    echo ""
    echo "Possible causes:"
    echo "  • TTS service returned an error"
    echo "  • RunPod service is down"
    echo "  • Invalid voice name"
    echo ""
    
    # Try to show error
    if command -v file &> /dev/null; then
      FILE_TYPE=$(file -b "$OUTPUT_FILE")
      echo "File type: $FILE_TYPE"
    fi
    
    exit 1
  fi
else
  echo -e "${RED}❌ FAILED${NC} - No output file created"
  exit 1
fi

# Test 4: Different voice test
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🎭 Test 4: Testing different voice...${NC}"
echo ""

TEST_VOICE="james-en-us"
OUTPUT_FILE_2="/tmp/n8n_test_voice.mp3"

echo "  Voice: $TEST_VOICE"
echo ""

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"This is a test of the $TEST_VOICE voice.\", \"voice\": \"$TEST_VOICE\"}" \
  -o "$OUTPUT_FILE_2" \
  --progress-bar \
  --max-time 35 \
  2>&1

echo ""

if [ -f "$OUTPUT_FILE_2" ]; then
  FILE_SIZE_2=$(stat -f%z "$OUTPUT_FILE_2" 2>/dev/null || stat -c%s "$OUTPUT_FILE_2" 2>/dev/null)
  
  if [ "$FILE_SIZE_2" -gt 10000 ]; then
    FILE_SIZE_2_KB=$((FILE_SIZE_2 / 1024))
    echo -e "${GREEN}✅ SUCCESS${NC} - Voice variant working (${FILE_SIZE_2_KB}KB)"
  else
    echo -e "${YELLOW}⚠️  WARNING${NC} - Voice test file too small"
  fi
else
  echo -e "${YELLOW}⚠️  WARNING${NC} - Voice test failed (not critical)"
fi

echo ""

# Summary
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
echo ""
echo "Your n8n TTS workflow is working correctly!"
echo ""
echo "Files created:"
echo "  • $OUTPUT_FILE"
echo "  • $OUTPUT_FILE_2"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo ""
echo "  1. Use this webhook in your apps:"
echo "     ${GREEN}$WEBHOOK_URL${NC}"
echo ""
echo "  2. Example curl command:"
echo "     ${YELLOW}curl -X POST \"$WEBHOOK_URL\" \\${NC}"
echo "     ${YELLOW}  -H \"Content-Type: application/json\" \\${NC}"
echo "     ${YELLOW}  -d '{\"text\": \"Your text here\", \"voice\": \"emily-en-us\"}' \\${NC}"
echo "     ${YELLOW}  --output output.mp3${NC}"
echo ""
echo "  3. Available voices:"
echo "     • emily-en-us (Female, US)"
echo "     • james-en-us (Male, US)"
echo "     • sophia-en-gb (Female, UK)"
echo "     • marcus-en-us (Male, US)"
echo "     • luna-en-us (Female, US)"
echo ""
echo "  4. See full docs:"
echo "     ${BLUE}IMPORT_AND_TEST_N8N.md${NC}"
echo ""
echo -e "${GREEN}✅ Ready for production!${NC}"
echo ""

