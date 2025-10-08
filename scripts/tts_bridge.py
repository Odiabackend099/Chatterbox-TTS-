#!/usr/bin/env python3
"""
TTS Bridge Service
==================
A lightweight FastAPI proxy that sits between n8n/webhooks and your RunPod TTS API.

Purpose:
- Accept simple POST /tts requests with text + voice_id
- Forward to your TTS service with proper auth
- Return MP3 binary audio

Usage:
    # Load environment variables
    export $(cat .env.tts | xargs)
    
    # Run the bridge
    python scripts/tts_bridge.py
    
    # Or with uvicorn directly
    uvicorn scripts.tts_bridge:app --host 0.0.0.0 --port 7070

Environment Variables Required:
    TTS_BASE_URL      - Your TTS service endpoint
    TTS_API_KEY       - API key for TTS service
    DEFAULT_VOICE_ID  - Fallback voice (optional, default: naija_female)
    TTS_BRIDGE_PORT   - Port to run on (optional, default: 7070)
    TTS_BRIDGE_HOST   - Host to bind to (optional, default: 0.0.0.0)
"""

import os
import sys
import httpx
from fastapi import FastAPI, Form, Response, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Validate required environment variables
required_vars = ["TTS_BASE_URL", "TTS_API_KEY"]
missing_vars = [var for var in required_vars if not os.getenv(var)]
if missing_vars:
    logger.error(f"Missing required environment variables: {', '.join(missing_vars)}")
    logger.error("Please set these variables in .env.tts or export them")
    sys.exit(1)

# Load configuration from environment
TTS_BASE_URL = os.environ["TTS_BASE_URL"].rstrip("/")
TTS_API_KEY = os.environ["TTS_API_KEY"]
DEFAULT_VOICE_ID = os.getenv("DEFAULT_VOICE_ID", "naija_female")
TTS_BRIDGE_PORT = int(os.getenv("TTS_BRIDGE_PORT", "7070"))
TTS_BRIDGE_HOST = os.getenv("TTS_BRIDGE_HOST", "0.0.0.0")

logger.info(f"TTS Bridge configured:")
logger.info(f"  - TTS_BASE_URL: {TTS_BASE_URL}")
logger.info(f"  - DEFAULT_VOICE_ID: {DEFAULT_VOICE_ID}")
logger.info(f"  - Bridge will run on: {TTS_BRIDGE_HOST}:{TTS_BRIDGE_PORT}")

# Initialize FastAPI app
app = FastAPI(
    title="TTS Bridge Service",
    description="Lightweight proxy for RunPod TTS API",
    version="1.0.0"
)

# Enable CORS for all origins (adjust for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def root():
    """Root endpoint with service information."""
    return {
        "service": "TTS Bridge",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "tts": "/tts (POST)",
            "docs": "/docs"
        }
    }


@app.get("/health")
def health():
    """Health check endpoint."""
    return {
        "status": "ok",
        "tts_base_url": TTS_BASE_URL,
        "default_voice": DEFAULT_VOICE_ID
    }


@app.post("/tts")
async def tts(text: str = Form(...), voice_id: str = Form(None)):
    """
    Synthesize speech from text.
    
    Args:
        text: Text to synthesize (required)
        voice_id: Voice ID to use (optional, defaults to DEFAULT_VOICE_ID)
    
    Returns:
        MP3 audio binary
    
    Example curl:
        curl -X POST "http://localhost:7070/tts" \
          -F "text=Hello from Nigeria!" \
          -F "voice_id=naija_female" \
          --output hello.mp3
    """
    voice = voice_id or DEFAULT_VOICE_ID
    url = f"{TTS_BASE_URL}/synthesize"
    headers = {"Authorization": f"Bearer {TTS_API_KEY}"}
    data = {"text": text, "voice_id": voice}
    
    logger.info(f"TTS request: text='{text[:50]}...' voice={voice}")
    
    try:
        # Call TTS service with streaming response
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.post(url, headers=headers, data=data)
            
            if resp.status_code != 200:
                logger.error(f"TTS service error: {resp.status_code} - {resp.text}")
                return Response(
                    content=resp.content,
                    status_code=resp.status_code,
                    media_type="application/json"
                )
            
            logger.info(f"TTS successful: {len(resp.content)} bytes")
            return Response(
                content=resp.content,
                media_type="audio/mpeg",
                headers={
                    "Content-Disposition": f'attachment; filename="tts_{voice}.mp3"'
                }
            )
    
    except httpx.TimeoutException:
        logger.error("TTS service timeout")
        raise HTTPException(status_code=504, detail="TTS service timeout")
    
    except httpx.ConnectError:
        logger.error(f"Cannot connect to TTS service at {TTS_BASE_URL}")
        raise HTTPException(
            status_code=503,
            detail=f"Cannot connect to TTS service. Check TTS_BASE_URL: {TTS_BASE_URL}"
        )
    
    except Exception as e:
        logger.error(f"TTS error: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"TTS error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    logger.info(f"Starting TTS Bridge on {TTS_BRIDGE_HOST}:{TTS_BRIDGE_PORT}")
    uvicorn.run(app, host=TTS_BRIDGE_HOST, port=TTS_BRIDGE_PORT)

