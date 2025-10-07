#!/bin/bash
set -e

echo "=================================================="
echo "Chatterbox TTS Local Installation Script"
echo "=================================================="
echo ""

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    echo "Platform: macOS detected"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    echo "Platform: Linux detected"
else
    echo "Error: Unsupported platform. This script supports macOS and Linux only."
    exit 1
fi

# Check Python version
echo ""
echo "Checking Python version..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d ' ' -f 2 | cut -d '.' -f 1,2)
    echo "Python version: $PYTHON_VERSION"

    if [[ "$PYTHON_VERSION" < "3.10" ]]; then
        echo "Error: Python 3.10 or higher required. Found Python $PYTHON_VERSION"
        echo "Please install Python 3.10 or 3.11 (recommended)"
        exit 1
    fi
else
    echo "Error: Python 3 not found. Please install Python 3.10 or 3.11"
    exit 1
fi

# Check for conda (recommended)
echo ""
echo "Checking for conda..."
if command -v conda &> /dev/null; then
    echo "Conda found: $(conda --version)"
    USE_CONDA=true
else
    echo "Conda not found. Will use venv instead."
    echo "Note: Conda is recommended for easier GPU setup."
    USE_CONDA=false
fi

# Check for NVIDIA GPU (Linux only)
if [[ "$PLATFORM" == "linux" ]]; then
    echo ""
    echo "Checking for NVIDIA GPU..."
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA GPU detected:"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
        USE_GPU="cuda"
    else
        echo "No NVIDIA GPU detected. Will use CPU mode (slower)."
        USE_GPU="cpu"
    fi
elif [[ "$PLATFORM" == "macos" ]]; then
    # Check for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        echo "Apple Silicon detected. Will use MPS acceleration."
        USE_GPU="mps"
    else
        echo "Intel Mac detected. Will use CPU mode."
        USE_GPU="cpu"
    fi
fi

# Create environment
echo ""
echo "=================================================="
echo "Creating Python environment..."
echo "=================================================="

cd "$(dirname "$0")/.."

if [[ "$USE_CONDA" == true ]]; then
    echo "Creating conda environment 'chatterbox'..."
    conda create -n chatterbox python=3.11 -y

    echo "Activating environment..."
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate chatterbox

    # Install PyTorch based on platform
    if [[ "$USE_GPU" == "cuda" ]]; then
        echo "Installing PyTorch with CUDA support..."
        conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y
    elif [[ "$USE_GPU" == "mps" ]]; then
        echo "Installing PyTorch with MPS support..."
        conda install pytorch torchvision torchaudio -c pytorch -y
    else
        echo "Installing PyTorch CPU version..."
        conda install pytorch torchvision torchaudio cpuonly -c pytorch -y
    fi
else
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate

    # Install PyTorch via pip
    if [[ "$USE_GPU" == "cuda" ]]; then
        echo "Installing PyTorch with CUDA support..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    else
        echo "Installing PyTorch CPU version..."
        pip install torch torchvision torchaudio
    fi
fi

# Upgrade pip
echo ""
echo "Upgrading pip..."
pip install --upgrade pip

# Install Chatterbox TTS
echo ""
echo "Installing Chatterbox TTS..."
pip install chatterbox-tts

# Install additional dependencies
echo ""
echo "Installing additional dependencies..."
pip install fastapi uvicorn[standard] python-multipart librosa soundfile pydub pyyaml requests twilio openai anthropic

# Install development dependencies
echo ""
echo "Installing development dependencies..."
pip install pytest black flake8 ipython jupyter

# Create config file
echo ""
echo "Creating default configuration..."
cat > config/config.yaml << 'EOF'
server:
  host: 0.0.0.0
  port: 8004
  workers: 1
  log_level: info

model:
  repository: "ResembleAI/chatterbox"
  device: auto  # auto, cuda, mps, cpu
  default_voice: "Emily.wav"
  cache_dir: "./model_cache"

generation_defaults:
  temperature: 0.8
  exaggeration: 1.3
  cfg_weight: 0.5
  seed: 0
  speed_factor: 1.0
  language: en

audio_output:
  format: WAV
  sample_rate: 24000
  max_reference_duration: 30
  output_dir: "./outputs"

text_processing:
  chunk_size: 200
  max_length: 2000
  enable_splitting: true

twilio:
  account_sid: ""  # Set via environment variable TWILIO_ACCOUNT_SID
  auth_token: ""   # Set via environment variable TWILIO_AUTH_TOKEN
  phone_number: "" # Your Twilio phone number

llm:
  provider: anthropic  # anthropic or openai
  model: claude-3-5-sonnet-20241022
  api_key: ""  # Set via environment variable ANTHROPIC_API_KEY or OPENAI_API_KEY
  max_tokens: 150
  temperature: 0.7

security:
  enable_auth: false
  username: admin
  password: changeme123
  enable_cors: true
  allowed_origins:
    - "*"
EOF

echo "Configuration file created at: config/config.yaml"

# Create directories
echo ""
echo "Creating necessary directories..."
mkdir -p voices reference_audio outputs logs model_cache

# Download sample voice (optional)
echo ""
echo "Would you like to download a sample reference voice? (y/n)"
read -r DOWNLOAD_SAMPLE
if [[ "$DOWNLOAD_SAMPLE" =~ ^[Yy]$ ]]; then
    echo "Downloading sample voice..."
    # Create a simple test voice file path placeholder
    echo "Note: Please add your own reference audio files to the 'reference_audio' directory"
    echo "Recommended: 10-20 second WAV files at 24kHz sample rate"
fi

# Create .env file
echo ""
echo "Creating .env template..."
cat > .env << 'EOF'
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=your_twilio_number_here

# LLM Configuration (choose one)
ANTHROPIC_API_KEY=your_anthropic_api_key_here
OPENAI_API_KEY=your_openai_api_key_here

# Server Configuration
CHATTERBOX_HOST=0.0.0.0
CHATTERBOX_PORT=8004
CHATTERBOX_DEVICE=auto

# Model Configuration
HF_HUB_ENABLE_HF_TRANSFER=1
TRANSFORMERS_CACHE=./model_cache
EOF

echo ".env template created. Please edit .env with your actual credentials."

# Create activation helper script
cat > activate.sh << 'EOF'
#!/bin/bash
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "Virtual environment activated"
elif command -v conda &> /dev/null; then
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate chatterbox
    echo "Conda environment 'chatterbox' activated"
else
    echo "No environment found"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "Environment variables loaded from .env"
fi

echo ""
echo "Environment ready! Use 'deactivate' or 'conda deactivate' to exit."
EOF
chmod +x activate.sh

# Installation complete
echo ""
echo "=================================================="
echo "Installation Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Edit .env file with your API keys and credentials"
echo "2. Activate environment: source activate.sh"
echo "3. Run test: python tests/test_installation.py"
echo "4. Start server: python scripts/server.py"
echo ""
echo "Environment details:"
echo "  Platform: $PLATFORM"
echo "  Python: $PYTHON_VERSION"
echo "  Device: $USE_GPU"
if [[ "$USE_CONDA" == true ]]; then
    echo "  Manager: conda"
    echo "  Activate: conda activate chatterbox"
else
    echo "  Manager: venv"
    echo "  Activate: source venv/bin/activate"
fi
echo ""
echo "Documentation: See README.md for usage examples"
echo ""
