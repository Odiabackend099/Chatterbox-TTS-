#!/bin/bash

##############################################################################
# Environment Setup Helper
##############################################################################
# Quickly setup your environment for different use cases
##############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Chatterbox TTS - Environment Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Choose your setup:${NC}\n"
echo "  1) Full setup (TTS + Twilio + n8n)"
echo "  2) TTS only"
echo "  3) Twilio only"
echo "  4) Show current configuration"
echo "  5) Exit"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
  1)
    echo -e "\n${BLUE}Setting up complete environment...${NC}\n"
    
    if [ ! -f ".env.master" ]; then
      echo -e "${YELLOW}⚠ .env.master not found!${NC}"
      exit 1
    fi
    
    cp .env.master .env
    echo -e "${GREEN}✓ Created .env from .env.master${NC}"
    
    source .env
    echo -e "${GREEN}✓ Loaded environment variables${NC}\n"
    
    echo -e "${BLUE}Configuration loaded:${NC}"
    echo -e "  TTS URL:      ${TTS_BASE_URL}"
    echo -e "  TTS API Key:  ${TTS_API_KEY:0:20}..."
    echo -e "  Twilio Phone: ${TWILIO_PHONE_NUMBER}"
    echo -e "  Twilio SID:   ${TWILIO_ACCOUNT_SID:0:10}..."
    ;;
    
  2)
    echo -e "\n${BLUE}Setting up TTS only...${NC}\n"
    
    if [ ! -f "env.tts.example" ]; then
      echo -e "${YELLOW}⚠ env.tts.example not found!${NC}"
      exit 1
    fi
    
    cp env.tts.example .env.tts
    echo -e "${GREEN}✓ Created .env.tts${NC}"
    
    source .env.tts
    echo -e "${GREEN}✓ Loaded TTS environment${NC}\n"
    
    echo -e "${BLUE}TTS Configuration:${NC}"
    echo -e "  TTS URL:  ${TTS_BASE_URL}"
    echo -e "  API Key:  ${TTS_API_KEY:0:20}..."
    echo -e "  Voice ID: ${DEFAULT_VOICE_ID}"
    ;;
    
  3)
    echo -e "\n${BLUE}Setting up Twilio only...${NC}\n"
    
    if [ ! -f "env.twilio.example" ]; then
      echo -e "${YELLOW}⚠ env.twilio.example not found!${NC}"
      exit 1
    fi
    
    cp env.twilio.example .env.twilio
    echo -e "${GREEN}✓ Created .env.twilio${NC}"
    
    source .env.twilio
    echo -e "${GREEN}✓ Loaded Twilio environment${NC}\n"
    
    echo -e "${BLUE}Twilio Configuration:${NC}"
    echo -e "  Phone:       ${TWILIO_PHONE_NUMBER}"
    echo -e "  Account SID: ${TWILIO_ACCOUNT_SID:0:10}..."
    ;;
    
  4)
    echo -e "\n${BLUE}Current Configuration:${NC}\n"
    
    if [ -f ".env" ]; then
      echo -e "${GREEN}✓ .env exists${NC}"
      source .env 2>/dev/null || true
    else
      echo -e "${YELLOW}⚠ .env not found${NC}"
    fi
    
    echo ""
    echo "TTS Configuration:"
    echo "  TTS_BASE_URL:         ${TTS_BASE_URL:-Not set}"
    echo "  TTS_API_KEY:          ${TTS_API_KEY:+Set (${TTS_API_KEY:0:20}...)}"
    echo "  DEFAULT_VOICE_ID:     ${DEFAULT_VOICE_ID:-Not set}"
    echo ""
    echo "Twilio Configuration:"
    echo "  TWILIO_ACCOUNT_SID:   ${TWILIO_ACCOUNT_SID:+Set (${TWILIO_ACCOUNT_SID:0:10}...)}"
    echo "  TWILIO_AUTH_TOKEN:    ${TWILIO_AUTH_TOKEN:+Set}"
    echo "  TWILIO_PHONE_NUMBER:  ${TWILIO_PHONE_NUMBER:-Not set}"
    ;;
    
  5)
    echo -e "\n${BLUE}Exiting...${NC}\n"
    exit 0
    ;;
    
  *)
    echo -e "\n${YELLOW}Invalid choice${NC}\n"
    exit 1
    ;;
esac

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Environment setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Load variables: ${BLUE}source .env${NC}"
echo -e "  2. Test TTS:       ${BLUE}./test_scripts/quick_test.sh${NC}"
echo -e "  3. Test Twilio:    ${BLUE}./test_twilio.sh${NC}"
echo ""

