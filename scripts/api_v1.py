#!/usr/bin/env python3
"""
Production API v1 Endpoints
Provides stable, versioned API for TTS and voice management
"""

import io
import uuid
import logging
import asyncio
from typing import Optional, Dict, List, AsyncIterator
from pathlib import Path

from fastapi import APIRouter, Request, HTTPException, Response
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
import asyncpg
import soundfile as sf
import numpy as np

logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/v1")


# ============================================================================
# Request/Response Models
# ============================================================================

class TTSRequest(BaseModel):
    """Request model for TTS generation"""
    text: str = Field(..., description="Text to synthesize (max 1200 chars)", max_length=1200)
    voice_id: str = Field(..., description="Voice ID from catalog")
    format: str = Field(default="wav", description="Audio format: wav, mp3, pcm16")
    speed: float = Field(default=1.0, ge=0.5, le=2.0, description="Playback speed multiplier")
    seed: Optional[int] = Field(default=None, description="Random seed for reproducibility")


class VoiceResponse(BaseModel):
    """Response model for voice catalog"""
    id: str
    slug: str
    display_name: str
    description: Optional[str]
    language: str
    gender: Optional[str]
    sample_url: Optional[str]
    is_public: bool


class UsageResponse(BaseModel):
    """Response model for usage statistics"""
    day: str
    requests: int
    characters: int
    avg_latency_ms: float


# ============================================================================
# Helper Functions
# ============================================================================

async def get_voice_by_id(conn: asyncpg.Connection, voice_id: str, tenant_id: Optional[uuid.UUID] = None) -> Optional[Dict]:
    """
    Get voice parameters by ID, checking access permissions.
    
    Returns voice if:
    - Voice is public, OR
    - Voice is owned by the requesting tenant
    """
    try:
        voice_uuid = uuid.UUID(voice_id)
    except ValueError:
        return None
    
    row = await conn.fetchrow("""
        SELECT id, slug, display_name, language, params, audio_file_path, owner_tenant, is_public
        FROM voices
        WHERE id = $1 AND status = 'active'
    """, voice_uuid)
    
    if not row:
        return None
    
    # Check access permissions
    if not row["is_public"]:
        if not tenant_id or row["owner_tenant"] != tenant_id:
            logger.warning(f"Access denied to private voice {voice_id} for tenant {tenant_id}")
            return None
    
    return dict(row)


def chunk_text(text: str, max_length: int = 200) -> List[str]:
    """
    Split text into chunks for long-form synthesis.
    Splits on sentence boundaries when possible.
    """
    if len(text) <= max_length:
        return [text]
    
    chunks = []
    current_chunk = ""
    
    # Split on sentence boundaries
    sentences = text.replace("! ", "!|").replace("? ", "?|").replace(". ", ".|").split("|")
    
    for sentence in sentences:
        if len(current_chunk) + len(sentence) <= max_length:
            current_chunk += sentence
        else:
            if current_chunk:
                chunks.append(current_chunk.strip())
            current_chunk = sentence
    
    if current_chunk:
        chunks.append(current_chunk.strip())
    
    return chunks


async def synthesize_audio(
    tts_model,
    text: str,
    voice_params: Dict,
    reference_audio: Optional[str] = None,
    speed: float = 1.0,
    seed: Optional[int] = None
) -> np.ndarray:
    """
    Synthesize audio using Chatterbox TTS model.
    
    Args:
        tts_model: The loaded ChatterboxTTS model
        text: Text to synthesize
        voice_params: Voice generation parameters (temperature, exaggeration, cfg_weight)
        reference_audio: Path to reference audio file for voice cloning
        speed: Playback speed multiplier
        seed: Random seed for reproducibility
    
    Returns:
        Audio waveform as numpy array
    """
    params = voice_params.get("params", {}) if isinstance(voice_params, dict) else {}
    
    # Generate audio
    wav = await asyncio.to_thread(
        tts_model.generate,
        text=text,
        temperature=params.get("temperature", 0.8),
        exaggeration=params.get("exaggeration", 1.3),
        cfg_weight=params.get("cfg_weight", 0.5),
        seed=seed,
        reference_audio=reference_audio
    )
    
    # Apply speed adjustment if needed
    if speed != 1.0:
        try:
            import librosa
            wav = librosa.effects.time_stretch(wav, rate=1.0 / speed)
        except ImportError:
            logger.warning("librosa not available, skipping speed adjustment")
    
    return wav


