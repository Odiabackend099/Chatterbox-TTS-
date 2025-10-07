"""
Production TTS API - WORKS OUT OF THE BOX
No setup required, no voice files needed
"""

import time
import logging
import uuid
from typing import Optional
from fastapi import APIRouter, HTTPException, Request, Response
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import soundfile as sf
import io

from voice_manager import get_voice_manager

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["Production TTS"])

class TTSRequestProduction(BaseModel):
    text: str
    voice: Optional[str] = None  # Voice slug, e.g., "emily-en-us"
    format: str = "wav"  # wav|mp3|pcm16
    temperature: Optional[float] = None
    exaggeration: Optional[float] = None
    cfg_weight: Optional[float] = None
    speed_factor: Optional[float] = None

class VoiceListResponse(BaseModel):
    voices: list
    total: int

@router.post("/tts", summary="Generate TTS (Production)")
async def generate_tts_production(request: Request, payload: TTSRequestProduction):
    """
    Generate TTS audio - PRODUCTION READY

    Works immediately with default voices, no setup required.

    Example:
    ```json
    {
        "text": "Hello world!",
        "voice": "emily-en-us",
        "format": "wav"
    }
    ```
    """
    request_id = str(uuid.uuid4())
    start_time = time.time()

    # Validate input
    if not payload.text or len(payload.text.strip()) == 0:
        raise HTTPException(status_code=400, detail="Text cannot be empty")

    if len(payload.text) > 2000:
        raise HTTPException(status_code=400, detail="Text too long (max 2000 characters)")

    # Get TTS model from app state
    if not hasattr(request.app.state, 'tts_model') or request.app.state.tts_model is None:
        raise HTTPException(status_code=503, detail="TTS model not loaded")

    tts_model = request.app.state.tts_model

    # Get voice manager
    voice_manager = get_voice_manager()

    # Get voice parameters
    voice_slug = payload.voice or voice_manager.get_default_voice()
    voice_params = voice_manager.get_voice_params(voice_slug)

    # Override with request parameters if provided
    if payload.temperature is not None:
        voice_params['temperature'] = payload.temperature
    if payload.exaggeration is not None:
        voice_params['exaggeration'] = payload.exaggeration
    if payload.cfg_weight is not None:
        voice_params['cfg_weight'] = payload.cfg_weight
    if payload.speed_factor is not None:
        voice_params['speed_factor'] = payload.speed_factor

    logger.info(f"[{request_id}] Generating TTS: voice={voice_slug}, text_len={len(payload.text)}")

    try:
        # Generate audio using Chatterbox TTS
        wav = tts_model.generate(
            text=payload.text,
            exaggeration=voice_params['exaggeration'],
            temperature=voice_params['temperature'],
            cfg_weight=voice_params['cfg_weight']
        )

        # Apply speed factor if needed
        if voice_params['speed_factor'] != 1.0:
            import librosa
            wav = librosa.effects.time_stretch(wav, rate=1.0 / voice_params['speed_factor'])

        # Convert to requested format
        if payload.format == "wav":
            # Create WAV file in memory
            import numpy as np
            buffer = io.BytesIO()
            # Ensure wav is float32 numpy array
            if not isinstance(wav, np.ndarray):
                wav = np.array(wav, dtype=np.float32)
            sf.write(buffer, wav, 24000, format='WAV')
            buffer.seek(0)
            media_type = "audio/wav"

        elif payload.format == "pcm16":
            # Raw PCM16 for telephony
            import numpy as np
            pcm = (wav * 32767).astype(np.int16)
            buffer = io.BytesIO(pcm.tobytes())
            buffer.seek(0)
            media_type = "audio/L16; rate=24000; channels=1"

        elif payload.format == "mp3":
            # Convert to MP3 (requires pydub + ffmpeg)
            try:
                from pydub import AudioSegment
                import numpy as np

                # Convert to AudioSegment
                pcm = (wav * 32767).astype(np.int16)
                audio_segment = AudioSegment(
                    pcm.tobytes(),
                    frame_rate=24000,
                    sample_width=2,
                    channels=1
                )

                # Export as MP3
                buffer = io.BytesIO()
                audio_segment.export(buffer, format="mp3", bitrate="128k")
                buffer.seek(0)
                media_type = "audio/mpeg"

            except Exception as e:
                logger.error(f"MP3 conversion failed: {e}, falling back to WAV")
                import numpy as np
                buffer = io.BytesIO()
                if not isinstance(wav, np.ndarray):
                    wav = np.array(wav, dtype=np.float32)
                sf.write(buffer, wav, 24000, format='WAV')
                buffer.seek(0)
                media_type = "audio/wav"

        else:
            raise HTTPException(status_code=400, detail=f"Unsupported format: {payload.format}")

        duration_ms = int((time.time() - start_time) * 1000)
        audio_duration = len(wav) / 24000

        logger.info(f"[{request_id}] Generated {audio_duration:.2f}s audio in {duration_ms}ms")

        # Return streaming response
        return StreamingResponse(
            buffer,
            media_type=media_type,
            headers={
                "X-Request-ID": request_id,
                "X-Generation-Time-MS": str(duration_ms),
                "X-Audio-Duration-Seconds": f"{audio_duration:.2f}",
                "X-Voice": voice_slug
            }
        )

    except Exception as e:
        logger.error(f"[{request_id}] TTS generation failed: {e}")
        raise HTTPException(status_code=500, detail=f"TTS generation failed: {str(e)}")


@router.get("/voices", response_model=VoiceListResponse, summary="List Voices")
async def list_voices():
    """
    List all available voices

    Returns voice slugs that can be used in /api/tts requests.
    """
    voice_manager = get_voice_manager()
    voices = voice_manager.list_voices()

    return {
        "voices": voices,
        "total": len(voices)
    }


@router.get("/voices/{voice_slug}", summary="Get Voice Details")
async def get_voice_details(voice_slug: str):
    """Get detailed information about a specific voice"""
    voice_manager = get_voice_manager()
    voice = voice_manager.get_voice(voice_slug)

    if not voice:
        raise HTTPException(status_code=404, detail=f"Voice not found: {voice_slug}")

    return voice


@router.get("/health", summary="API Health Check")
async def health_check(request: Request):
    """Check if the TTS API is ready"""
    return {
        "status": "healthy",
        "tts_model_loaded": hasattr(request.app.state, 'tts_model') and request.app.state.tts_model is not None,
        "voices_available": len(get_voice_manager().list_voices()),
        "formats_supported": ["wav", "mp3", "pcm16"]
    }
