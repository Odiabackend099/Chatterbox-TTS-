#!/bin/bash
# Kokoro TTS Deployment Script
# Automatically installs and tests Kokoro TTS on RunPod

set -e

echo "============================================"
echo "Kokoro TTS Deployment"
echo "============================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check Python
echo -e "${YELLOW}[1/5]${NC} Checking Python installation..."
python3 --version || { echo -e "${RED}✗${NC} Python 3 not found"; exit 1; }
echo -e "${GREEN}✓${NC} Python OK"
echo ""

# Step 2: Install Kokoro
echo -e "${YELLOW}[2/5]${NC} Installing Kokoro TTS..."
pip install kokoro-onnx --quiet && echo -e "${GREEN}✓${NC} Kokoro TTS installed" || {
    echo -e "${RED}✗${NC} Installation failed"
    echo "Trying with --upgrade..."
    pip install --upgrade kokoro-onnx
}
echo ""

# Step 3: Create output directory
echo -e "${YELLOW}[3/5]${NC} Creating output directory..."
mkdir -p test_outputs/kokoro_samples
echo -e "${GREEN}✓${NC} Directory created"
echo ""

# Step 4: Generate test sample
echo -e "${YELLOW}[4/5]${NC} Generating test audio sample..."
python3 << 'EOF'
from scripts.kokoro_tts_engine import KokoroTTSEngine
import sys

try:
    # Professional female voice
    engine = KokoroTTSEngine(voice="af_heart")

    # Test text
    text = """Good afternoon. This is a friendly reminder from CallWaiting Services.
You have an appointment scheduled for tomorrow at three P M.
Please ensure you arrive fifteen minutes before your scheduled time.
Thank you for choosing CallWaiting Services."""

    # Generate
    audio = engine.generate(
        text,
        speed=0.85,
        pitch=-0.2,
        output_file="test_outputs/kokoro_samples/deployment_test.wav"
    )

    duration = len(audio) / 24000
    print(f"\n✓ Generated {len(audio)} samples ({duration:.2f}s)")
    print("✓ Saved to: test_outputs/kokoro_samples/deployment_test.wav")
    sys.exit(0)

except Exception as e:
    print(f"\n✗ Failed: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Test audio generated successfully"
else
    echo -e "${RED}✗${NC} Test failed"
    exit 1
fi
echo ""

# Step 5: Verify file
echo -e "${YELLOW}[5/5]${NC} Verifying output..."
if [ -f "test_outputs/kokoro_samples/deployment_test.wav" ]; then
    SIZE=$(wc -c < "test_outputs/kokoro_samples/deployment_test.wav")
    echo -e "${GREEN}✓${NC} Audio file created: $SIZE bytes"
else
    echo -e "${RED}✗${NC} Audio file not found"
    exit 1
fi
echo ""

# Success
echo "============================================"
echo -e "${GREEN}✓ DEPLOYMENT SUCCESSFUL!${NC}"
echo "============================================"
echo ""
echo "Generated test sample:"
echo "  test_outputs/kokoro_samples/deployment_test.wav"
echo ""
echo "To listen:"
echo "  # On server (if audio forwarding enabled)"
echo "  afplay test_outputs/kokoro_samples/deployment_test.wav"
echo ""
echo "  # Or download to local machine"
echo "  scp root@<runpod-ip>:/workspace/chatterbox-twilio-integration/test_outputs/kokoro_samples/*.wav ."
echo "  afplay deployment_test.wav"
echo ""
echo "Next steps:"
echo "  1. Download and listen to the test sample"
echo "  2. Compare with current Chatterbox voice"
echo "  3. If satisfied, integrate using: KOKORO_DEPLOYMENT_GUIDE.md"
echo ""
