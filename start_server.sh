#!/bin/bash
# Adaqua TTS Server Startup Script for RunPod

echo "======================================================"
echo "   Starting Adaqua TTS Server on RunPod"
echo "======================================================"
echo ""

# Set Python path
export PYTHONPATH=/workspace/chatterbox-tts
export CHATTERBOX_HOST=0.0.0.0
export CHATTERBOX_PORT=8004

echo "Configuration:"
echo "  PYTHONPATH: $PYTHONPATH"
echo "  Host: $CHATTERBOX_HOST"
echo "  Port: $CHATTERBOX_PORT"
echo ""

# Kill existing server
echo "Stopping any existing server..."
pkill -f "uvicorn.*server" || true
pkill -f "python.*server" || true
sleep 2

# Navigate to directory
cd /workspace/chatterbox-tts

echo "Starting server..."
echo ""

# Start server
exec uvicorn scripts.server:app --host 0.0.0.0 --port 8004 --log-level info

