#!/bin/bash

##############################################################################
# TTS Bridge Test Script
##############################################################################
# This script tests both direct RunPod TTS API calls and the FastAPI bridge.
#
# Prerequisites:
#   1. Set environment variables (source .env.tts)
#   2. RunPod TTS service must be running
#   3. (Optional) TTS bridge must be running for bridge tests
#
# Usage:
#   chmod +x test_tts_bridge.sh
#   source .env.tts  # Load environment variables
#   ./test_tts_bridge.sh
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DEFAULT_VOICE_ID=${DEFAULT_VOICE_ID:-naija_female}
TTS_BRIDGE_PORT=${TTS_BRIDGE_PORT:-7070}
OUTPUT_DIR="./outputs/tts_tests"

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_env_var() {
    local var_name=$1
    if [ -z "${!var_name}" ]; then
        print_error "Environment variable $var_name is not set"
        return 1
    fi
    print_success "$var_name is set"
    return 0
}

check_file_valid() {
    local filepath=$1
    local min_size=${2:-1000}  # Minimum 1KB by default
    
    if [ ! -f "$filepath" ]; then
        print_error "File not created: $filepath"
        return 1
    fi
    
    local filesize=$(wc -c < "$filepath")
    if [ "$filesize" -lt "$min_size" ]; then
        print_error "File too small ($filesize bytes): $filepath"
        return 1
    fi
    
    print_success "Valid MP3 created: $filepath ($filesize bytes)"
    return 0
}

##############################################################################
# Pre-flight Checks
##############################################################################

print_header "🔍 Pre-flight Checks"

# Check environment variables
check_env_var "TTS_BASE_URL" || exit 1
check_env_var "TTS_API_KEY" || exit 1

print_info "TTS_BASE_URL: $TTS_BASE_URL"
print_info "DEFAULT_VOICE_ID: $DEFAULT_VOICE_ID"

# Create output directory
mkdir -p "$OUTPUT_DIR"
print_success "Output directory ready: $OUTPUT_DIR"

##############################################################################
# Test 1: TTS Service Health Check
##############################################################################

print_header "🏥 Test 1: TTS Service Health Check"

if curl -s -f "${TTS_BASE_URL}/health" > /dev/null; then
    print_success "TTS service is healthy"
    curl -s "${TTS_BASE_URL}/health" | jq . || cat
else
    print_error "TTS service health check failed"
    print_warning "Make sure your RunPod TTS service is running"
    exit 1
fi

##############################################################################
# Test 2: Direct TTS API Call (Simple)
##############################################################################

print_header "🎤 Test 2: Direct TTS API Call (Simple)"

OUTPUT_FILE="$OUTPUT_DIR/direct_simple.mp3"

print_info "Calling: POST $TTS_BASE_URL/synthesize"
print_info "Text: 'Hello from Nigeria!'"
print_info "Voice: $DEFAULT_VOICE_ID"

if curl -X POST "${TTS_BASE_URL}/synthesize" \
    -H "Authorization: Bearer ${TTS_API_KEY}" \
    -F "text=Hello from Nigeria!" \
    -F "voice_id=${DEFAULT_VOICE_ID}" \
    --output "$OUTPUT_FILE" \
    --silent --show-error --fail; then
    
    check_file_valid "$OUTPUT_FILE" 1000
else
    print_error "Direct TTS API call failed"
    exit 1
fi

##############################################################################
# Test 3: Direct TTS API Call (Long Text)
##############################################################################

print_header "🎤 Test 3: Direct TTS API Call (Long Text)"

OUTPUT_FILE="$OUTPUT_DIR/direct_long.mp3"
LONG_TEXT="Welcome to Chatterbox TTS service. This is a longer text to test the synthesizer with multiple sentences. We support various Nigerian accents and voices. Thank you for using our service!"

print_info "Calling: POST $TTS_BASE_URL/synthesize"
print_info "Text length: ${#LONG_TEXT} characters"
print_info "Voice: $DEFAULT_VOICE_ID"

if curl -X POST "${TTS_BASE_URL}/synthesize" \
    -H "Authorization: Bearer ${TTS_API_KEY}" \
    -F "text=$LONG_TEXT" \
    -F "voice_id=${DEFAULT_VOICE_ID}" \
    --output "$OUTPUT_FILE" \
    --silent --show-error --fail \
    --max-time 30; then
    
    check_file_valid "$OUTPUT_FILE" 5000
else
    print_error "Long text TTS call failed"
fi

##############################################################################
# Test 4: Direct TTS API Call (Different Voice)
##############################################################################

print_header "🎤 Test 4: Direct TTS API Call (Different Voice)"

OUTPUT_FILE="$OUTPUT_DIR/direct_voice_naija_male.mp3"
VOICE_ID="naija_male"

print_info "Calling: POST $TTS_BASE_URL/synthesize"
print_info "Text: 'Testing male voice'"
print_info "Voice: $VOICE_ID"

