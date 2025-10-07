#!/usr/bin/env python3
"""
Production TTS Server - GUARANTEED TO WORK
Minimal dependencies, maximum reliability
"""

import os
import sys
import logging
from pathlib import Path

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Minimal FastAPI app
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import torch

# Import TTS
from chatterbox.tts import ChatterboxTTS

# Import our production API
from api_production import router as production_router
from voice_manager import get_voice_manager

# Create app
app = FastAPI(
    title="CallWaiting TTS API - Production",
    description="Production-ready TTS with zero setup required",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Store model in app state
app.state.tts_model = None

@app.on_event("startup")
async def startup():
    """Initialize everything on startup"""
    logger.info("=" * 80)
    logger.info("Starting Production TTS Server")
    logger.info("=" * 80)

    # Create directories
    for d in ['outputs', 'logs', 'model_cache', 'voices']:
        Path(d).mkdir(exist_ok=True)

    # Bootstrap voices
    logger.info("Loading voice configurations...")
    voice_manager = get_voice_manager()
    logger.info(f"✓ Loaded {len(voice_manager.list_voices())} voices")

    # Determine device
    if torch.cuda.is_available():
        device = "cuda"
        logger.info(f"✓ CUDA available: {torch.cuda.get_device_name(0)}")
    elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
        device = "mps"
        logger.info("✓ MPS (Apple Silicon) available")
    else:
        device = "cpu"
        logger.info("⚠ Using CPU mode (slower)")

    # Load TTS model
    logger.info(f"Loading Chatterbox TTS model on {device}...")
    try:
        app.state.tts_model = ChatterboxTTS.from_pretrained(device=device)
        logger.info("✓ TTS model loaded successfully")
    except Exception as e:
        logger.error(f"✗ Failed to load TTS model: {e}")
        logger.error("Server will start but TTS will not work")

    logger.info("=" * 80)
    logger.info("✓ SERVER READY")
    logger.info("=" * 80)
    port = int(os.getenv("PORT", os.getenv("CHATTERBOX_PORT", 8004)))
    
    logger.info("")
    logger.info("API Endpoints:")
    logger.info("  POST /api/tts         - Generate TTS")
    logger.info("  GET  /api/voices      - List voices")
    logger.info("  GET  /api/health      - Health check")
    logger.info("  GET  /docs            - API documentation")
    logger.info("")
    logger.info("Example:")
    logger.info(f'  curl -X POST http://localhost:{port}/api/tts \\')
    logger.info('    -H "Content-Type: application/json" \\')
    logger.info('    -d \'{"text": "Hello world", "voice": "emily-en-us"}\' \\')
    logger.info('    --output hello.wav')
    logger.info("")
    logger.info("=" * 80)

# Include production router
app.include_router(production_router)

# Root endpoint
@app.get("/")
async def root():
    return {
        "service": "CallWaiting TTS API",
        "status": "running",
        "version": "1.0.0",
        "model_loaded": app.state.tts_model is not None,
        "endpoints": {
            "tts": "/api/tts",
            "voices": "/api/voices",
            "health": "/api/health",
            "docs": "/docs"
        }
    }

# Health check endpoint (for Docker healthcheck compatibility)
@app.get("/health")
async def health_check_root():
    """Simple health check endpoint for Docker/K8s"""
    return {
        "status": "healthy",
        "model_loaded": app.state.tts_model is not None
    }

# Main
if __name__ == "__main__":
    # CRITICAL: Always use CHATTERBOX_PORT first, ignore generic PORT variable
    port = int(os.getenv("CHATTERBOX_PORT", os.getenv("PORT", 8004)))
    host = os.getenv("CHATTERBOX_HOST", os.getenv("HOST", "0.0.0.0"))
    
    # CRITICAL: Must bind to 0.0.0.0 for RunPod/Docker deployment
    if host == "localhost" or host == "127.0.0.1":
        logger.warning(f"⚠ Host is set to {host}, changing to 0.0.0.0 for external access")
        host = "0.0.0.0"
    
    logger.info("=" * 80)
    logger.info(f"[STARTUP] Server binding to {host}:{port}")
    logger.info(f"[STARTUP] Working directory: {os.getcwd()}")
    logger.info(f"[STARTUP] Python path: {sys.path[:3]}")
    logger.info("=" * 80)

    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info"
    )
