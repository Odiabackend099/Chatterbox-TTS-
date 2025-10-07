#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS - Requirements Check"
echo "=================================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Check Python version
echo "Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d '.' -f 1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d '.' -f 2)

    if [[ "$PYTHON_MAJOR" -eq 3 ]] && [[ "$PYTHON_MINOR" -ge 10 ]]; then
        echo -e "${GREEN}✓${NC} Python $PYTHON_VERSION (meets requirement: 3.10+)"
    else
        echo -e "${RED}✗${NC} Python $PYTHON_VERSION (need 3.10 or 3.11)"
        echo "  Install Python 3.11:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "    brew install python@3.11"
            echo "    OR download from: https://www.python.org/downloads/"
        else
            echo "    sudo apt install python3.11"
        fi
        ERRORS=$((ERRORS+1))
    fi
else
    echo -e "${RED}✗${NC} Python 3 not found"
    ERRORS=$((ERRORS+1))
fi

# Check for specific Python versions
for ver in 3.11 3.10 3.12; do
    if command -v python${ver} &> /dev/null; then
        echo -e "${GREEN}  Found:${NC} python${ver} ($(python${ver} --version))"
    fi
done

# Check GPU (macOS)
echo ""
echo "Checking GPU..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
        echo -e "${GREEN}✓${NC} Apple Silicon detected (MPS acceleration available)"
        echo "  Note: MPS is slower than NVIDIA GPU but faster than CPU"
    else
        echo -e "${YELLOW}⚠${NC} Intel Mac (CPU mode only - expect 10-30s latency)"
        WARNINGS=$((WARNINGS+1))
    fi
elif command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓${NC} NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
    echo -e "${YELLOW}⚠${NC} No GPU detected (CPU mode - expect 10-30s latency)"
    echo "  For production, deploy to RunPod with GPU"
    WARNINGS=$((WARNINGS+1))
fi

# Check disk space
echo ""
echo "Checking disk space..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    AVAILABLE=$(df -h . | awk 'NR==2 {print $4}')
    echo -e "${GREEN}✓${NC} Available space: $AVAILABLE"
    echo "  Required: ~5GB for models and cache"
else
    AVAILABLE=$(df -h . | awk 'NR==2 {print $4}')
    echo -e "${GREEN}✓${NC} Available space: $AVAILABLE"
fi

# Check for recommended tools
echo ""
echo "Checking optional tools..."

if command -v git &> /dev/null; then
    echo -e "${GREEN}✓${NC} git $(git --version | cut -d ' ' -f 3)"
else
    echo -e "${YELLOW}⚠${NC} git not found (optional, but recommended)"
fi

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker $(docker --version | cut -d ' ' -f 3 | tr -d ',')"
else
    echo -e "${YELLOW}⚠${NC} Docker not found (optional, needed for Docker deployment)"
fi

if command -v curl &> /dev/null; then
    echo -e "${GREEN}✓${NC} curl available"
else
    echo -e "${YELLOW}⚠${NC} curl not found"
fi

# Summary
echo ""
echo "=================================================="
echo "Summary"
echo "=================================================="

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}✓ All required components present${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run installation: ./setup/install_local.sh"
    echo "  2. Or see QUICKSTART.md for detailed instructions"
else
    echo -e "${RED}✗ $ERRORS error(s) found - please fix before continuing${NC}"
    echo ""
    echo "Required fixes:"
    if [[ $PYTHON_MAJOR -lt 3 ]] || [[ $PYTHON_MINOR -lt 10 ]]; then
        echo "  • Install Python 3.10 or 3.11"
    fi
fi

if [[ $WARNINGS -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) - system will work but with limitations${NC}"
fi

echo ""
exit $ERRORS
