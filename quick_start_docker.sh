#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS - Quick Start with Docker"
echo "=================================================="
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop."
    echo "   Download: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Check for .env
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ .env created"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env file with your API keys"
    echo ""
    echo "Required credentials:"
    echo "  • TWILIO_ACCOUNT_SID (from https://console.twilio.com)"
    echo "  • TWILIO_AUTH_TOKEN"
    echo "  • TWILIO_PHONE_NUMBER"
    echo "  • ANTHROPIC_API_KEY (from https://console.anthropic.com)"
    echo "     OR OPENAI_API_KEY"
    echo ""
    read -p "Press Enter when you've added your API keys to .env..."
fi

# Detect if we should use CPU or GPU compose file
COMPOSE_FILE="docker-compose.cpu.yml"
if command -v nvidia-smi &> /dev/null 2>&1; then
    echo "✓ NVIDIA GPU detected, using GPU configuration"
    COMPOSE_FILE="docker-compose.yml"
else
    echo "ℹ Using CPU configuration (slower, but works for testing)"
    echo "  For production with GPU, deploy to RunPod"
fi

# Build and start
echo ""
echo "Building Docker image (this may take 5-10 minutes)..."
docker-compose -f $COMPOSE_FILE build

echo ""
echo "Starting container..."
docker-compose -f $COMPOSE_FILE up -d

echo ""
echo "Waiting for server to start..."
sleep 5

# Wait for health check
MAX_WAIT=60
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:8004/health &> /dev/null; then
        echo "✓ Server is ready!"
        break
    fi
    echo "Waiting... ($WAITED/$MAX_WAIT seconds)"
    sleep 5
    WAITED=$((WAITED+5))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "⚠️  Server taking longer than expected to start"
    echo "This is normal on first run (downloading ~2-3GB model)"
    echo ""
    echo "Check progress with:"
    echo "  docker-compose logs -f"
fi

echo ""
echo "=================================================="
echo "Server Started!"
echo "=================================================="
echo ""
echo "Server URL: http://localhost:8004"
echo "API Docs: http://localhost:8004/docs"
echo ""
echo "Useful commands:"
echo "  • View logs:  docker-compose -f $COMPOSE_FILE logs -f"
echo "  • Stop:       docker-compose -f $COMPOSE_FILE down"
echo "  • Restart:    docker-compose -f $COMPOSE_FILE restart"
echo "  • Status:     docker-compose -f $COMPOSE_FILE ps"
echo ""
echo "Test the API:"
echo "  curl http://localhost:8004/health"
echo ""
echo "⚠️  Note: First TTS generation will be slow (10-30s on CPU)"
echo "   For production with GPU, deploy to RunPod (see runpod/ directory)"
echo ""
