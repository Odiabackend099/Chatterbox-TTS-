#!/bin/bash
# Test n8n Webhook Trigger - Battle Tested
# Usage: ./test_n8n_webhook_trigger.sh "YOUR_N8N_WEBHOOK_URL"

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get webhook URL from argument or ask for it
WEBHOOK_URL="${1:-}"

if [ -z "$WEBHOOK_URL" ]; then
  echo -e "${YELLOW}⚠️  No webhook URL provided${NC}"
  echo ""
  echo "Usage:"
  echo "  ./test_n8n_webhook_trigger.sh 'https://your-n8n.com/webhook/tts-trigger'"
  echo ""
  echo "To get your webhook URL:"
  echo "  1. Open your n8n workflow"
  echo "  2. Click on the Webhook node"
  echo "  3. Copy the Production URL"
  echo ""
  exit 1
fi

echo -e "${GREEN}🧪 Testing n8n Webhook Trigger${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 Webhook URL: $WEBHOOK_URL"
echo ""

# Test 1: Simple health check with minimal payload
echo -e "${YELLOW}📤 Test 1: Minimal Payload${NC}"
echo "Payload: {\"text\": \"Test\"}"
echo ""

RESPONSE=$(curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test"}' \
  -w "\nHTTP_CODE:%{http_code}" \
  -s \
  --max-time 10 \
  2>&1 || echo "CURL_ERROR")

# Extract HTTP status code
HTTP_CODE=$(echo "$RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✅ Test 1 PASSED${NC} - HTTP 200 received"
elif [ "$HTTP_CODE" = "404" ]; then
  echo -e "${RED}❌ Test 1 FAILED${NC} - HTTP 404"
  echo "   Webhook not found. Is the workflow activated?"
  exit 1
elif [ "$HTTP_CODE" = "500" ]; then
  echo -e "${RED}❌ Test 1 FAILED${NC} - HTTP 500"
  echo "   Server error. Check n8n workflow execution logs."
  exit 1
else
  echo -e "${RED}❌ Test 1 FAILED${NC} - HTTP $HTTP_CODE (or connection failed)"
  echo "   Check if n8n is running and URL is correct."
  exit 1
fi

echo ""

# Test 2: Full payload with voice parameter
echo -e "${YELLOW}📤 Test 2: Full Payload with Voice${NC}"
echo "Payload: {\"text\": \"Hello from Nigeria!\", \"voice\": \"emily-en-us\"}"
echo ""

RESPONSE2=$(curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria!", "voice": "emily-en-us"}' \
  -w "\nHTTP_CODE:%{http_code}" \
  -s \
  --max-time 10 \
  2>&1 || echo "CURL_ERROR")

HTTP_CODE2=$(echo "$RESPONSE2" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$HTTP_CODE2" = "200" ]; then
  echo -e "${GREEN}✅ Test 2 PASSED${NC} - HTTP 200 received"
else
  echo -e "${RED}❌ Test 2 FAILED${NC} - HTTP $HTTP_CODE2"
  exit 1
fi

echo ""

# Test 3: Nested body structure (webhook might pass body.text)
echo -e "${YELLOW}📤 Test 3: Nested Body Structure${NC}"
echo "Payload: {\"body\": {\"text\": \"Testing nested payload\", \"voice\": \"emily-en-us\"}}"
echo ""

RESPONSE3=$(curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"body": {"text": "Testing nested payload", "voice": "emily-en-us"}}' \
  -w "\nHTTP_CODE:%{http_code}" \
  -s \
  --max-time 10 \
  2>&1 || echo "CURL_ERROR")

HTTP_CODE3=$(echo "$RESPONSE3" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$HTTP_CODE3" = "200" ]; then
  echo -e "${GREEN}✅ Test 3 PASSED${NC} - HTTP 200 received"
else
  echo -e "${YELLOW}⚠️  Test 3 WARNING${NC} - HTTP $HTTP_CODE3 (nested structure may not be needed)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Webhook Trigger Tests Complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Check n8n workflow execution history"
echo "  2. Verify webhook received the payload"
echo "  3. Connect remaining nodes (Set → HTTP Request → Respond)"
echo ""

