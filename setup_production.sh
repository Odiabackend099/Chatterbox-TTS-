#!/bin/bash
# Production Setup Script for CallWaiting TTS API
# This script initializes the production environment

set -e

echo "============================================================================"
echo "CallWaiting TTS API - Production Setup"
echo "============================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root${NC}"
   exit 1
fi

echo -e "${YELLOW}Step 1: Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found${NC}"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose found${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    if [ -f env.example ]; then
        cp env.example .env
        echo -e "${GREEN}✓ .env file created${NC}"
        echo -e "${YELLOW}⚠  Please edit .env file with your credentials before continuing${NC}"
        echo ""
        read -p "Press Enter to continue after editing .env..."
    else
        echo -e "${RED}env.example not found. Please create .env manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ .env file exists${NC}"
fi

echo ""
echo -e "${YELLOW}Step 2: Creating necessary directories...${NC}"

# Create directories
mkdir -p outputs logs model_cache voices reference_audio ssl certbot/www

echo -e "${GREEN}✓ Directories created${NC}"

echo ""
echo -e "${YELLOW}Step 3: Starting database services...${NC}"

# Start PostgreSQL and Redis
docker-compose up -d postgres redis

echo "Waiting for services to be healthy (30s)..."
sleep 30

# Check if services are running
if ! docker-compose ps postgres | grep -q "Up"; then
    echo -e "${RED}PostgreSQL failed to start. Check logs with: docker-compose logs postgres${NC}"
    exit 1
fi

if ! docker-compose ps redis | grep -q "Up"; then
    echo -e "${RED}Redis failed to start. Check logs with: docker-compose logs redis${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Database services started${NC}"

echo ""
echo -e "${YELLOW}Step 4: Initializing database schema...${NC}"

# Wait for PostgreSQL to be ready
until docker exec chatterbox-postgres pg_isready -U postgres &>/dev/null; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

echo -e "${GREEN}✓ Database schema initialized${NC}"

echo ""
echo -e "${YELLOW}Step 5: Generating API keys...${NC}"

# Generate API keys
if [ -f scripts/generate_api_keys.py ]; then
    echo "Generating 5 production API keys..."
    python3 scripts/generate_api_keys.py -n 5 --prefix "cw_live_" --name-prefix "Production Key" > api_keys_$(date +%Y%m%d_%H%M%S).txt
    echo -e "${GREEN}✓ API keys generated and saved to api_keys_*.txt${NC}"
    echo -e "${YELLOW}⚠  Store these keys securely! They are shown only once.${NC}"
    echo ""
    echo "To insert keys into database:"
    echo "  python3 scripts/generate_api_keys.py -n 5 --sql | docker exec -i chatterbox-postgres psql -U postgres -d chatterbox"
else
    echo -e "${YELLOW}⚠  Key generation script not found. Skipping...${NC}"
fi

echo ""
echo -e "${YELLOW}Step 6: Building TTS server image...${NC}"

# Build the image
docker-compose build chatterbox-tts

echo -e "${GREEN}✓ Image built successfully${NC}"

echo ""
echo -e "${YELLOW}Step 7: Starting TTS server...${NC}"

# Start TTS server
docker-compose up -d chatterbox-tts

echo "Waiting for TTS server to start (60s)..."
sleep 60

echo ""
echo -e "${YELLOW}Step 8: Running health checks...${NC}"

# Health check
if curl -s http://localhost:8004/health | grep -q "healthy"; then
    echo -e "${GREEN}✓ TTS server is healthy${NC}"
else
    echo -e "${RED}✗ TTS server health check failed${NC}"
    echo "Check logs with: docker-compose logs chatterbox-tts"
    exit 1
fi

echo ""
echo "============================================================================"
echo -e "${GREEN}Production setup complete!${NC}"
echo "============================================================================"
echo ""
echo "Next steps:"
echo "1. Review and securely store API keys from api_keys_*.txt"
echo "2. Insert API keys into database (see commands above)"
echo "3. Configure NGINX and SSL (see PRODUCTION_DEPLOYMENT.md)"
echo "4. Update DNS to point to this server"
echo "5. Test the API with: curl http://localhost:8004/health"
echo ""
echo "Services running:"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - TTS API: localhost:8004"
echo ""
echo "Documentation:"
echo "  - Production Guide: PRODUCTION_DEPLOYMENT.md"
echo "  - API Docs: http://localhost:8004/docs"
echo "  - Health Check: http://localhost:8004/health"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop services: docker-compose down"
echo "  - Restart services: docker-compose restart"
echo ""
echo "For troubleshooting, see PRODUCTION_DEPLOYMENT.md"
echo ""

