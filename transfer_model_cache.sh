#!/bin/bash
###############################################################################
# Model Cache Transfer Script
# Transfer model cache from old pod to new pod to save bandwidth
###############################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Model Cache Transfer - RunPod Migration                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Pod details
OLD_POD_HOST="213.173.108.103"
OLD_POD_PORT="14814"
NEW_POD_HOST="157.157.221.29"
NEW_POD_PORT="19191"
SSH_KEY="$HOME/.ssh/id_ed25519"

echo -e "${YELLOW}Old Pod:${NC} a288y3vpbfxwkk (${OLD_POD_HOST}:${OLD_POD_PORT})"
echo -e "${YELLOW}New Pod:${NC} aav4qfa6yqgt3k (${NEW_POD_HOST}:${NEW_POD_PORT})"
echo ""

# Check SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}❌ SSH key not found: $SSH_KEY${NC}"
    echo "Please ensure your SSH key is in the correct location"
    exit 1
fi

# Step 1: Compress model cache on old pod
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 1: Compressing model cache on old pod...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ssh -p $OLD_POD_PORT -i "$SSH_KEY" root@$OLD_POD_HOST << 'ENDSSH'
cd /workspace
if [ -d "model_cache" ]; then
    echo "Compressing model cache..."
    tar -czf /tmp/model_cache.tar.gz model_cache/ 2>/dev/null || \
    tar -czf /tmp/model_cache.tar.gz -C /workspace model_cache/
    echo "✓ Compression complete"
    ls -lh /tmp/model_cache.tar.gz
else
    echo "⚠ Warning: model_cache directory not found"
    exit 1
fi
ENDSSH

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Model cache compressed on old pod${NC}"
else
    echo -e "${RED}❌ Failed to compress model cache${NC}"
    exit 1
fi

echo ""

# Step 2: Download from old pod
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2: Downloading from old pod...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

scp -P $OLD_POD_PORT -i "$SSH_KEY" root@$OLD_POD_HOST:/tmp/model_cache.tar.gz ./model_cache.tar.gz

if [ $? -eq 0 ] && [ -f "model_cache.tar.gz" ]; then
    FILE_SIZE=$(du -h model_cache.tar.gz | cut -f1)
    echo -e "${GREEN}✓ Downloaded: $FILE_SIZE${NC}"
else
    echo -e "${RED}❌ Failed to download model cache${NC}"
    exit 1
fi

echo ""

# Step 3: Upload to new pod
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3: Uploading to new pod...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

scp -P $NEW_POD_PORT -i "$SSH_KEY" ./model_cache.tar.gz root@$NEW_POD_HOST:/workspace/model_cache.tar.gz

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Uploaded to new pod${NC}"
else
    echo -e "${RED}❌ Failed to upload to new pod${NC}"
    exit 1
fi

echo ""

# Step 4: Extract on new pod
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 4: Extracting on new pod...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ssh -p $NEW_POD_PORT -i "$SSH_KEY" root@$NEW_POD_HOST << 'ENDSSH'
cd /workspace
if [ -f "model_cache.tar.gz" ]; then
    echo "Extracting model cache..."
    tar -xzf model_cache.tar.gz
    echo "✓ Extraction complete"
    echo ""
    echo "Verifying model cache:"
    ls -lh model_cache/ | head -10
    echo ""
    echo "Total size:"
    du -sh model_cache/
    # Clean up archive
    rm -f model_cache.tar.gz
else
    echo "⚠ Archive not found"
    exit 1
fi
ENDSSH

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Model cache extracted on new pod${NC}"
else
    echo -e "${RED}❌ Failed to extract model cache${NC}"
    exit 1
fi

echo ""

# Clean up local archive
echo -e "${YELLOW}Cleaning up local archive...${NC}"
rm -f model_cache.tar.gz
echo -e "${GREEN}✓ Local cleanup complete${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Model Cache Transfer Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Run deployment script: ./runpod/DEPLOY_PORT_8000.sh"
echo "  2. Or SSH to new pod and deploy manually"
echo ""

