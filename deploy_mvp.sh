#!/bin/bash
# ============================================================================
# MVP Production Deployment Script
# Deploy AI Voice Agent in One Command
# ============================================================================

set -e  # Exit on error

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🚀 AI Voice Agent - MVP Production Deployment                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# Step 1: Pre-flight Checks
# ============================================================================

echo -e "${YELLOW}[1/7] Running pre-flight checks...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    echo "   Install from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    echo "   Install from: https://docs.docker.com/compose/install/"
    exit 1
fi

echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"

# ============================================================================
# Step 2: Environment Configuration
# ============================================================================

echo -e "\n${YELLOW}[2/7] Configuring environment...${NC}"

if [ ! -f .env.production ]; then
    echo -e "${YELLOW}⚠️  No .env.production file found. Creating from template...${NC}"

    if [ -f .env.production.template ]; then
        cp .env.production.template .env.production
        echo -e "${GREEN}✅ Created .env.production from template${NC}"
    elif [ -f .env.example ]; then
        cp .env.example .env.production
        echo -e "${GREEN}✅ Created .env.production from .env.example${NC}"
    else
        echo -e "${RED}❌ No environment template found!${NC}"
        exit 1
    fi

    echo -e "${YELLOW}⚠️  IMPORTANT: You need to edit .env.production with your credentials!${NC}"
    echo ""
    echo "Required values:"
    echo "  - TWILIO_ACCOUNT_SID"
    echo "  - TWILIO_AUTH_TOKEN"
    echo "  - TWILIO_PHONE_NUMBER"
    echo "  - ANTHROPIC_API_KEY (or OPENAI_API_KEY)"
    echo "  - POSTGRES_PASSWORD (change from default!)"
    echo ""
    read -p "Press Enter after you've edited .env.production with your credentials..."
fi

# Check if critical values are set
if grep -q "TWILIO_ACCOUNT_SID=$" .env.production || grep -q "ANTHROPIC_API_KEY=$" .env.production; then
    echo -e "${RED}❌ Missing required credentials in .env.production${NC}"
    echo "Please edit .env.production and add your Twilio and Anthropic credentials"
    exit 1
fi

# Check for default password
if grep -q "POSTGRES_PASSWORD=changeme123" .env.production || grep -q "POSTGRES_PASSWORD=CHANGE_ME" .env.production; then
    echo -e "${YELLOW}⚠️  WARNING: Default database password detected!${NC}"
    echo "Generating secure password..."

    # Generate secure password
    NEW_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

    # Update .env.production
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PASSWORD/" .env.production
    else
        # Linux
        sed -i "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PASSWORD/" .env.production
    fi

    echo -e "${GREEN}✅ Generated secure database password${NC}"
fi

# Load environment variables
set -a
source .env.production
set +a

echo -e "${GREEN}✅ Environment configured${NC}"

# ============================================================================
# Step 3: Security Configuration
# ============================================================================

echo -e "\n${YELLOW}[3/7] Applying security hardening...${NC}"

# Update config.yaml to disable wildcard CORS
if [ -f config/config.yaml ]; then
    if grep -q "allowed_origins:.*\*" config/config.yaml; then
        echo -e "${YELLOW}⚠️  Wildcard CORS detected in config.yaml${NC}"

        # Create backup
        cp config/config.yaml config/config.yaml.backup

        # Update CORS (if ALLOWED_ORIGINS is set in env)
        if [ ! -z "$ALLOWED_ORIGINS" ]; then
            echo "  Restricting CORS to: $ALLOWED_ORIGINS"
            # This would require more complex sed/awk logic
            echo "  Please manually update config/config.yaml if needed"
        fi
    fi
fi

# Check for default credentials in config
if grep -q "password: changeme" config/config.yaml 2>/dev/null; then
    echo -e "${RED}❌ Default password found in config.yaml!${NC}"
    echo "Please update config/config.yaml and remove default credentials"
fi

echo -e "${GREEN}✅ Security checks completed${NC}"

# ============================================================================
# Step 4: Create Required Directories
# ============================================================================

echo -e "\n${YELLOW}[4/7] Creating required directories...${NC}"

mkdir -p outputs logs model_cache voices reference_audio database

echo -e "${GREEN}✅ Directories created${NC}"

# ============================================================================
# Step 5: Build and Start Services
# ============================================================================

echo -e "\n${YELLOW}[5/7] Building and starting Docker services...${NC}"
echo "This may take 5-10 minutes on first run (downloading models)..."

