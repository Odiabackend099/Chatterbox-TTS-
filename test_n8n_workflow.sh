#!/bin/bash

##############################################################################
# Test n8n TTS Workflow
##############################################################################
# Simulates what your n8n workflow does
##############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
TTS_URL="https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts"
OUTPUT_DIR="./outputs/n8n_tests"

# Get input
TEXT="${1:-Hello from n8n! This is a test of the TTS workflow integration with Chatterbox.}"
VOICE="${2:-emily-en-us}"

mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  n8n TTS Workflow Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Simulating n8n workflow...${NC}\n"

echo -e "${BLUE}Step 1: Webhook receives request${NC}"
echo -e "  Text: ${TEXT:0:60}..."
echo -e "  Voice: $VOICE\n"

echo -e "${BLUE}Step 2: Set node prepares parameters${NC}"
echo -e "  ✓ Text extracted"
echo -e "  ✓ Voice set to: $VOICE\n"

echo -e "${BLUE}Step 3: HTTP Request calls TTS API${NC}"
echo -e "  URL: $TTS_URL"
echo -e "  Method: POST"
echo -e "  Body: JSON\n"

echo -e "${YELLOW}Generating audio...${NC}"

curl -X POST "$TTS_URL" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"$TEXT\", \"voice\": \"$VOICE\"}" \
    --output "$OUTPUT_DIR/n8n_workflow_test.wav" \
    --silent --show-error

FILESIZE=$(wc -c < "$OUTPUT_DIR/n8n_workflow_test.wav")

if [ "$FILESIZE" -gt 1000 ]; then
    echo -e "${GREEN}✓ Audio generated: $FILESIZE bytes${NC}\n"
    
    echo -e "${BLUE}Step 4: Respond to Webhook${NC}"
    echo -e "  Content-Type: audio/x-wav"
    echo -e "  Size: $FILESIZE bytes\n"
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ n8n Workflow Test Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Auto-play
    echo -e "${BLUE}🔊 Playing audio...${NC}\n"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        afplay "$OUTPUT_DIR/n8n_workflow_test.wav"
    elif command -v ffplay &> /dev/null; then
        ffplay -nodisp -autoexit -loglevel quiet "$OUTPUT_DIR/n8n_workflow_test.wav"
    elif command -v play &> /dev/null; then
        play -q "$OUTPUT_DIR/n8n_workflow_test.wav"
    else
        echo -e "${YELLOW}To play: open $OUTPUT_DIR/n8n_workflow_test.wav${NC}"
    fi
    
    echo -e "\n${GREEN}✓ File saved: $OUTPUT_DIR/n8n_workflow_test.wav${NC}\n"
    
else
    echo -e "${RED}✗ Error: File too small ($FILESIZE bytes)${NC}"
    exit 1
fi

