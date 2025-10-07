#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS - Quick Audio Test"
echo "=================================================="
echo ""
echo "⚠️  Note: First run will download ~2-3GB model"
echo "   This may take 10-15 minutes depending on your connection"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Create test Python script
cat > ~/chatterbox-twilio-integration/scripts/quick_test.py << 'PYTHONEOF'
#!/usr/bin/env python3
"""Quick test script for Chatterbox TTS"""
import sys
import os
import soundfile as sf

print("=" * 60)
print("Chatterbox TTS Quick Test")
print("=" * 60)
print()

try:
    print("1. Loading Chatterbox TTS model...")
    from chatterbox.tts import ChatterboxTTS

    device = os.getenv('CHATTERBOX_DEVICE', 'cpu')
    print(f"   Using device: {device}")

    model = ChatterboxTTS.from_pretrained(device=device)
    print("   ✓ Model loaded successfully")
    print()

    # Test text (about 20 seconds when spoken)
    test_text = """
    Hello! This is Chatterbox TTS in action.
    I'm an open-source text-to-speech system that can clone voices
    and speak in twenty-three different languages.
    I support emotion control, from neutral to very expressive.
    This technology is perfect for voice agents, phone systems,
    audiobooks, and any application that needs natural speech.
    I hope you enjoy this demonstration!
    """

    print("2. Generating audio...")
    print(f"   Text: {test_text[:60].strip()}...")
    print(f"   This may take 10-30 seconds on CPU")
    print()

    wav = model.generate(
        text=test_text.strip(),
        exaggeration=1.3,
        temperature=0.8
    )

    # Save output
    output_dir = os.path.join(os.path.dirname(__file__), '..', 'outputs')
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, 'test_demo.wav')

    sf.write(output_path, wav, 24000)

    duration = len(wav) / 24000
    print("   ✓ Audio generated successfully")
    print()
    print("=" * 60)
    print("SUCCESS!")
    print("=" * 60)
    print(f"File: {output_path}")
    print(f"Duration: {duration:.1f} seconds")
    print(f"Sample rate: 24000 Hz")
    print()
    print("Play it:")
    print(f"  afplay {output_path}")
    print()

except Exception as e:
    print(f"✗ Error: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYTHONEOF

chmod +x ~/chatterbox-twilio-integration/scripts/quick_test.py

# Use the full docker-compose setup
cd ~/chatterbox-twilio-integration

# Check if we need to create .env
if [ ! -f .env ]; then
    echo "Creating minimal .env file..."
    cat > .env << 'ENVEOF'
CHATTERBOX_DEVICE=cpu
CHATTERBOX_HOST=0.0.0.0
CHATTERBOX_PORT=8004
TRANSFORMERS_CACHE=/app/hf_cache
ENVEOF
fi

echo ""
echo "Starting Docker container..."
echo "This will:"
echo "  1. Build Docker image (~5-10 min first time)"
echo "  2. Download Chatterbox model (~5 min first time)"
echo "  3. Generate audio (~30 seconds)"
echo ""

# Build the image
docker-compose -f docker-compose.cpu.yml build

# Run the test script
echo ""
echo "Running test generation..."
docker-compose -f docker-compose.cpu.yml run --rm chatterbox-tts python /app/scripts/quick_test.py

echo ""
echo "=================================================="
echo "✓ Complete!"
echo "=================================================="
echo ""
echo "Audio file location:"
echo "  ~/chatterbox-twilio-integration/outputs/test_demo.wav"
echo ""
echo "Play it now:"
echo "  afplay ~/chatterbox-twilio-integration/outputs/test_demo.wav"
echo ""
echo "Or open in Finder:"
echo "  open ~/chatterbox-twilio-integration/outputs/"
echo ""