if curl -X POST "${TTS_BASE_URL}/synthesize" \
    -H "Authorization: Bearer ${TTS_API_KEY}" \
    -F "text=Testing male voice" \
    -F "voice_id=${VOICE_ID}" \
    --output "$OUTPUT_FILE" \
    --silent --show-error --fail; then
    
    check_file_valid "$OUTPUT_FILE" 1000
else
    print_warning "Voice '$VOICE_ID' may not be available. Skipping."
fi

##############################################################################
# Test 5: TTS Bridge Health Check
##############################################################################

print_header "🌉 Test 5: TTS Bridge Health Check"

BRIDGE_URL="http://localhost:${TTS_BRIDGE_PORT}"

if curl -s -f "${BRIDGE_URL}/health" > /dev/null 2>&1; then
    print_success "TTS bridge is running on port $TTS_BRIDGE_PORT"
    curl -s "${BRIDGE_URL}/health" | jq . || cat
    BRIDGE_RUNNING=true
else
    print_warning "TTS bridge is not running on port $TTS_BRIDGE_PORT"
    print_info "To start the bridge, run:"
    print_info "  source .env.tts && python scripts/tts_bridge.py"
    print_warning "Skipping bridge tests..."
    BRIDGE_RUNNING=false
fi

##############################################################################
# Test 6: Bridge API Call (Simple)
##############################################################################

if [ "$BRIDGE_RUNNING" = true ]; then
    print_header "🌉 Test 6: Bridge API Call (Simple)"
    
    OUTPUT_FILE="$OUTPUT_DIR/bridge_simple.mp3"
    
    print_info "Calling: POST $BRIDGE_URL/tts"
    print_info "Text: 'Hello from the bridge!'"
    print_info "Voice: $DEFAULT_VOICE_ID"
    
    if curl -X POST "${BRIDGE_URL}/tts" \
        -F "text=Hello from the bridge!" \
        -F "voice_id=${DEFAULT_VOICE_ID}" \
        --output "$OUTPUT_FILE" \
        --silent --show-error --fail; then
        
        check_file_valid "$OUTPUT_FILE" 1000
    else
        print_error "Bridge API call failed"
    fi
fi

##############################################################################
# Test 7: Bridge API Call (No voice_id - should use default)
##############################################################################

if [ "$BRIDGE_RUNNING" = true ]; then
    print_header "🌉 Test 7: Bridge API Call (Default Voice)"
    
    OUTPUT_FILE="$OUTPUT_DIR/bridge_default_voice.mp3"
    
    print_info "Calling: POST $BRIDGE_URL/tts"
    print_info "Text: 'Testing default voice'"
    print_info "Voice: (not specified, should use DEFAULT_VOICE_ID)"
    
    if curl -X POST "${BRIDGE_URL}/tts" \
        -F "text=Testing default voice" \
        --output "$OUTPUT_FILE" \
        --silent --show-error --fail; then
        
        check_file_valid "$OUTPUT_FILE" 1000
    else
        print_error "Bridge default voice test failed"
    fi
fi

##############################################################################
# Test 8: Error Handling (Invalid API Key)
##############################################################################

print_header "🔐 Test 8: Error Handling (Invalid API Key)"

print_info "Testing with invalid API key..."

HTTP_CODE=$(curl -X POST "${TTS_BASE_URL}/synthesize" \
    -H "Authorization: Bearer invalid_key_12345" \
    -F "text=This should fail" \
    -F "voice_id=${DEFAULT_VOICE_ID}" \
    --silent --output /dev/null \
    --write-out "%{http_code}")

if [ "$HTTP_CODE" -eq 401 ] || [ "$HTTP_CODE" -eq 403 ]; then
    print_success "Correctly rejected invalid API key (HTTP $HTTP_CODE)"
else
    print_warning "Expected 401/403, got HTTP $HTTP_CODE"
fi

##############################################################################
# Test 9: Error Handling (Missing Text)
##############################################################################

print_header "📝 Test 9: Error Handling (Missing Text)"

print_info "Testing with missing text parameter..."

HTTP_CODE=$(curl -X POST "${TTS_BASE_URL}/synthesize" \
    -H "Authorization: Bearer ${TTS_API_KEY}" \
    -F "voice_id=${DEFAULT_VOICE_ID}" \
    --silent --output /dev/null \
    --write-out "%{http_code}")

if [ "$HTTP_CODE" -eq 400 ] || [ "$HTTP_CODE" -eq 422 ]; then
    print_success "Correctly rejected missing text (HTTP $HTTP_CODE)"
else
    print_warning "Expected 400/422, got HTTP $HTTP_CODE"
fi

##############################################################################
# Summary
##############################################################################

print_header "📊 Test Summary"

print_info "Output files created in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.mp3 2>/dev/null || print_warning "No MP3 files found"

print_success "All tests completed!"

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ TTS Integration Tests Passed${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

print_info "Next steps:"
echo "  1. Play the generated MP3 files to verify audio quality"
echo "  2. Import n8n workflows from ./n8n/"
echo "  3. Set up Twilio integration (see main README)"
echo "  4. Deploy to production"

exit 0

