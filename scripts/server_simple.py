#!/usr/bin/env python3
"""
Simple Chatterbox TTS Server for RunPod
No database dependencies - quick deployment
"""

import os
import logging
from pathlib import Path
from datetime import datetime

import torch
import soundfile as sf
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# Import Chatterbox TTS
try:
    from chatterbox.tts import ChatterboxTTS
except ImportError:
    ChatterboxTTS = None
    logging.error("Chatterbox TTS not installed!")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="Chatterbox TTS API (RunPod Simple)",
    description="Simple TTS server without authentication",
    version="1.0.0"
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global state
tts_model = None

# Request models
class TTSRequest(BaseModel):
    text: str
    format: str = "wav"
    speed: float = 1.0
    temperature: float = 0.8
    exaggeration: float = 1.3

@app.on_event("startup")
async def startup_event():
    """Initialize TTS model on startup"""
    global tts_model
    
    logger.info("=" * 80)
    logger.info("Starting Chatterbox TTS Server (RunPod Simple)")
    logger.info("=" * 80)
    
    # Create directories
    for directory in ['outputs', 'logs', 'hf_cache']:
        Path(directory).mkdir(exist_ok=True)
    
    # Detect device
    if torch.cuda.is_available():
        device = 'cuda'
        logger.info(f"GPU detected: {torch.cuda.get_device_name(0)}")
        logger.info(f"CUDA version: {torch.version.cuda}")
    else:
        device = 'cpu'
        logger.warning("No GPU detected, using CPU (will be slow!)")
    
    # Load TTS model
    if ChatterboxTTS:
        try:
            logger.info(f"Loading Chatterbox TTS model on {device}...")
            tts_model = ChatterboxTTS.from_pretrained(device=device)
            logger.info("✓ TTS model loaded successfully!")
        except Exception as e:
            logger.error(f"Failed to load TTS model: {e}")
            logger.error("Server will start but TTS will not work")
    else:
        logger.error("ChatterboxTTS not available")
    
    logger.info("=" * 80)
    logger.info("Server startup complete!")
    logger.info(f"Device: {device}")
    logger.info(f"Port: 8004")
    logger.info(f"Docs: http://0.0.0.0:8004/docs")
    logger.info("=" * 80)

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "status": "running",
        "service": "Chatterbox TTS API (Simple)",
        "version": "1.0.0",
        "model_loaded": tts_model is not None,
        "device": "cuda" if torch.cuda.is_available() else "cpu",
        "docs": "/docs",
        "endpoints": {
            "health": "/health",
            "tts": "/tts (POST)",
            "simple_tts": "/generate (POST)"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy" if tts_model else "degraded",
        "timestamp": datetime.now().isoformat(),
        "model_loaded": tts_model is not None,
        "device": "cuda" if torch.cuda.is_available() else "cpu"
    }

@app.post("/tts")
async def generate_tts(request: TTSRequest):
    """Generate TTS audio"""
    if not tts_model:
        raise HTTPException(status_code=503, detail="TTS model not loaded")
    
    try:
        logger.info(f"Generating TTS for: {request.text[:50]}...")
        
        # Generate audio
        wav = tts_model.generate(
            text=request.text,
            temperature=request.temperature,
            exaggeration=request.exaggeration
        )
        
        # Apply speed if needed
        if request.speed != 1.0:
            try:
                import librosa
                wav = librosa.effects.time_stretch(wav, rate=1.0 / request.speed)
            except ImportError:
                logger.warning("librosa not available, skipping speed adjustment")
        
        # Save to temporary file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = Path("outputs") / f"tts_{timestamp}.wav"
        sf.write(output_path, wav, 24000)
        
        logger.info(f"Generated audio: {output_path}")
        
        # Return audio
        with open(output_path, "rb") as f:
            audio_data = f.read()
        
        return StreamingResponse(
            iter([audio_data]),
            media_type="audio/wav",
            headers={"Content-Disposition": f"attachment; filename={output_path.name}"}
        )
        
    except Exception as e:
        logger.error(f"TTS generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/generate")
async def simple_generate(text: str):
    """Simple TTS endpoint - just pass text as query parameter"""
    if not tts_model:
        raise HTTPException(status_code=503, detail="TTS model not loaded")
    
    try:
        logger.info(f"Simple generate: {text[:50]}...")
        
        wav = tts_model.generate(text=text)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = Path("outputs") / f"tts_{timestamp}.wav"
        sf.write(output_path, wav, 24000)
        
        with open(output_path, "rb") as f:
            audio_data = f.read()
        
        return StreamingResponse(
            iter([audio_data]),
            media_type="audio/wav"
        )
        
    except Exception as e:
        logger.error(f"Generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.getenv('PORT', 8004))
    host = os.getenv('HOST', '0.0.0.0')
    
    # CRITICAL: Must bind to 0.0.0.0 for RunPod/Docker deployment
    if host == "localhost" or host == "127.0.0.1":
        logger.warning(f"⚠ Host is set to {host}, changing to 0.0.0.0 for external access")
        host = "0.0.0.0"
    
    logger.info("=" * 80)
    logger.info(f"[STARTUP] Binding to {host}:{port}")
    logger.info(f"[STARTUP] Working directory: {os.getcwd()}")
    logger.info(f"[STARTUP] Access via: http://{host}:{port}")
    logger.info(f"[STARTUP] Docs at: http://{host}:{port}/docs")
    logger.info("=" * 80)
    
    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level="info"
    )

