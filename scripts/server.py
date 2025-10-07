#!/usr/bin/env python3
"""
Chatterbox TTS Server with Twilio Integration
Complete FastAPI server for voice agent system with LLM and TTS
"""

import os
import sys
import logging
import asyncio
import base64
import json
from pathlib import Path
from typing import Optional, Dict, Any
from datetime import datetime

import yaml
import torch
import soundfile as sf
import numpy as np
from fastapi import FastAPI, HTTPException, Request, Response, File, UploadFile, Form
from fastapi.responses import StreamingResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import asyncpg
import redis.asyncio as aioredis

# Import Chatterbox TTS
from chatterbox.tts import ChatterboxTTS

# Import our production modules
from auth import APIKeyMiddleware
from api_v1 import router as api_v1_router
from monitoring import router as monitoring_router, set_app_info, set_model_loaded

# LLM clients
try:
    from anthropic import Anthropic
except ImportError:
    Anthropic = None

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None

# Twilio
try:
    from twilio.twiml.voice_response import VoiceResponse, Gather
    from twilio.rest import Client as TwilioClient
except ImportError:
    VoiceResponse = None
    TwilioClient = None

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('logs/server.log')
    ]
)
logger = logging.getLogger(__name__)

# Load configuration
def load_config():
    """Load configuration from config.yaml"""
    config_path = Path("config/config.yaml")
    if not config_path.exists():
        logger.error("config.yaml not found. Run setup script first.")
        sys.exit(1)

    with open(config_path) as f:
        config = yaml.safe_load(f)

    # Override with environment variables
    config['twilio']['account_sid'] = os.getenv('TWILIO_ACCOUNT_SID', config['twilio'].get('account_sid', ''))
    config['twilio']['auth_token'] = os.getenv('TWILIO_AUTH_TOKEN', config['twilio'].get('auth_token', ''))
    config['twilio']['phone_number'] = os.getenv('TWILIO_PHONE_NUMBER', config['twilio'].get('phone_number', ''))

    config['llm']['api_key'] = os.getenv('ANTHROPIC_API_KEY') or os.getenv('OPENAI_API_KEY') or config['llm'].get('api_key', '')

    # Device configuration
    device = os.getenv('CHATTERBOX_DEVICE', config['model'].get('device', 'auto'))
    if device == 'auto':
        if torch.cuda.is_available():
            device = 'cuda'
        elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
            device = 'mps'
        else:
            device = 'cpu'
    config['model']['device'] = device
    
    # Database configuration
    if 'database' not in config:
        config['database'] = {}
    config['database']['host'] = os.getenv('POSTGRES_HOST', config.get('database', {}).get('host', 'localhost'))
    config['database']['port'] = int(os.getenv('POSTGRES_PORT', config.get('database', {}).get('port', 5432)))
    config['database']['database'] = os.getenv('POSTGRES_DB', config.get('database', {}).get('database', 'chatterbox'))
    config['database']['user'] = os.getenv('POSTGRES_USER', config.get('database', {}).get('user', 'postgres'))
    config['database']['password'] = os.getenv('POSTGRES_PASSWORD', config.get('database', {}).get('password', ''))
    
    # Redis configuration
    if 'redis' not in config:
        config['redis'] = {}
    config['redis']['host'] = os.getenv('REDIS_HOST', config.get('redis', {}).get('host', 'localhost'))
    config['redis']['port'] = int(os.getenv('REDIS_PORT', config.get('redis', {}).get('port', 6379)))
    config['redis']['db'] = int(os.getenv('REDIS_DB', config.get('redis', {}).get('db', 0)))

    return config

config = load_config()

