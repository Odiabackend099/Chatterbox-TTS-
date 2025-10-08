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
        import numpy as np
        import torch
        
        wav = tts_model.generate(
            text=payload.text,
            exaggeration=voice_params['exaggeration'],
            temperature=voice_params['temperature'],
            cfg_weight=voice_params['cfg_weight']
        )
        
        # Convert torch tensor to numpy if needed
        if isinstance(wav, torch.Tensor):
            wav = wav.cpu().numpy()
        
        # Ensure it's a 1D float32 array
        wav = np.array(wav, dtype=np.float32)
        if len(wav.shape) > 1:
            wav = wav.flatten()

        # Apply speed factor if needed
        if voice_params['speed_factor'] != 1.0:
            import librosa
            wav = librosa.effects.time_stretch(wav, rate=1.0 / voice_params['speed_factor'])

        # Convert to requested format
        if payload.format == "wav":
            # Create WAV file - ROBUST APPROACH
            import numpy as np
            import tempfile
            from pathlib import Path

            # Ensure wav is proper numpy array with correct dtype
            if not isinstance(wav, np.ndarray):
                logger.info(f"[{request_id}] Converting wav from {type(wav)} to numpy array")
                wav = np.array(wav, dtype=np.float32)
            else:
                # Ensure float32 dtype for soundfile compatibility
                if wav.dtype != np.float32:
                    logger.info(f"[{request_id}] Converting wav dtype from {wav.dtype} to float32")
                    wav = wav.astype(np.float32)

            # Flatten if multi-dimensional
            if len(wav.shape) > 1:
                logger.info(f"[{request_id}] Flattening wav from shape {wav.shape}")
                wav = wav.flatten()

            # Validate audio data
            if len(wav) == 0:
                raise ValueError("Generated audio is empty")

            # Normalize if values are out of range
            max_val = np.abs(wav).max()
            if max_val > 1.0:
                logger.warning(f"[{request_id}] Audio values out of range (max={max_val}), normalizing")
                wav = wav / max_val

            logger.info(f"[{request_id}] Prepared WAV: shape={wav.shape}, dtype={wav.dtype}, range=[{wav.min():.3f}, {wav.max():.3f}]")

            # Write to temp file with explicit parameters
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
                tmp_path = tmp.name

            try:
                # Write with explicit format specification
                sf.write(
                    tmp_path,
                    wav,
                    samplerate=24000,
                    subtype='PCM_16'  # Explicit 16-bit PCM encoding
                )
                logger.info(f"[{request_id}] ✓ Wrote WAV to {tmp_path} ({len(wav)} samples)")

                # Verify the file was created and has content
                tmp_size = Path(tmp_path).stat().st_size
                if tmp_size == 0:
                    raise ValueError(f"Temp WAV file is empty: {tmp_path}")
                logger.info(f"[{request_id}] ✓ Temp file size: {tmp_size} bytes")

            except Exception as write_error:
                logger.error(f"[{request_id}] ✗ sf.write failed: {write_error}")
                Path(tmp_path).unlink(missing_ok=True)
                raise

            # Read temp file into buffer
            try:
                with open(tmp_path, 'rb') as f:
                    audio_bytes = f.read()
                buffer = io.BytesIO(audio_bytes)
                buffer.seek(0)
                logger.info(f"[{request_id}] ✓ Read {len(audio_bytes)} bytes from temp file")
            except Exception as read_error:
                logger.error(f"[{request_id}] ✗ Failed to read temp file: {read_error}")
                raise
            finally:
                # Always clean up temp file
                Path(tmp_path).unlink(missing_ok=True)
                logger.info(f"[{request_id}] ✓ Cleaned up temp file")

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
                logger.error(f"[{request_id}] MP3 conversion failed: {e}, falling back to WAV")
                import numpy as np
                import tempfile
                from pathlib import Path

                # Ensure proper numpy array
                if not isinstance(wav, np.ndarray):
                    wav = np.array(wav, dtype=np.float32)
                elif wav.dtype != np.float32:
                    wav = wav.astype(np.float32)

                # Normalize if needed
                max_val = np.abs(wav).max()
                if max_val > 1.0:
                    wav = wav / max_val

                with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
                    tmp_path = tmp.name

                try:
                    sf.write(tmp_path, wav, samplerate=24000, subtype='PCM_16')
                    with open(tmp_path, 'rb') as f:
                        buffer = io.BytesIO(f.read())
                    buffer.seek(0)
                    logger.info(f"[{request_id}] ✓ MP3 fallback: Generated WAV")
                finally:
                    Path(tmp_path).unlink(missing_ok=True)

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