async def audio_stream_generator(
    tts_model,
    text: str,
    voice: Dict,
    format: str,
    speed: float,
    seed: Optional[int],
    sample_rate: int = 24000
) -> AsyncIterator[bytes]:
    """
    Generate audio stream in chunks for large texts.
    
    Yields audio chunks as they're generated to reduce latency.
    """
    # Get reference audio path if available
    reference_audio = voice.get("audio_file_path")
    if reference_audio:
        audio_path = Path(reference_audio)
        if not audio_path.exists():
            # Try in voices directory
            audio_path = Path("voices") / Path(reference_audio).name
            if not audio_path.exists():
                reference_audio = None
            else:
                reference_audio = str(audio_path)
    
    # Chunk long text
    text_chunks = chunk_text(text, max_length=200)
    
    # For WAV format with multiple chunks, we need to handle headers specially
    if format == "wav" and len(text_chunks) > 1:
        logger.warning("Multiple chunks with WAV format - concatenating audio first")
        # Generate all audio first, then encode
        all_audio = []
        for chunk in text_chunks:
            wav = await synthesize_audio(
                tts_model, chunk, voice, reference_audio, speed, seed
            )
            all_audio.append(wav)
        
        # Concatenate
        full_audio = np.concatenate(all_audio)
        
        # Encode as WAV
        buffer = io.BytesIO()
        sf.write(buffer, full_audio, sample_rate, format='WAV')
        buffer.seek(0)
        yield buffer.read()
    
    elif format == "pcm16":
        # PCM16 can be streamed directly
        for chunk in text_chunks:
            wav = await synthesize_audio(
                tts_model, chunk, voice, reference_audio, speed, seed
            )
            # Convert to PCM16
            pcm_data = (wav * 32767).astype(np.int16).tobytes()
            yield pcm_data
    
    elif format == "mp3":
        # MP3 requires full audio (or complex streaming)
        all_audio = []
        for chunk in text_chunks:
            wav = await synthesize_audio(
                tts_model, chunk, voice, reference_audio, speed, seed
            )
            all_audio.append(wav)
        
        full_audio = np.concatenate(all_audio)
        
        # Convert to MP3 using pydub
        try:
            from pydub import AudioSegment
            
            # Save to WAV buffer first
            wav_buffer = io.BytesIO()
            sf.write(wav_buffer, full_audio, sample_rate, format='WAV')
            wav_buffer.seek(0)
            
            # Convert to MP3
            audio_segment = AudioSegment.from_wav(wav_buffer)
            mp3_buffer = io.BytesIO()
            audio_segment.export(mp3_buffer, format="mp3", bitrate="128k")
            mp3_buffer.seek(0)
            yield mp3_buffer.read()
        except ImportError:
            logger.error("pydub not available for MP3 encoding")
            raise HTTPException(status_code=500, detail="MP3 encoding not available")
    
    else:
        # Default to WAV single chunk
        wav = await synthesize_audio(
            tts_model, text, voice, reference_audio, speed, seed
        )
        buffer = io.BytesIO()
        sf.write(buffer, wav, sample_rate, format='WAV')
        buffer.seek(0)
        yield buffer.read()


# ============================================================================
# API Endpoints
# ============================================================================

@router.get("/health")
async def health_check():
    """Health check endpoint (no auth required)"""
    return {
        "status": "healthy",
        "version": "1.0.0",
        "service": "CallWaiting TTS API"
    }


@router.post("/tts")
async def generate_tts(request: Request, payload: TTSRequest):
    """
    Generate TTS audio from text.
    
    Supports streaming for large texts and multiple audio formats.
    Requires valid API key in x-api-key header.
    
    Returns:
        Audio stream in requested format (WAV, MP3, or PCM16)
    """
    # Get TTS model from app state
    tts_model = request.app.state.tts_model
    if not tts_model:
        raise HTTPException(status_code=503, detail="TTS model not loaded")
    
    # Track text length for usage metering
    request.state.text_length = len(payload.text)
    
    # Get voice from database
    try:
        async with request.app.state.pg.acquire() as conn:
            voice = await get_voice_by_id(conn, payload.voice_id, request.state.tenant_id)
    except Exception as e:
        logger.error(f"Database error getting voice: {e}")
        raise HTTPException(status_code=503, detail="Database error")
    
    if not voice:
        raise HTTPException(status_code=404, detail="Voice not found or access denied")
    
    # Track voice_id for logging
    request.state.voice_id = uuid.UUID(payload.voice_id)
    
    # Determine media type
    media_types = {
        "wav": "audio/wav",
        "mp3": "audio/mpeg",
        "pcm16": "audio/L16; rate=24000; channels=1"
    }
    media_type = media_types.get(payload.format, "audio/wav")
    
    # Generate and stream audio
    try:
        sample_rate = request.app.state.config.get("audio_output", {}).get("sample_rate", 24000)
        
        return StreamingResponse(
            audio_stream_generator(
                tts_model,
                payload.text,
                voice,
                payload.format,
                payload.speed,
                payload.seed,
                sample_rate
            ),
            media_type=media_type,
            headers={
                "X-Voice-ID": payload.voice_id,
                "X-Text-Length": str(len(payload.text)),
                "Content-Disposition": f'attachment; filename="tts_{payload.voice_id[:8]}.{payload.format}"'
            }
        )
    except Exception as e:
        logger.error(f"TTS generation error: {e}")
        raise HTTPException(status_code=500, detail=f"TTS generation failed: {str(e)}")


