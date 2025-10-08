#!/bin/bash

##############################################################################
# Quick TTS Test with Auto-Play
##############################################################################
# Quickly test TTS with a short message and auto-play the result
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
TTS_URL="https://a288y3vpbfxwkk-8004.proxy.runpod.net/synthesize"
API_KEY="cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU"
OUTPUT_DIR="./outputs/audio_samples"

# Get text from argument or use default
TEXT="${1:-Hello from Nigeria! This is a test of the Chatterbox text-to-speech service.}"
VOICE="${2:-naija_female}"
OUTPUT_FILE="${3:-quick_test.mp3}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Quick TTS Test with Auto-Play${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Text:${NC} $TEXT"
echo -e "${YELLOW}Voice:${NC} $VOICE"
echo -e "${YELLOW}Output:${NC} $OUTPUT_FILE\n"

echo -e "${BLUE}Generating audio...${NC}"

curl -X POST "$TTS_URL" \
    -H "Authorization: Bearer $API_KEY" \
    -F "text=$TEXT" \
    -F "voice_id=$VOICE" \
    --output "$OUTPUT_DIR/$OUTPUT_FILE" \
    --silent --show-error

FILESIZE=$(wc -c < "$OUTPUT_DIR/$OUTPUT_FILE")

if [ "$FILESIZE" -gt 1000 ]; then
    echo -e "${GREEN}✓ Audio generated successfully!${NC} ($FILESIZE bytes)\n"
    
    # Auto-play
    echo -e "${BLUE}🔊 Playing audio now...${NC}\n"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - afplay is built-in and plays synchronously
        afplay "$OUTPUT_DIR/$OUTPUT_FILE"
    elif command -v mpg123 &> /dev/null; then
        # Linux with mpg123
        mpg123 -q "$OUTPUT_DIR/$OUTPUT_FILE"
    elif command -v ffplay &> /dev/null; then
        # Linux with ffplay
        ffplay -nodisp -autoexit -loglevel quiet "$OUTPUT_DIR/$OUTPUT_FILE"
    elif command -v play &> /dev/null; then
        # Linux with sox
        play -q "$OUTPUT_DIR/$OUTPUT_FILE"
    else
        echo -e "${YELLOW}⚠ No audio player found. File saved but cannot auto-play.${NC}"
        echo -e "${YELLOW}Install one of: afplay (macOS), mpg123, ffplay, or sox${NC}\n"
        echo -e "To play manually:"
        echo -e "  open $OUTPUT_DIR/$OUTPUT_FILE"
    fi
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Test complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
else
    echo -e "${RED}✗ Error: Audio file is too small ($FILESIZE bytes)${NC}"
    echo -e "${RED}  Check if your RunPod TTS service is running${NC}\n"
    exit 1
fi

