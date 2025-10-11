#!/bin/bash
# Voice Quality Comparison Test
# Compare old emily-en-us parameters vs new maya-professional parameters

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Maya Voice Quality Comparison Test${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Configuration
BASE_URL="https://aav4qfa6yqgt3k-8888.proxy.runpod.net"
TEST_TEXT="Hello, I am here to help you today. How can I assist?"

echo "Test Text: \"$TEST_TEXT\""
echo ""

# Test 1: OLD parameters (emily-en-us)
echo -e "${YELLOW}[1/2] Generating with OLD parameters (emily-en-us)...${NC}"
echo "  Parameters: temp=0.8, exag=1.3, speed=1.0"
curl -X POST "${BASE_URL}/api/tts" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$TEST_TEXT\", \"voice\": \"emily-en-us\"}" \
  --max-time 180 \
  --output ~/Desktop/old_voice.wav \
  --silent --show-error

if [ -f ~/Desktop/old_voice.wav ] && [ -s ~/Desktop/old_voice.wav ]; then
    SIZE=$(ls -lh ~/Desktop/old_voice.wav | awk '{print $5}')
    echo -e "${GREEN}✓ OLD voice generated: ${SIZE}${NC}"
    echo "  Saved to: ~/Desktop/old_voice.wav"
else
    echo -e "${RED}✗ OLD voice generation failed${NC}"
    exit 1
fi
echo ""

# Test 2: NEW parameters (maya-professional)
echo -e "${YELLOW}[2/2] Generating with NEW parameters (maya-professional)...${NC}"
echo "  Parameters: temp=0.6, exag=0.85, speed=0.88"
curl -X POST "${BASE_URL}/api/tts" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$TEST_TEXT\", \"voice\": \"maya-professional\"}" \
  --max-time 180 \
  --output ~/Desktop/maya_voice.wav \
  --silent --show-error

if [ -f ~/Desktop/maya_voice.wav ] && [ -s ~/Desktop/maya_voice.wav ]; then
    SIZE=$(ls -lh ~/Desktop/maya_voice.wav | awk '{print $5}')
    echo -e "${GREEN}✓ NEW voice generated: ${SIZE}${NC}"
    echo "  Saved to: ~/Desktop/maya_voice.wav"
else
    echo -e "${RED}✗ NEW voice generation failed${NC}"
    exit 1
fi
echo ""

# Summary
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ COMPARISON TEST COMPLETE!${NC}\n"
echo -e "${BLUE}Listen and compare:${NC}"
echo ""
echo -e "  ${YELLOW}# Old voice (emily-en-us)${NC}"
echo -e "  afplay ~/Desktop/old_voice.wav"
echo ""
echo -e "  ${YELLOW}# New voice (maya-professional)${NC}"
echo -e "  afplay ~/Desktop/maya_voice.wav"
echo ""
echo -e "${BLUE}Expected differences:${NC}"
echo "  - Maya should sound warmer and more natural"
echo "  - Maya should speak ~12% slower (clearer)"
echo "  - Maya should have consistent tone (less variation)"
echo "  - Maya should sound professional, not theatrical"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

