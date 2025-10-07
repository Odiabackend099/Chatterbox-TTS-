# Chatterbox TTS Local Installation Script for Windows
# Run with: powershell -ExecutionPolicy Bypass -File install_local.ps1

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Chatterbox TTS Local Installation Script (Windows)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check Python version
Write-Host "Checking Python version..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Found: $pythonVersion" -ForegroundColor Green

    $versionNumber = [version]($pythonVersion -replace 'Python ', '')
    if ($versionNumber -lt [version]"3.10") {
        Write-Host "Error: Python 3.10 or higher required" -ForegroundColor Red
        Write-Host "Please install Python 3.10 or 3.11 from python.org" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: Python not found" -ForegroundColor Red
    Write-Host "Please install Python 3.10 or 3.11 from python.org" -ForegroundColor Red
    exit 1
}

# Check for NVIDIA GPU
Write-Host ""
Write-Host "Checking for NVIDIA GPU..." -ForegroundColor Yellow
try {
    $nvidiaCheck = nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>&1
    Write-Host "NVIDIA GPU detected:" -ForegroundColor Green
    Write-Host $nvidiaCheck -ForegroundColor Green
    $useGPU = "cuda"
} catch {
    Write-Host "No NVIDIA GPU detected. Will use CPU mode (slower)." -ForegroundColor Yellow
    $useGPU = "cpu"
}

# Check for conda
Write-Host ""
Write-Host "Checking for conda..." -ForegroundColor Yellow
$useConda = $false
try {
    $condaVersion = conda --version 2>&1
    Write-Host "Conda found: $condaVersion" -ForegroundColor Green
    $useConda = $true
} catch {
    Write-Host "Conda not found. Will use venv instead." -ForegroundColor Yellow
    Write-Host "Note: Conda is recommended for easier GPU setup." -ForegroundColor Yellow
}

# Navigate to project root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Split-Path -Parent $scriptDir)

# Create environment
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Creating Python environment..." -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if ($useConda) {
    Write-Host "Creating conda environment 'chatterbox'..." -ForegroundColor Yellow
    conda create -n chatterbox python=3.11 -y

    Write-Host "Activating environment..." -ForegroundColor Yellow
    conda activate chatterbox

    if ($useGPU -eq "cuda") {
        Write-Host "Installing PyTorch with CUDA support..." -ForegroundColor Yellow
        conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y
    } else {
        Write-Host "Installing PyTorch CPU version..." -ForegroundColor Yellow
        conda install pytorch torchvision torchaudio cpuonly -c pytorch -y
    }
} else {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv

    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    .\venv\Scripts\Activate.ps1

    if ($useGPU -eq "cuda") {
        Write-Host "Installing PyTorch with CUDA support..." -ForegroundColor Yellow
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    } else {
        Write-Host "Installing PyTorch CPU version..." -ForegroundColor Yellow
        pip install torch torchvision torchaudio
    }
}

# Upgrade pip
Write-Host ""
Write-Host "Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip

# Install Chatterbox TTS
Write-Host ""
Write-Host "Installing Chatterbox TTS..." -ForegroundColor Yellow
pip install chatterbox-tts

# Install additional dependencies
Write-Host ""
Write-Host "Installing additional dependencies..." -ForegroundColor Yellow
pip install fastapi uvicorn[standard] python-multipart librosa soundfile pydub pyyaml requests twilio openai anthropic

# Install development dependencies
Write-Host ""
Write-Host "Installing development dependencies..." -ForegroundColor Yellow
pip install pytest black flake8 ipython jupyter

# Create directories
Write-Host ""
Write-Host "Creating necessary directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path config, voices, reference_audio, outputs, logs, model_cache | Out-Null

# Create config file
Write-Host ""
Write-Host "Creating default configuration..." -ForegroundColor Yellow
$configContent = @'
server:
  host: 0.0.0.0
  port: 8004
  workers: 1
  log_level: info

model:
  repository: "ResembleAI/chatterbox"
  device: auto  # auto, cuda, cpu
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
'@
Set-Content -Path "config/config.yaml" -Value $configContent

# Create .env file
Write-Host ""
Write-Host "Creating .env template..." -ForegroundColor Yellow
$envContent = @'
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
'@
Set-Content -Path ".env" -Value $envContent

# Create activation helper script
$activateContent = @'
# Activate environment and load .env
if (Test-Path "venv\Scripts\Activate.ps1") {
    .\venv\Scripts\Activate.ps1
    Write-Host "Virtual environment activated" -ForegroundColor Green
} else {
    conda activate chatterbox
    Write-Host "Conda environment activated" -ForegroundColor Green
}

# Load .env variables
if (Test-Path ".env") {
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $name = $matches[1]
            $value = $matches[2]
            if (-not $name.StartsWith('#')) {
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
            }
        }
    }
    Write-Host "Environment variables loaded from .env" -ForegroundColor Green
}

Write-Host ""
Write-Host "Environment ready!" -ForegroundColor Cyan
'@
Set-Content -Path "activate.ps1" -Value $activateContent

# Installation complete
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env file with your API keys and credentials"
Write-Host "2. Activate environment: .\activate.ps1"
Write-Host "3. Run test: python tests\test_installation.py"
Write-Host "4. Start server: python scripts\server.py"
Write-Host ""
Write-Host "Environment details:" -ForegroundColor Yellow
Write-Host "  Python: $pythonVersion"
Write-Host "  Device: $useGPU"
if ($useConda) {
    Write-Host "  Manager: conda"
    Write-Host "  Activate: conda activate chatterbox"
} else {
    Write-Host "  Manager: venv"
    Write-Host "  Activate: .\venv\Scripts\Activate.ps1"
}
Write-Host ""
Write-Host "Documentation: See README.md for usage examples" -ForegroundColor Yellow
Write-Host ""
