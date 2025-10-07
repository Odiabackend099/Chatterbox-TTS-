#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS - Generate Test Audio"
echo "=================================================="
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    exit 1
fi

if ! docker info &> /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Create minimal test script
cat > /tmp/test_tts.py << 'EOF'
import sys
import soundfile as sf
from chatterbox.tts import ChatterboxTTS

print("Loading Chatterbox TTS model...")
model = ChatterboxTTS.from_pretrained(device="cpu")
print("✓ Model loaded")

# Generate 20-second sample
text = """
Hello! This is a demonstration of Chatterbox TTS technology.
I can speak in a natural, expressive voice with emotion control.
This open-source text-to-speech system supports voice cloning
and works in twenty-three different languages.
You can adjust my speaking style from neutral to dramatic.
This is just a quick test to show you what I sound like!
"""

print("Generating audio (this may take 10-30 seconds on CPU)...")
wav = model.generate(
    text=text.strip(),
    exaggeration=1.3,
    temperature=0.8
)

output_path = "/app/outputs/test_demo.wav"
sf.write(output_path, wav, 24000)
print(f"✓ Audio saved to {output_path}")
print(f"  Duration: {len(wav) / 24000:.1f} seconds")
print(f"  Sample rate: 24000 Hz")
EOF

# Build minimal Docker image for testing
echo "Building Docker image (first time only, ~5 minutes)..."
cat > /tmp/Dockerfile.test << 'EOF'
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir chatterbox-tts soundfile

WORKDIR /app
RUN mkdir -p /app/outputs

CMD ["python", "/app/test_tts.py"]
EOF

# Check if image exists
if docker images | grep -q "chatterbox-test"; then
    echo "✓ Using existing Docker image"
else
    docker build -t chatterbox-test -f /tmp/Dockerfile.test /tmp/
fi

# Create outputs directory
mkdir -p ~/chatterbox-twilio-integration/outputs

echo ""
echo "=================================================="
echo "Generating test audio..."
echo "=================================================="
echo ""
echo "⏳ This will take 10-30 seconds (CPU mode)"
echo "   First run will download model (~2-3GB)"
echo ""

# Run container
docker run --rm \
    -v /tmp/test_tts.py:/app/test_tts.py \
    -v ~/chatterbox-twilio-integration/outputs:/app/outputs \
    chatterbox-test

echo ""
echo "=================================================="
echo "✓ Audio Generated!"
echo "=================================================="
echo ""
echo "File saved to:"
echo "  ~/chatterbox-twilio-integration/outputs/test_demo.wav"
echo ""
echo "Play it:"
echo "  afplay ~/chatterbox-twilio-integration/outputs/test_demo.wav"
echo ""
echo "Or open in Finder:"
echo "  open ~/chatterbox-twilio-integration/outputs/"
echo ""