@router.get("/voices", response_model=List[VoiceResponse])
async def list_voices(request: Request):
    """
    List available voices from catalog.
    
    Returns:
    - All public voices
    - Private voices owned by the requesting tenant
    """
    try:
        async with request.app.state.pg.acquire() as conn:
            # Get public voices + tenant private voices
            tenant_id = getattr(request.state, "tenant_id", None)
            
            if tenant_id:
                rows = await conn.fetch("""
                    SELECT id, slug, display_name, description, language, gender, 
                           sample_url, is_public
                    FROM voices
                    WHERE status = 'active' AND (is_public = TRUE OR owner_tenant = $1)
                    ORDER BY display_name
                """, tenant_id)
            else:
                rows = await conn.fetch("""
                    SELECT id, slug, display_name, description, language, gender, 
                           sample_url, is_public
                    FROM voices
                    WHERE status = 'active' AND is_public = TRUE
                    ORDER BY display_name
                """)
            
            return [
                VoiceResponse(
                    id=str(row["id"]),
                    slug=row["slug"],
                    display_name=row["display_name"],
                    description=row["description"],
                    language=row["language"],
                    gender=row["gender"],
                    sample_url=row["sample_url"],
                    is_public=row["is_public"]
                )
                for row in rows
            ]
    except Exception as e:
        logger.error(f"Database error listing voices: {e}")
        raise HTTPException(status_code=503, detail="Database error")


@router.get("/voices/{voice_id}", response_model=VoiceResponse)
async def get_voice(request: Request, voice_id: str):
    """
    Get details for a specific voice.
    
    Returns voice if public or owned by requesting tenant.
    """
    try:
        async with request.app.state.pg.acquire() as conn:
            voice = await get_voice_by_id(conn, voice_id, request.state.tenant_id)
    except Exception as e:
        logger.error(f"Database error getting voice: {e}")
        raise HTTPException(status_code=503, detail="Database error")
    
    if not voice:
        raise HTTPException(status_code=404, detail="Voice not found or access denied")
    
    return VoiceResponse(
        id=str(voice["id"]),
        slug=voice["slug"],
        display_name=voice["display_name"],
        description=None,  # Not in our query
        language=voice["language"],
        gender=None,  # Not in our query
        sample_url=None,  # Not in our query
        is_public=voice["is_public"]
    )


@router.get("/usage", response_model=List[UsageResponse])
async def get_usage(request: Request, days: int = 7):
    """
    Get usage statistics for the requesting API key.
    
    Args:
        days: Number of days to retrieve (default 7, max 90)
    
    Returns:
        Daily usage statistics including requests, characters, and latency
    """
    if days > 90:
        days = 90
    
    api_key_id = request.state.api_key_id
    
    try:
        async with request.app.state.pg.acquire() as conn:
            rows = await conn.fetch("""
                SELECT
                    day,
                    requests,
                    chars,
                    ROUND(ms_synth::NUMERIC / NULLIF(requests, 0), 2) AS avg_latency_ms
                FROM usage_counters
                WHERE api_key_id = $1 AND day >= CURRENT_DATE - $2::INTEGER
                ORDER BY day DESC
            """, api_key_id, days)
            
            return [
                UsageResponse(
                    day=row["day"].isoformat(),
                    requests=row["requests"],
                    characters=row["chars"],
                    avg_latency_ms=float(row["avg_latency_ms"] or 0)
                )
                for row in rows
            ]
    except Exception as e:
        logger.error(f"Database error getting usage: {e}")
        raise HTTPException(status_code=503, detail="Database error")


@router.get("/auth/verify")
async def verify_auth(request: Request):
    """
    Verify API key and return key information.
    
    Useful for testing authentication.
    """
    return {
        "valid": True,
        "api_key_id": str(request.state.api_key_id),
        "api_key_name": request.state.api_key_name,
        "tenant_id": str(request.state.tenant_id) if request.state.tenant_id else None,
        "scopes": request.state.scopes
    }

