# Chatterbox TTS Server Dockerfile
# Multi-stage build for production deployment

ARG PYTHON_VERSION=3.11
ARG RUNTIME=nvidia

# Base stage
FROM python:${PYTHON_VERSION}-slim as base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    libsndfile1 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Builder stage
FROM base as builder

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install --user -r requirements.txt

# Runtime stage
FROM base as runtime

# Copy Python packages from builder
COPY --from=builder /root/.local /root/.local

# Make sure scripts in .local are usable
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY scripts/ /app/scripts/
COPY config/ /app/config/
COPY tests/ /app/tests/
COPY voices/ /app/voices/
COPY reference_audio/ /app/reference_audio/

# Create necessary directories
RUN mkdir -p /app/outputs /app/logs /app/model_cache /app/hf_cache

# Set HuggingFace cache directory
ENV TRANSFORMERS_CACHE=/app/hf_cache \
    HF_HOME=/app/hf_cache \
    HF_HUB_ENABLE_HF_TRANSFER=1

# Expose port
EXPOSE 8004

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8004/health || exit 1

# Run server
CMD ["python", "scripts/server.py"]

# NVIDIA GPU runtime stage
FROM runtime as nvidia-runtime

# Install CUDA dependencies
RUN pip install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# AMD ROCm runtime stage
FROM runtime as rocm-runtime

# Install ROCm dependencies
RUN pip install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0

# CPU runtime stage
FROM runtime as cpu-runtime

# PyTorch CPU is already installed from requirements.txt

# Select final stage based on build arg
FROM ${RUNTIME}-runtime as final
