#!/bin/bash

##############################################################################
# Test Twilio Integration
##############################################################################
# This script tests your Twilio setup and TTS integration
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Twilio Integration Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Load environment variables
if [ -f ".env.twilio" ]; then
    source .env.twilio
    echo -e "${GREEN}✓ Loaded .env.twilio${NC}\n"
else
    echo -e "${RED}✗ .env.twilio not found${NC}"
    echo -e "${YELLOW}  Please create .env.twilio with your Twilio credentials${NC}\n"
    exit 1
fi

# Check required variables
echo -e "${BLUE}Checking configuration...${NC}"

if [ -z "$TWILIO_ACCOUNT_SID" ]; then
    echo -e "${RED}✗ TWILIO_ACCOUNT_SID not set${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Account SID: ${TWILIO_ACCOUNT_SID:0:10}...${NC}"

if [ -z "$TWILIO_AUTH_TOKEN" ]; then
    echo -e "${RED}✗ TWILIO_AUTH_TOKEN not set${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Auth Token: ${TWILIO_AUTH_TOKEN:0:8}...${NC}"

if [ -z "$TWILIO_PHONE_NUMBER" ]; then
    echo -e "${RED}✗ TWILIO_PHONE_NUMBER not set${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Phone Number: ${TWILIO_PHONE_NUMBER}${NC}\n"

##############################################################################
# Test 1: Twilio API Connection
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test 1: Twilio API Connection${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Test Twilio API
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
    "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}.json")

if [ "$HTTP_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Twilio API connection successful${NC}"
else
    echo -e "${RED}✗ Twilio API connection failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

# Get account details
echo -e "\n${YELLOW}Account Details:${NC}"
curl -s -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
    "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}.json" \
    | python3 -m json.tool | grep -E "(friendly_name|status|type)" || echo "  (Account verified)"

echo ""

##############################################################################
# Test 2: List Phone Numbers
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test 2: Your Twilio Phone Numbers${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

curl -s -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
    "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/IncomingPhoneNumbers.json" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for num in data.get('phone_numbers', []):
    print(f\"  📞 {num.get('phone_number')} - {num.get('friendly_name', 'N/A')}\")
    print(f\"     Voice URL: {num.get('voice_url', 'Not set')}\")
    print()
" || echo -e "${YELLOW}  No phone numbers found${NC}"

##############################################################################
# Test 3: TTS Service Connection
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test 3: TTS Service Connection${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ -n "$TTS_BASE_URL" ]; then
    echo -e "${YELLOW}Testing TTS at: ${TTS_BASE_URL}${NC}"
    
    TTS_HEALTH=$(curl -s "${TTS_BASE_URL}/health" || echo "failed")
    
    if echo "$TTS_HEALTH" | grep -q "healthy\|ok\|status"; then
        echo -e "${GREEN}✓ TTS service is accessible${NC}"
    else
        echo -e "${RED}✗ TTS service not accessible${NC}"
        echo -e "${YELLOW}  Make sure your RunPod TTS service is running${NC}"
    fi
else
    echo -e "${YELLOW}⚠ TTS_BASE_URL not set in .env.twilio${NC}"
fi

echo ""

##############################################################################
# Test 4: Send Test SMS (Optional)
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test 4: Send Test SMS (Optional)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Would you like to send a test SMS? (y/n)${NC}"
read -r SEND_SMS

if [ "$SEND_SMS" = "y" ]; then
    echo -e "${YELLOW}Enter destination phone number (e.g., +1234567890):${NC}"
    read -r TO_NUMBER
    
    if [ -n "$TO_NUMBER" ]; then
        echo -e "${BLUE}Sending test SMS...${NC}"
        
        RESPONSE=$(curl -s -X POST "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json" \
            -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
            --data-urlencode "From=${TWILIO_PHONE_NUMBER}" \
            --data-urlencode "To=${TO_NUMBER}" \
            --data-urlencode "Body=Test message from Chatterbox TTS Integration!")
        
        if echo "$RESPONSE" | grep -q "sid"; then
            MSG_SID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('sid', 'N/A'))")
            echo -e "${GREEN}✓ SMS sent successfully!${NC}"
            echo -e "  Message SID: ${MSG_SID}"
        else
            echo -e "${RED}✗ SMS failed${NC}"
            echo "$RESPONSE" | python3 -m json.tool
        fi
    fi
else
    echo -e "${YELLOW}Skipping SMS test${NC}"
fi

echo ""

##############################################################################
# Summary
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${GREEN}✓ Twilio Integration Tests Complete!${NC}\n"

echo -e "${YELLOW}Your Configuration:${NC}"
echo -e "  Account SID: ${TWILIO_ACCOUNT_SID}"
echo -e "  Phone Number: ${TWILIO_PHONE_NUMBER}"
echo -e "  TTS Service: ${TTS_BASE_URL}"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Deploy scripts/twilio_integration.py to a public server"
echo -e "  2. Configure Twilio webhook URLs in Twilio console"
echo -e "  3. Test incoming calls to ${TWILIO_PHONE_NUMBER}"
echo -e "  4. Integrate with n8n for advanced workflows"
echo ""

echo -e "${BLUE}Documentation:${NC}"
echo -e "  • Twilio Integration: See TWILIO_INTEGRATION.md"
echo -e "  • n8n Workflows: See n8n/README.md"
echo -e "  • API Reference: See API_REFERENCE.md"
echo ""