# Initialize FastAPI
app = FastAPI(
    title="CallWaiting TTS API",
    description="Production-ready TTS server for voice agents with API key authentication",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS middleware
if config['security']['enable_cors']:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=config['security']['allowed_origins'],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# Store config in app state for access in routes
app.state.config = config

# Global state (legacy, will be moved to app.state)
class AppState:
    """Application state manager"""
    def __init__(self):
        self.tts_model: Optional[ChatterboxTTS] = None
        self.llm_client: Optional[Any] = None
        self.twilio_client: Optional[Any] = None
        self.call_sessions: Dict[str, Dict] = {}  # Track active calls

state = AppState()

# Alias for app.state access
app.state.tts_model = None

# Pydantic models
class TTSRequest(BaseModel):
    text: str
    voice_mode: str = "predefined"  # "predefined" or "clone"
    predefined_voice: Optional[str] = None
    temperature: float = 0.8
    exaggeration: float = 1.3
    cfg_weight: float = 0.5
    seed: int = 0
    speed_factor: float = 1.0
    language: str = "en"
    chunk_size: int = 200
    split_text: bool = True

class OpenAISpeechRequest(BaseModel):
    input: str
    voice: str = "Emily.wav"
    response_format: str = "wav"
    speed: float = 1.0
    seed: Optional[int] = None

class LLMRequest(BaseModel):
    prompt: str
    max_tokens: int = 150
    temperature: float = 0.7

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize models, database, and clients on startup"""
    logger.info("Starting CallWaiting TTS API Server...")

    # Create necessary directories
    for directory in ['outputs', 'logs', 'model_cache']:
        Path(directory).mkdir(exist_ok=True)
    
    # Initialize database connection pool (OPTIONAL - graceful degradation)
    try:
        db_config = config.get('database', {})
        if db_config.get('host') and db_config.get('password'):
            dsn = f"postgresql://{db_config['user']}:{db_config['password']}@{db_config['host']}:{db_config['port']}/{db_config['database']}"
            
            app.state.pg = await asyncpg.create_pool(
                dsn=dsn,
                min_size=2,
                max_size=10,
                command_timeout=60,
                timeout=5  # 5 second timeout for connection attempts
            )
            logger.info("✓ PostgreSQL connection pool initialized")
        else:
            logger.warning("⚠ Database config incomplete, running without database")
            app.state.pg = None
    except Exception as e:
        logger.warning(f"Database unavailable, continuing without authentication: {e}")
        app.state.pg = None
    
    # Initialize Redis connection (OPTIONAL - graceful degradation)
    try:
        redis_config = config.get('redis', {})
        if redis_config.get('host'):
            app.state.redis = await aioredis.from_url(
                f"redis://{redis_config['host']}:{redis_config['port']}/{redis_config['db']}",
                encoding="utf-8",
                decode_responses=True,
                socket_timeout=5,
                socket_connect_timeout=5
            )
            # Test connection
            await app.state.redis.ping()
            logger.info("✓ Redis connection initialized")
        else:
            logger.warning("⚠ Redis config incomplete, running without cache")
            app.state.redis = None
    except Exception as e:
        logger.warning(f"Redis unavailable, continuing without rate limiting: {e}")
        app.state.redis = None
    
    # Add authentication middleware (only if database AND redis are available)
    if app.state.pg and app.state.redis:
        app.add_middleware(APIKeyMiddleware, pool=app.state.pg, redis_client=app.state.redis)
        logger.info("✓ API key authentication middleware enabled")
    else:
        logger.warning("⚠ Authentication middleware disabled - running in open mode")
        logger.warning("⚠ All endpoints accessible without API keys")

    # Initialize TTS model
    try:
        logger.info(f"Loading Chatterbox TTS model on {config['model']['device']}...")
        state.tts_model = ChatterboxTTS.from_pretrained(device=config['model']['device'])
        app.state.tts_model = state.tts_model  # Also store in app.state for API v1
        set_model_loaded(True)
        logger.info("✓ TTS model loaded successfully")
    except Exception as e:
        logger.error(f"Failed to load TTS model: {e}")
        logger.error("Server will start but TTS will not work until model is loaded")
        set_model_loaded(False)

    # Initialize LLM client
    try:
        provider = config['llm']['provider']
        api_key = config['llm']['api_key']

        if provider == 'anthropic' and Anthropic and api_key:
            state.llm_client = Anthropic(api_key=api_key)
            logger.info("✓ Anthropic LLM client initialized")
        elif provider == 'openai' and OpenAI and api_key:
            state.llm_client = OpenAI(api_key=api_key)
            logger.info("✓ OpenAI LLM client initialized")
        else:
            logger.warning("LLM client not initialized (missing API key or provider)")
    except Exception as e:
        logger.error(f"Failed to initialize LLM client: {e}")

    # Initialize Twilio client
    try:
        if TwilioClient and config['twilio']['account_sid'] and config['twilio']['auth_token']:
            state.twilio_client = TwilioClient(
                config['twilio']['account_sid'],
                config['twilio']['auth_token']
            )
            logger.info("✓ Twilio client initialized")
        else:
            logger.warning("Twilio client not initialized (missing credentials)")
    except Exception as e:
        logger.error(f"Failed to initialize Twilio client: {e}")

    # Set application info for monitoring
    set_app_info(
        version="1.0.0",
        environment=os.getenv("ENVIRONMENT", "production"),
        device=config['model']['device']
    )
    
    logger.info("=" * 80)
    logger.info("Server startup complete")
    logger.info(f"Device: {config['model']['device']}")
    logger.info(f"Port: {config['server']['port']}")
    logger.info(f"Database: {'✓ Connected' if app.state.pg else '✗ Not connected'}")
    logger.info(f"Redis: {'✓ Connected' if app.state.redis else '✗ Not connected'}")
    logger.info(f"TTS Model: {'✓ Loaded' if state.tts_model else '✗ Not loaded'}")
    logger.info("=" * 80)


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down server...")
    
    # Close database pool
    if hasattr(app.state, 'pg') and app.state.pg:
        await app.state.pg.close()
        logger.info("✓ Database pool closed")
    
    # Close Redis connection
    if hasattr(app.state, 'redis') and app.state.redis:
        await app.state.redis.close()
        logger.info("✓ Redis connection closed")
    
    logger.info("Shutdown complete")

# Health check endpoints (no auth required)
@app.get("/")
async def root():
    """Health check and server info"""
    return {
        "status": "running",
        "service": "CallWaiting TTS API",
        "version": "1.0.0",
        "model_loaded": state.tts_model is not None,
        "llm_available": state.llm_client is not None,
        "twilio_available": state.twilio_client is not None,
        "database_connected": hasattr(app.state, 'pg') and app.state.pg is not None,
        "redis_connected": hasattr(app.state, 'redis') and app.state.redis is not None,
        "device": config['model']['device'],
        "docs": "/docs",
        "api_v1": "/v1"
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    health = {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "components": {
            "tts_model": state.tts_model is not None,
            "database": hasattr(app.state, 'pg') and app.state.pg is not None,
            "redis": hasattr(app.state, 'redis') and app.state.redis is not None,
            "llm_client": state.llm_client is not None,
            "twilio_client": state.twilio_client is not None
        },
        "config": {
            "device": config['model']['device'],
            "llm_provider": config['llm']['provider']
        }
    }

    warnings = []
    if not state.tts_model:
        warnings.append("TTS model not loaded")
    if not hasattr(app.state, 'pg') or not app.state.pg:
        warnings.append("Database not connected")
    if not hasattr(app.state, 'redis') or not app.state.redis:
        warnings.append("Redis not connected")
    
    if warnings:
        health["status"] = "degraded"
        health["warnings"] = warnings

    return health


# Include production API routes
app.include_router(api_v1_router, tags=["API v1"])
app.include_router(monitoring_router, tags=["Monitoring"])

# TTS Generation Endpoint
@app.post("/tts")
async def generate_tts(request: TTSRequest):
    """Generate TTS audio from text"""
    if not state.tts_model:
        raise HTTPException(status_code=503, detail="TTS model not loaded")

    try:
        logger.info(f"Generating TTS for: {request.text[:50]}...")

        # Load reference audio if voice cloning
        reference_audio = None
        if request.voice_mode == "clone" and request.predefined_voice:
            voice_path = Path("voices") / request.predefined_voice
            if voice_path.exists():
                reference_audio = str(voice_path)
            else:
                logger.warning(f"Voice file not found: {voice_path}, using default")

        # Generate audio
        wav = state.tts_model.generate(
            text=request.text,
            exaggeration=request.exaggeration,
            temperature=request.temperature,
            cfg_weight=request.cfg_weight,
            seed=request.seed if request.seed > 0 else None,
            reference_audio=reference_audio
        )

        # Apply speed factor if needed
        if request.speed_factor != 1.0:
            import librosa
            wav = librosa.effects.time_stretch(wav, rate=1.0 / request.speed_factor)

        # Save to temporary file
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = Path("outputs") / f"tts_{timestamp}.wav"
        sf.write(output_path, wav, config['audio_output']['sample_rate'])

        logger.info(f"Generated audio saved to {output_path}")

        # Return audio file
        return StreamingResponse(
            iter([open(output_path, "rb").read()]),
            media_type="audio/wav",
            headers={"Content-Disposition": f"attachment; filename={output_path.name}"}
        )

    except Exception as e:
        logger.error(f"TTS generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# OpenAI-compatible endpoint
@app.post("/v1/audio/speech")
async def openai_speech(request: OpenAISpeechRequest):
    """OpenAI-compatible TTS endpoint"""
    if not state.tts_model:
        raise HTTPException(status_code=503, detail="TTS model not loaded")

    try:
        # Convert to internal format
        tts_request = TTSRequest(
            text=request.input,
            predefined_voice=request.voice,
            speed_factor=request.speed,
            seed=request.seed or 0
        )

        return await generate_tts(tts_request)

    except Exception as e:
        logger.error(f"OpenAI speech generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# LLM endpoint
@app.post("/llm")
async def generate_llm_response(request: LLMRequest):
    """Generate LLM response"""
    if not state.llm_client:
        raise HTTPException(status_code=503, detail="LLM client not initialized")

    try:
        provider = config['llm']['provider']

        if provider == 'anthropic':
            response = state.llm_client.messages.create(
                model=config['llm']['model'],
                max_tokens=request.max_tokens,
                temperature=request.temperature,
                messages=[{"role": "user", "content": request.prompt}]
            )
            text = response.content[0].text

        elif provider == 'openai':
            response = state.llm_client.chat.completions.create(
                model=config['llm']['model'],
                max_tokens=request.max_tokens,
                temperature=request.temperature,
                messages=[{"role": "user", "content": request.prompt}]
            )
            text = response.choices[0].message.content

        else:
            raise HTTPException(status_code=500, detail="Unknown LLM provider")

        return {"response": text}

    except Exception as e:
        logger.error(f"LLM generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Twilio webhook endpoints
@app.post("/twilio/voice")
async def twilio_voice_webhook(request: Request):
    """Handle incoming Twilio voice calls"""
    if not VoiceResponse:
        raise HTTPException(status_code=503, detail="Twilio not available")

    form_data = await request.form()
    call_sid = form_data.get('CallSid')
    from_number = form_data.get('From')

    logger.info(f"Incoming call from {from_number}, SID: {call_sid}")

    # Initialize call session
    state.call_sessions[call_sid] = {
        'from': from_number,
        'started_at': datetime.now().isoformat(),
        'messages': []
    }

    # Create TwiML response
    response = VoiceResponse()
    response.say("Hello! I'm your AI assistant. How can I help you today?")

    # Gather user input
    gather = Gather(
        input='speech',
        action='/twilio/process-speech',
        method='POST',
        speech_timeout='auto',
        language='en-US'
    )
    response.append(gather)

    # Fallback
    response.say("I didn't hear anything. Please call back.")

    return Response(content=str(response), media_type="application/xml")

@app.post("/twilio/process-speech")
async def process_speech(request: Request):
    """Process speech input from Twilio"""
    if not VoiceResponse:
        raise HTTPException(status_code=503, detail="Twilio not available")

    form_data = await request.form()
    call_sid = form_data.get('CallSid')
    speech_result = form_data.get('SpeechResult', '')

    logger.info(f"Call {call_sid}: User said: {speech_result}")

    # Get LLM response
    try:
        if state.llm_client:
            llm_response = await generate_llm_response(
                LLMRequest(prompt=speech_result)
            )
            response_text = llm_response['response']
        else:
            response_text = f"You said: {speech_result}"

        # Store in session
        if call_sid in state.call_sessions:
            state.call_sessions[call_sid]['messages'].append({
                'user': speech_result,
                'assistant': response_text,
                'timestamp': datetime.now().isoformat()
            })

        # Generate TTS
        if state.tts_model:
            wav = state.tts_model.generate(
                text=response_text,
                exaggeration=1.3,
                temperature=0.8
            )

            # Save audio for Twilio
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            audio_path = Path("outputs") / f"call_{call_sid}_{timestamp}.wav"
            sf.write(audio_path, wav, config['audio_output']['sample_rate'])

            logger.info(f"Generated response audio: {audio_path}")

        # Create TwiML response
        response = VoiceResponse()
        response.say(response_text)

        # Continue conversation
        gather = Gather(
            input='speech',
            action='/twilio/process-speech',
            method='POST',
            speech_timeout='auto',
            language='en-US'
        )
        response.append(gather)

        return Response(content=str(response), media_type="application/xml")

    except Exception as e:
        logger.error(f"Error processing speech: {e}")
        response = VoiceResponse()
        response.say("Sorry, I encountered an error. Please try again.")
        return Response(content=str(response), media_type="application/xml")

@app.post("/twilio/status")
async def twilio_status_callback(request: Request):
    """Handle Twilio status callbacks"""
    form_data = await request.form()
    call_sid = form_data.get('CallSid')
    call_status = form_data.get('CallStatus')

    logger.info(f"Call {call_sid} status: {call_status}")

    # Clean up session on call end
    if call_status in ['completed', 'failed', 'busy', 'no-answer']:
        if call_sid in state.call_sessions:
            session = state.call_sessions.pop(call_sid)
            logger.info(f"Call session ended: {session}")

    return {"status": "ok"}

# Voice cloning endpoint
@app.post("/upload-voice")
async def upload_voice(
    voice_name: str = Form(...),
    audio_file: UploadFile = File(...)
):
    """Upload reference audio for voice cloning"""
    try:
        # Save uploaded file
        voice_path = Path("voices") / f"{voice_name}.wav"
        with open(voice_path, "wb") as f:
            content = await audio_file.read()
            f.write(content)

        logger.info(f"Voice uploaded: {voice_path}")

        return {
            "status": "success",
            "voice_name": voice_name,
            "path": str(voice_path)
        }

    except Exception as e:
        logger.error(f"Voice upload failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# List available voices
@app.get("/voices")
async def list_voices():
    """List available voice files"""
    voices_dir = Path("voices")
    voices = [f.name for f in voices_dir.glob("*.wav")]
    return {"voices": voices}

# Main entry point
if __name__ == "__main__":
    port = int(os.getenv('CHATTERBOX_PORT', config['server']['port']))
    host = os.getenv('CHATTERBOX_HOST', config['server']['host'])
    
    # CRITICAL: Must bind to 0.0.0.0 for RunPod/Docker deployment
    if host == "localhost" or host == "127.0.0.1":
        logger.warning(f"⚠ Host is set to {host}, changing to 0.0.0.0 for external access")
        host = "0.0.0.0"
    
    logger.info(f"Starting server on {host}:{port}")

    uvicorn.run(
        app,
        host=host,
        port=port,
        log_level=config['server']['log_level'],
        workers=config['server'].get('workers', 1)
    )
