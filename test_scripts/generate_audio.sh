#!/bin/bash

##############################################################################
# Generate Audio from Script
##############################################################################
# This script generates audio files from text scripts using your TTS service
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
TTS_URL="https://a288y3vpbfxwkk-8888.proxy.runpod.net/api/tts"
API_KEY="cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU"
OUTPUT_DIR="./outputs/audio_samples"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Chatterbox TTS - Audio Generator${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Function to generate audio
generate_audio() {
    local text="$1"
    local voice="$2"
    local output_file="$3"
    
    echo -e "${YELLOW}Generating:${NC} $output_file"
    echo -e "${YELLOW}Voice:${NC} $voice"
    echo -e "${YELLOW}Text length:${NC} ${#text} characters\n"
    
    curl -X POST "$TTS_URL" \
        -H "Authorization: Bearer $API_KEY" \
        -F "text=$text" \
        -F "voice_id=$voice" \
        --output "$OUTPUT_DIR/$output_file" \
        --silent --show-error
    
    local filesize=$(wc -c < "$OUTPUT_DIR/$output_file")
    echo -e "${GREEN}✓ Created:${NC} $output_file ($filesize bytes)"
    
    # Auto-play the audio
    echo -e "${BLUE}🔊 Playing audio...${NC}\n"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        afplay "$OUTPUT_DIR/$output_file"
    elif command -v mpg123 &> /dev/null; then
        # Linux with mpg123
        mpg123 -q "$OUTPUT_DIR/$output_file"
    elif command -v ffplay &> /dev/null; then
        # Linux with ffplay (from ffmpeg)
        ffplay -nodisp -autoexit -loglevel quiet "$OUTPUT_DIR/$output_file"
    else
        echo -e "${YELLOW}⚠ No audio player found. Skipping playback.${NC}\n"
    fi
    
    echo ""
}

##############################################################################
# Script 1: One-Minute Welcome (Female Voice)
##############################################################################

SCRIPT_1=$(cat test_scripts/one_minute_script.txt)

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Script 1: One-Minute Welcome (Female)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

generate_audio "$SCRIPT_1" "naija_female" "welcome_female_1min.mp3"

##############################################################################
# Script 2: Same Script with Male Voice
##############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Script 2: One-Minute Welcome (Male)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

generate_audio "$SCRIPT_1" "naija_male" "welcome_male_1min.mp3"

##############################################################################
# Script 3: Short Customer Service Message
##############################################################################

SCRIPT_3="Thank you for calling First Bank of Nigeria. Your call is important to us. Please stay on the line and one of our customer service representatives will be with you shortly. For account balance inquiries, press one. For recent transactions, press two. To speak with a representative, press three."

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Script 3: Customer Service Message${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

generate_audio "$SCRIPT_3" "naija_female" "customer_service.mp3"

##############################################################################
# Script 4: Delivery Notification
##############################################################################

SCRIPT_4="Good afternoon! This is a message from Jumia Express. Your package with order number J-K-2-0-2-5-9-8-7 has been dispatched and is on its way to your delivery address in Lekki. Our rider will arrive between 2 PM and 4 PM today. Please ensure someone is available to receive the package. Thank you for shopping with Jumia!"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Script 4: Delivery Notification${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

generate_audio "$SCRIPT_4" "naija_female" "delivery_notification.mp3"

##############################################################################
# Script 5: Educational Content
##############################################################################

SCRIPT_5="Welcome to Learn Tech Africa. In today's lesson, we'll explore how mobile money is transforming financial inclusion across Nigeria. From small market traders to large businesses, everyone now has access to digital banking through their mobile phones. This revolution started with simple SMS-based transactions and has evolved into sophisticated apps that let you pay bills, send money, and even invest, all from your smartphone."

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Script 5: Educational Content${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

generate_audio "$SCRIPT_5" "naija_male" "educational_content.mp3"

##############################################################################
# Summary
##############################################################################

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Audio Generation Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Generated Files:${NC}"
ls -lh "$OUTPUT_DIR"/*.mp3

echo -e "\n${BLUE}Output Directory:${NC} $OUTPUT_DIR"
echo -e "${BLUE}Total Files:${NC} $(ls -1 "$OUTPUT_DIR"/*.mp3 2>/dev/null | wc -l)"

echo -e "\n${YELLOW}To play the audio:${NC}"
echo -e "  macOS:  open $OUTPUT_DIR/welcome_female_1min.mp3"
echo -e "  Linux:  mpg123 $OUTPUT_DIR/welcome_female_1min.mp3"
echo -e "  Windows: start $OUTPUT_DIR/welcome_female_1min.mp3"

echo ""