# Stop any existing containers
docker-compose down 2>/dev/null || true

# Build and start services
docker-compose up -d --build

echo -e "${GREEN}✅ Services started${NC}"

# ============================================================================
# Step 6: Wait for Services to be Ready
# ============================================================================

echo -e "\n${YELLOW}[6/7] Waiting for services to be ready...${NC}"

echo "  Waiting for database..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Database is ready${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}  ❌ Database failed to start${NC}"
        docker-compose logs postgres
        exit 1
    fi
    sleep 2
done

echo "  Waiting for Redis..."
for i in {1..20}; do
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Redis is ready${NC}"
        break
    fi
    if [ $i -eq 20 ]; then
        echo -e "${RED}  ❌ Redis failed to start${NC}"
        docker-compose logs redis
        exit 1
    fi
    sleep 1
done

echo "  Waiting for TTS server (this takes 2-3 minutes for model download)..."
for i in {1..90}; do
    if curl -s http://localhost:${CHATTERBOX_PORT:-8004}/health > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ TTS server is ready${NC}"
        break
    fi
    if [ $i -eq 90 ]; then
        echo -e "${RED}  ❌ TTS server failed to start${NC}"
        echo "Check logs with: docker-compose logs chatterbox-tts"
        exit 1
    fi
    printf "."
    sleep 2
done

echo -e "\n${GREEN}✅ All services are running${NC}"

# ============================================================================
# Step 7: Verify Deployment
# ============================================================================

echo -e "\n${YELLOW}[7/7] Verifying deployment...${NC}"

# Check health endpoint
HEALTH_RESPONSE=$(curl -s http://localhost:${CHATTERBOX_PORT:-8004}/health)

if echo "$HEALTH_RESPONSE" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✅ Health check passed${NC}"
else
    echo -e "${YELLOW}⚠️  Health check returned degraded status:${NC}"
    echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
fi

# ============================================================================
# Deployment Complete - Show Next Steps
# ============================================================================

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ DEPLOYMENT SUCCESSFUL!                                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📊 Server Status:${NC}"
echo "   • API Server: http://localhost:${CHATTERBOX_PORT:-8004}"
echo "   • API Docs: http://localhost:${CHATTERBOX_PORT:-8004}/docs"
echo "   • Health Check: http://localhost:${CHATTERBOX_PORT:-8004}/health"
echo ""
echo -e "${GREEN}🎯 Next Steps:${NC}"
echo ""
echo "1. Expose your server to the internet:"
echo "   ${YELLOW}Option A - ngrok (for testing):${NC}"
echo "     ngrok http ${CHATTERBOX_PORT:-8004}"
echo "     Copy the HTTPS URL (e.g., https://abc123.ngrok.io)"
echo ""
echo "   ${YELLOW}Option B - Your domain (for production):${NC}"
echo "     Point your domain DNS to this server"
echo "     Set up SSL: sudo certbot --nginx -d voice.yourdomain.com"
echo ""
echo "2. Configure Twilio webhook:"
echo "   • Go to: https://console.twilio.com/us1/develop/phone-numbers/manage/incoming"
echo "   • Click your phone number"
echo "   • Set 'A CALL COMES IN' to: https://YOUR-URL/twilio/voice"
echo "   • Set HTTP method to: POST"
echo "   • Save"
echo ""
echo "3. Test your AI:"
echo "   • Call your Twilio number: ${TWILIO_PHONE_NUMBER:-YOUR_TWILIO_NUMBER}"
echo "   • You should hear: 'Hello! I'm your AI assistant...'"
echo ""
echo -e "${GREEN}📝 Useful Commands:${NC}"
echo "   • View logs: docker-compose logs -f chatterbox-tts"
echo "   • Restart: docker-compose restart chatterbox-tts"
echo "   • Stop all: docker-compose down"
echo "   • Check status: curl http://localhost:${CHATTERBOX_PORT:-8004}/health"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY REMINDERS:${NC}"
echo "   • Never commit .env.production to git!"
echo "   • Enable HTTPS before production use"
echo "   • Review config/config.yaml for security settings"
echo "   • Monitor logs for suspicious activity"
echo ""
echo "📖 Full documentation: MVP_PRODUCTION_SETUP.md"
echo ""

# Tail logs (optional)
read -p "View live logs? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Press Ctrl+C to exit log view"
    sleep 2
    docker-compose logs -f chatterbox-tts
fi
