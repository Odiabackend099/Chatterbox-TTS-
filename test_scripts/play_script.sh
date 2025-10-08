#!/bin/bash

##############################################################################
# Play Script - Generate and Auto-Play from Text File
##############################################################################
# Usage:
#   ./test_scripts/play_script.sh                    # Uses one_minute_script.txt
#   ./test_scripts/play_script.sh custom_script.txt  # Uses custom file
#   ./test_scripts/play_script.sh - "Your text here" # Direct text input
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
TTS_URL="https://bh1ki2a4eg8ufz-8004.proxy.runpod.net/synthesize"
API_KEY="cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU"
OUTPUT_DIR="./outputs/audio_samples"
DEFAULT_SCRIPT="test_scripts/one_minute_script.txt"

# Parse arguments
if [ "$1" == "-" ]; then
    # Direct text input
    TEXT="$2"
    SOURCE="direct input"
elif [ -n "$1" ] && [ -f "$1" ]; then
    # Custom script file
    TEXT=$(cat "$1")
    SOURCE="$1"
elif [ -f "$DEFAULT_SCRIPT" ]; then
    # Default script
    TEXT=$(cat "$DEFAULT_SCRIPT")
    SOURCE="$DEFAULT_SCRIPT"
else
    echo -e "${RED}Error: No script file found${NC}"
    echo -e "Usage:"
    echo -e "  $0                           # Use default one_minute_script.txt"
    echo -e "  $0 path/to/script.txt        # Use custom script file"
    echo -e "  $0 - \"Your text here\"        # Use direct text input"
    exit 1
fi

VOICE="${VOICE:-naija_female}"
OUTPUT_FILE="script_output_$(date +%s).mp3"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  🎙️  TTS Script Player${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Source:${NC} $SOURCE"
echo -e "${YELLOW}Voice:${NC} $VOICE"
echo -e "${YELLOW}Text length:${NC} ${#TEXT} characters (~$(echo "$TEXT" | wc -w | tr -d ' ') words)\n"

# Show preview of text
echo -e "${BLUE}Text preview:${NC}"
echo "$TEXT" | head -c 200
if [ ${#TEXT} -gt 200 ]; then
    echo "..."
fi
echo -e "\n"

echo -e "${BLUE}Generating audio...${NC}"

curl -X POST "$TTS_URL" \
    -H "Authorization: Bearer $API_KEY" \
    -F "text=$TEXT" \
    -F "voice_id=$VOICE" \
    --output "$OUTPUT_DIR/$OUTPUT_FILE" \
    --silent --show-error

FILESIZE=$(wc -c < "$OUTPUT_DIR/$OUTPUT_FILE")

if [ "$FILESIZE" -gt 1000 ]; then
    echo -e "${GREEN}✓ Generated:${NC} $OUTPUT_FILE ($FILESIZE bytes)\n"
    
    # Auto-play
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  🔊 Now Playing...${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        afplay "$OUTPUT_DIR/$OUTPUT_FILE"
    elif command -v mpg123 &> /dev/null; then
        mpg123 -q "$OUTPUT_DIR/$OUTPUT_FILE"
    elif command -v ffplay &> /dev/null; then
        ffplay -nodisp -autoexit -loglevel quiet "$OUTPUT_DIR/$OUTPUT_FILE"
    elif command -v play &> /dev/null; then
        play -q "$OUTPUT_DIR/$OUTPUT_FILE"
    else
        echo -e "${YELLOW}⚠ No audio player found${NC}\n"
        echo -e "To play manually:"
        echo -e "  open $OUTPUT_DIR/$OUTPUT_FILE"
    fi
    
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Playback complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\nFile saved: ${BLUE}$OUTPUT_DIR/$OUTPUT_FILE${NC}\n"
    
else
    echo -e "${RED}✗ Error: Audio file is too small ($FILESIZE bytes)${NC}"
    echo -e "${RED}  Check if your RunPod TTS service is running:${NC}"
    echo -e "  curl $TTS_URL/../health"
    exit 1
fi

