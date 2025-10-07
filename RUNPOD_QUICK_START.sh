#!/bin/bash
###############################################################################
# RunPod TTS Server - Quick Start Script
# Pod ID: dmbt2v5xek8fou
# Location: /workspace/chatterbox-tts
###############################################################################

set -e

echo "====================================="
echo "🚀 RunPod TTS Quick Start"
echo "Pod: dmbt2v5xek8fou"
echo "====================================="
echo ""

# Navigate to project
cd /workspace/chatterbox-tts

# Pull latest code
echo "📥 Pulling latest code..."
git pull

# Kill old server
echo "🔄 Stopping old server..."
pkill -9 python 2>/dev/null || echo "No old server found"

# Start new server
echo ""
echo "✨ Starting TTS server with robust WAV encoding..."
echo "   Port: 8888"
echo "   Docs: http://0.0.0.0:8888/docs"
echo ""
python scripts/server_production.py
