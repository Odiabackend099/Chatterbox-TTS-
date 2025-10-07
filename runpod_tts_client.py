"""
Production-Ready RunPod TTS Client
Drop this file into your project and use it immediately.

Usage:
    from runpod_tts_client import RunPodTTSClient
    
    tts = RunPodTTSClient()
    audio = tts.generate("Hello world!", voice="emily-en-us")
    
    with open("output.wav", "wb") as f:
        f.write(audio)
"""

import os
import requests
import logging
from typing import Optional, Dict, Any
from pathlib import Path
import hashlib
import json
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

logger = logging.getLogger(__name__)


class RunPodTTSClient:
    """
    Production-ready RunPod TTS client
    
    Features:
    - Automatic retry with exponential backoff
    - Response caching to reduce costs
    - Comprehensive error handling
    - Connection pooling
    - Health monitoring
    """
    
    # Default RunPod endpoint (override with env var or parameter)
    DEFAULT_URL = "https://sbwpfh7exfn63d-8888.proxy.runpod.net/api/tts"
    
    def __init__(
        self,
        base_url: Optional[str] = None,
        api_key: Optional[str] = None,
        timeout: int = 60,
        cache_dir: Optional[str] = None,
        enable_cache: bool = True
    ):
        """
        Initialize TTS client
        
        Args:
            base_url: RunPod TTS endpoint (defaults to env RUNPOD_TTS_URL)
            api_key: API key if authentication is enabled (env RUNPOD_TTS_API_KEY)
            timeout: Request timeout in seconds
            cache_dir: Directory for caching audio files
            enable_cache: Enable/disable caching
        """
        self.base_url = base_url or os.getenv('RUNPOD_TTS_URL', self.DEFAULT_URL)
        self.api_key = api_key or os.getenv('RUNPOD_TTS_API_KEY')
        self.timeout = timeout
        self.enable_cache = enable_cache
        
        # Setup caching
        if self.enable_cache:
            self.cache_dir = Path(cache_dir) if cache_dir else Path('.tts_cache')
            self.cache_dir.mkdir(exist_ok=True)
        else:
            self.cache_dir = None
        
        # Setup session with connection pooling
        self.session = requests.Session()
        adapter = requests.adapters.HTTPAdapter(
            pool_connections=10,
            pool_maxsize=20,
            max_retries=0  # We handle retries with tenacity
        )
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)
        
        logger.info(f"TTS Client initialized: {self.base_url}")
        if self.cache_dir:
            logger.info(f"Cache enabled: {self.cache_dir}")
    
    def _get_headers(self) -> Dict[str, str]:
        """Build request headers"""
        headers = {"Content-Type": "application/json"}
        
        if self.api_key:
            headers["X-API-Key"] = self.api_key
        
        return headers
    
    def _get_cache_key(self, **params) -> str:
        """Generate cache key from parameters"""
        cache_str = json.dumps(params, sort_keys=True)
        return hashlib.sha256(cache_str.encode()).hexdigest()
    
    def _get_from_cache(self, cache_key: str) -> Optional[bytes]:
        """Get audio from cache"""
        if not self.cache_dir:
            return None
        
        cache_file = self.cache_dir / f"{cache_key}.wav"
        if cache_file.exists():
            logger.debug(f"Cache hit: {cache_key[:12]}...")
            return cache_file.read_bytes()
        
        return None
    
    def _save_to_cache(self, cache_key: str, audio_data: bytes):
        """Save audio to cache"""
        if not self.cache_dir:
            return
        
        cache_file = self.cache_dir / f"{cache_key}.wav"
        cache_file.write_bytes(audio_data)
        logger.debug(f"Cached: {cache_key[:12]}...")
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type((
            requests.exceptions.ConnectionError,
            requests.exceptions.Timeout
        )),
        before_sleep=lambda retry_state: logger.warning(
            f"Retry {retry_state.attempt_number}/3 after error..."
        )
    )
    def generate(
        self,
        text: str,
        voice: str = "emily-en-us",
        format: str = "wav",
        temperature: Optional[float] = None,
        exaggeration: Optional[float] = None,
        cfg_weight: Optional[float] = None,
        speed_factor: Optional[float] = None,
        use_cache: bool = True
    ) -> bytes:
        """
        Generate TTS audio
        
        Args:
            text: Text to synthesize (max 2000 chars)
            voice: Voice ID (emily-en-us, james-en-us, sophia-en-gb, marcus-en-us, luna-en-us)
            format: Audio format (wav, mp3, pcm16)
            temperature: Voice variation 0.0-1.0 (default: 0.8)
            exaggeration: Expression intensity 0.5-2.0 (default: 1.3)
            cfg_weight: Guidance strength 0.0-1.0 (default: 0.5)
            speed_factor: Playback speed 0.5-2.0 (default: 1.0)
            use_cache: Use cached audio if available
        
        Returns:
            Audio data as bytes (WAV format)
        
        Raises:
            ValueError: Invalid parameters
            requests.exceptions.RequestException: Network/server errors
        """
        # Validate input
        if not text or len(text.strip()) == 0:
            raise ValueError("Text cannot be empty")
        
        if len(text) > 2000:
            raise ValueError(f"Text too long: {len(text)} chars (max 2000)")
        
        # Build payload
        payload = {
            "text": text,
            "voice": voice,
            "format": format
        }
        
        # Add optional parameters
        if temperature is not None:
            payload["temperature"] = temperature
        if exaggeration is not None:
            payload["exaggeration"] = exaggeration
        if cfg_weight is not None:
            payload["cfg_weight"] = cfg_weight
        if speed_factor is not None:
            payload["speed_factor"] = speed_factor
        
        # Check cache
        if use_cache and self.enable_cache:
            cache_key = self._get_cache_key(**payload)
            cached = self._get_from_cache(cache_key)
            if cached:
                logger.info(f"✓ Cache hit for text: {text[:30]}...")
                return cached
        
        # Make request
        logger.info(f"Generating TTS: {len(text)} chars, voice={voice}")
        
        try:
            response = self.session.post(
                self.base_url,
                json=payload,
                headers=self._get_headers(),
                timeout=self.timeout,
                stream=True
            )
            
            response.raise_for_status()
            audio_data = response.content
            
            # Validate response
            if len(audio_data) == 0:
                raise ValueError("Received empty audio data")
            
            # Check if it's actually audio (not JSON error)
            if format == 'wav' and not audio_data.startswith(b'RIFF'):
                # Try to parse as error message
                try:
                    error_data = json.loads(audio_data.decode('utf-8'))
                    error_msg = error_data.get('detail', 'Unknown error')
                    raise ValueError(f"Server error: {error_msg}")
                except json.JSONDecodeError:
                    raise ValueError("Received invalid audio data")
            
            # Log success
            duration = response.elapsed.total_seconds()
            size_kb = len(audio_data) / 1024
            logger.info(f"✓ Generated {size_kb:.1f} KB in {duration:.1f}s")
            
            # Cache the result
            if use_cache and self.enable_cache:
                self._save_to_cache(cache_key, audio_data)
            
            return audio_data
            
        except requests.exceptions.Timeout:
            logger.error(f"Request timeout after {self.timeout}s")
            raise
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error {e.response.status_code}: {e.response.text}")
            raise
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            raise
    
    def health_check(self) -> Dict[str, Any]:
        """
        Check if TTS service is healthy
        
        Returns:
            Health status dict with 'status' and 'model_loaded' keys
        """
        health_url = self.base_url.replace('/api/tts', '/health')
        
        try:
            response = self.session.get(health_url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {"status": "unhealthy", "error": str(e)}
    
    def list_voices(self) -> list:
        """
        Get available voices
        
        Returns:
            List of voice dictionaries with slug, name, language, gender, description
        """
        voices_url = self.base_url.replace('/tts', '/voices')
        
        try:
            response = self.session.get(voices_url, timeout=10)
            response.raise_for_status()
            data = response.json()
            return data.get('voices', [])
        except Exception as e:
            logger.error(f"Failed to list voices: {e}")
            return []
    
    def clear_cache(self):
        """Clear all cached audio files"""
        if not self.cache_dir or not self.cache_dir.exists():
            return
        
        count = 0
        for cache_file in self.cache_dir.glob("*.wav"):
            cache_file.unlink()
            count += 1
        
        logger.info(f"Cleared {count} cached files")
    
    def close(self):
        """Clean up resources"""
        self.session.close()
    
    def __enter__(self):
        """Context manager support"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager cleanup"""
        self.close()


# Convenience functions
def generate_speech(
    text: str,
    voice: str = "emily-en-us",
    save_to: Optional[str] = None
) -> bytes:
    """
    Quick helper function to generate speech
    
    Args:
        text: Text to synthesize
        voice: Voice ID
        save_to: Optional file path to save audio
    
    Returns:
        Audio bytes (WAV format)
    """
    with RunPodTTSClient() as tts:
        audio = tts.generate(text, voice)
        
        if save_to:
            Path(save_to).write_bytes(audio)
            logger.info(f"✓ Saved to {save_to}")
        
        return audio


# Example usage
if __name__ == "__main__":
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Method 1: Using context manager (recommended)
    with RunPodTTSClient() as tts:
        # Health check
        health = tts.health_check()
        print(f"Service status: {health}")
        
        # List voices
        voices = tts.list_voices()
        print(f"\nAvailable voices:")
        for v in voices:
            print(f"  - {v['slug']}: {v['description']}")
        
        # Generate audio
        print("\nGenerating audio...")
        audio = tts.generate(
            text="Hello! This is a test of the RunPod TTS integration.",
            voice="emily-en-us"
        )
        
        # Save
        with open("test_output.wav", "wb") as f:
            f.write(audio)
        
        print(f"✓ Audio saved: test_output.wav ({len(audio)} bytes)")
    
    # Method 2: Using convenience function
    print("\nUsing convenience function...")
    audio = generate_speech(
        "This is even simpler!",
        voice="james-en-us",
        save_to="simple_output.wav"
    )
    
    print("✓ Complete!")

