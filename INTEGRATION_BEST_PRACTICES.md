# 🏆 Production Integration Best Practices

## RunPod TTS API Integration Guide

**Your Production Endpoint:** `https://sbwpfh7exfn63d-8888.proxy.runpod.net`

---

## 🔐 **1. Security Best Practices**

### Environment Variables (CRITICAL)

**Never hardcode URLs or keys in your code!**

Create `.env` file:
```env
# RunPod TTS Configuration
RUNPOD_TTS_URL=https://sbwpfh7exfn63d-8888.proxy.runpod.net/api/tts
RUNPOD_TTS_API_KEY=  # Optional - add when you enable auth
RUNPOD_TTS_TIMEOUT=60
RUNPOD_TTS_MAX_RETRIES=3
```

Add to `.gitignore`:
```
.env
*.env
.env.*
```

---

## 🐍 **2. Python Integration (Production-Ready)**

### Install Dependencies

```bash
pip install requests python-dotenv tenacity
```

### Complete Implementation

```python
"""
Production-ready RunPod TTS Client
Best practices included: retry logic, error handling, caching
"""

import os
import requests
import logging
from typing import Optional, Dict, Any
from pathlib import Path
from dotenv import load_dotenv
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)
import hashlib
import json

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class RunPodTTSClient:
    """Production-ready RunPod TTS client with best practices"""
    
    def __init__(
        self,
        base_url: Optional[str] = None,
        api_key: Optional[str] = None,
        timeout: int = 60,
        cache_dir: Optional[str] = None
    ):
        self.base_url = base_url or os.getenv('RUNPOD_TTS_URL')
        self.api_key = api_key or os.getenv('RUNPOD_TTS_API_KEY')
        self.timeout = timeout
        self.cache_dir = Path(cache_dir) if cache_dir else Path('.tts_cache')
        
        # Validate configuration
        if not self.base_url:
            raise ValueError("RUNPOD_TTS_URL not set in environment or parameters")
        
        # Create cache directory
        if self.cache_dir:
            self.cache_dir.mkdir(exist_ok=True)
            logger.info(f"TTS cache enabled: {self.cache_dir}")
    
    def _get_headers(self) -> Dict[str, str]:
        """Build request headers"""
        headers = {"Content-Type": "application/json"}
        
        if self.api_key:
            headers["X-API-Key"] = self.api_key
        
        return headers
    
    def _get_cache_key(self, text: str, voice: str, **params) -> str:
        """Generate cache key from parameters"""
        cache_data = {
            "text": text,
            "voice": voice,
            **params
        }
        cache_str = json.dumps(cache_data, sort_keys=True)
        return hashlib.sha256(cache_str.encode()).hexdigest()
    
    def _get_cached_audio(self, cache_key: str) -> Optional[bytes]:
        """Get audio from cache if exists"""
        if not self.cache_dir:
            return None
        
        cache_file = self.cache_dir / f"{cache_key}.wav"
        if cache_file.exists():
            logger.info(f"Cache hit: {cache_key[:8]}...")
            return cache_file.read_bytes()
        
        return None
    
    def _save_to_cache(self, cache_key: str, audio_data: bytes):
        """Save audio to cache"""
        if not self.cache_dir:
            return
        
        cache_file = self.cache_dir / f"{cache_key}.wav"
        cache_file.write_bytes(audio_data)
        logger.info(f"Cached: {cache_key[:8]}...")
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(requests.exceptions.RequestException),
        before_sleep=lambda retry_state: logger.warning(
            f"Retry attempt {retry_state.attempt_number}/3..."
        )
    )
    def generate(
        self,
        text: str,
        voice: str = "emily-en-us",
        format: str = "wav",
        temperature: float = 0.8,
        exaggeration: float = 1.3,
        cfg_weight: float = 0.5,
        speed_factor: float = 1.0,
        use_cache: bool = True
    ) -> bytes:
        """
        Generate TTS audio with retry logic and caching
        
        Args:
            text: Text to synthesize
            voice: Voice ID (emily-en-us, james-en-us, etc.)
            format: Audio format (wav, mp3, pcm16)
            temperature: Voice variation (0.0-1.0)
            exaggeration: Expression intensity (0.5-2.0)
            cfg_weight: Classifier-free guidance (0.0-1.0)
            speed_factor: Playback speed (0.5-2.0)
            use_cache: Enable caching for identical requests
        
        Returns:
            Audio data as bytes
        
        Raises:
            requests.exceptions.RequestException: On network errors
            ValueError: On invalid parameters
        """
        # Validate input
        if not text or len(text.strip()) == 0:
            raise ValueError("Text cannot be empty")
        
        if len(text) > 2000:
            raise ValueError("Text too long (max 2000 characters)")
        
        # Check cache
        if use_cache:
            cache_key = self._get_cache_key(
                text, voice, format=format, 
                temperature=temperature, exaggeration=exaggeration,
                cfg_weight=cfg_weight, speed_factor=speed_factor
            )
            cached_audio = self._get_cached_audio(cache_key)
            if cached_audio:
                return cached_audio
        
        # Prepare request
        payload = {
            "text": text,
            "voice": voice,
            "format": format,
            "temperature": temperature,
            "exaggeration": exaggeration,
            "cfg_weight": cfg_weight,
            "speed_factor": speed_factor
        }
        
        logger.info(f"Generating TTS: voice={voice}, text_len={len(text)}")
        
        # Make request
        try:
            response = requests.post(
                self.base_url,
                json=payload,
                headers=self._get_headers(),
                timeout=self.timeout
            )
            
            response.raise_for_status()
            
            audio_data = response.content
            
            # Validate response
            if len(audio_data) == 0:
                raise ValueError("Received empty audio data")
            
            # Check if it's actually audio (not JSON error)
            if audio_data[:4] != b'RIFF' and format == 'wav':
                error_msg = audio_data.decode('utf-8', errors='ignore')
                raise ValueError(f"Server returned error: {error_msg}")
            
            logger.info(f"✓ Generated {len(audio_data)} bytes in {response.elapsed.total_seconds():.1f}s")
            
            # Cache the result
            if use_cache:
                self._save_to_cache(cache_key, audio_data)
            
            return audio_data
            
        except requests.exceptions.Timeout:
            logger.error(f"Request timeout after {self.timeout}s")
            raise
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            raise
    
    def health_check(self) -> Dict[str, Any]:
        """Check if TTS service is healthy"""
        health_url = self.base_url.replace('/api/tts', '/health')
        
        try:
            response = requests.get(health_url, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            return {"status": "unhealthy", "error": str(e)}
    
    def list_voices(self) -> list:
        """Get available voices"""
        voices_url = self.base_url.replace('/tts', '/voices')
        
        try:
            response = requests.get(voices_url, timeout=10)
            response.raise_for_status()
            data = response.json()
            return data.get('voices', [])
        except Exception as e:
            logger.error(f"Failed to list voices: {e}")
            return []


# Usage Example
if __name__ == "__main__":
    # Initialize client
    tts = RunPodTTSClient()
    
    # Health check
    health = tts.health_check()
    print(f"Service status: {health}")
    
    # List voices
    voices = tts.list_voices()
    print(f"Available voices: {[v['slug'] for v in voices]}")
    
    # Generate audio
    audio = tts.generate(
        text="Hello! This is a production test of the RunPod TTS integration.",
        voice="emily-en-us"
    )
    
    # Save and play
    with open("test.wav", "wb") as f:
        f.write(audio)
    
    print("✓ Audio saved to test.wav")
```

---

## 🚀 **3. Advanced Features**

### Batch Processing

```python
def generate_batch(texts: list[str], voice: str = "emily-en-us") -> list[bytes]:
    """Generate multiple TTS requests efficiently"""
    tts = RunPodTTSClient()
    results = []
    
    for i, text in enumerate(texts, 1):
        try:
            logger.info(f"Processing {i}/{len(texts)}")
            audio = tts.generate(text, voice)
            results.append(audio)
        except Exception as e:
            logger.error(f"Failed to generate {i}: {e}")
            results.append(None)
    
    return results
```

### Async Support (for high-concurrency)

```python
import asyncio
import aiohttp

async def generate_tts_async(text: str, voice: str = "emily-en-us") -> bytes:
    """Async TTS generation for concurrent requests"""
    url = os.getenv('RUNPOD_TTS_URL')
    
    async with aiohttp.ClientSession() as session:
        async with session.post(
            url,
            json={"text": text, "voice": voice},
            timeout=aiohttp.ClientTimeout(total=60)
        ) as response:
            response.raise_for_status()
            return await response.read()

# Usage
async def main():
    tasks = [
        generate_tts_async("First sentence"),
        generate_tts_async("Second sentence"),
        generate_tts_async("Third sentence")
    ]
    results = await asyncio.gather(*tasks)
    return results
```

---

## 📊 **4. Monitoring & Logging**

```python
import time
from dataclasses import dataclass
from datetime import datetime

@dataclass
class TTSMetrics:
    """Track TTS performance metrics"""
    request_count: int = 0
    total_chars: int = 0
    total_time: float = 0
    cache_hits: int = 0
    errors: int = 0
    
    def record_request(self, text_len: int, duration: float, cached: bool = False):
        self.request_count += 1
        self.total_chars += text_len
        self.total_time += duration
        if cached:
            self.cache_hits += 1
    
    def record_error(self):
        self.errors += 1
    
    @property
    def avg_time(self) -> float:
        return self.total_time / self.request_count if self.request_count > 0 else 0
    
    @property
    def cache_hit_rate(self) -> float:
        return self.cache_hits / self.request_count if self.request_count > 0 else 0
    
    def report(self) -> dict:
        return {
            "requests": self.request_count,
            "total_characters": self.total_chars,
            "avg_time_seconds": round(self.avg_time, 2),
            "cache_hit_rate": f"{self.cache_hit_rate * 100:.1f}%",
            "errors": self.errors,
            "timestamp": datetime.now().isoformat()
        }

# Usage
metrics = TTSMetrics()

# Track each request
start = time.time()
audio = tts.generate("Hello world")
metrics.record_request(len("Hello world"), time.time() - start)

# Generate report
print(json.dumps(metrics.report(), indent=2))
```

---

## 🛡️ **5. Error Handling Patterns**

```python
from enum import Enum

class TTSError(Exception):
    """Base TTS exception"""
    pass

class TTSTimeoutError(TTSError):
    """Request timeout"""
    pass

class TTSServiceUnavailable(TTSError):
    """Service is down"""
    pass

class TTSInvalidInput(TTSError):
    """Invalid parameters"""
    pass


def generate_with_fallback(text: str, voice: str = "emily-en-us") -> Optional[bytes]:
    """
    Generate TTS with graceful degradation
    """
    try:
        # Try RunPod TTS
        tts = RunPodTTSClient()
        return tts.generate(text, voice)
        
    except requests.exceptions.Timeout:
        logger.error("RunPod TTS timeout, check if text is too long")
        raise TTSTimeoutError("TTS generation timeout")
        
    except requests.exceptions.ConnectionError:
        logger.error("RunPod TTS unavailable")
        raise TTSServiceUnavailable("TTS service is down")
        
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 400:
            logger.error(f"Invalid TTS parameters: {e.response.text}")
            raise TTSInvalidInput(f"Invalid input: {e.response.text}")
        else:
            logger.error(f"TTS service error: {e}")
            raise TTSError(f"Service error: {e}")
    
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise TTSError(f"Unexpected error: {e}")
```

---

## ⚡ **6. Performance Optimization**

### Connection Pooling

```python
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

class OptimizedTTSClient(RunPodTTSClient):
    """TTS client with connection pooling"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # Configure session with connection pooling
        self.session = requests.Session()
        
        # Retry strategy
        retry_strategy = Retry(
            total=3,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["POST"],
            backoff_factor=1
        )
        
        adapter = HTTPAdapter(
            max_retries=retry_strategy,
            pool_connections=10,
            pool_maxsize=20
        )
        
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)
    
    def generate(self, text: str, **kwargs) -> bytes:
        """Generate using pooled connection"""
        # Use self.session instead of requests
        response = self.session.post(
            self.base_url,
            json={"text": text, **kwargs},
            headers=self._get_headers(),
            timeout=self.timeout
        )
        response.raise_for_status()
        return response.content
    
    def close(self):
        """Clean up session"""
        self.session.close()
```

### Text Chunking for Long Content

```python
def chunk_text(text: str, max_length: int = 500) -> list[str]:
    """Split long text into chunks"""
    sentences = text.replace('!', '.').replace('?', '.').split('.')
    chunks = []
    current_chunk = ""
    
    for sentence in sentences:
        sentence = sentence.strip()
        if not sentence:
            continue
        
        if len(current_chunk) + len(sentence) < max_length:
            current_chunk += sentence + ". "
        else:
            if current_chunk:
                chunks.append(current_chunk.strip())
            current_chunk = sentence + ". "
    
    if current_chunk:
        chunks.append(current_chunk.strip())
    
    return chunks


def generate_long_audio(text: str, voice: str = "emily-en-us") -> bytes:
    """Generate audio for long text with chunking"""
    from pydub import AudioSegment
    import io
    
    chunks = chunk_text(text, max_length=500)
    logger.info(f"Split text into {len(chunks)} chunks")
    
    audio_segments = []
    tts = RunPodTTSClient()
    
    for i, chunk in enumerate(chunks, 1):
        logger.info(f"Generating chunk {i}/{len(chunks)}")
        audio_data = tts.generate(chunk, voice)
        
        # Load as AudioSegment
        segment = AudioSegment.from_wav(io.BytesIO(audio_data))
        audio_segments.append(segment)
    
    # Combine all chunks
    combined = sum(audio_segments)
    
    # Export as WAV
    buffer = io.BytesIO()
    combined.export(buffer, format="wav")
    buffer.seek(0)
    
    return buffer.read()
```

---

## 🔒 **7. Enable API Key Authentication (Recommended)**

### Setup on RunPod:

**In your RunPod SSH terminal:**

```bash
# Add PostgreSQL (for API key storage)
# Option 1: Use external PostgreSQL (recommended)
export POSTGRES_HOST=your-db-host.com
export POSTGRES_DB=chatterbox
export POSTGRES_USER=chatterbox
export POSTGRES_PASSWORD=your-secure-password

# Add Redis (for rate limiting)
export REDIS_HOST=your-redis-host.com
export REDIS_PORT=6379

# Restart server to enable auth
# Server will auto-enable authentication when DB & Redis are available
```

### Generate API Keys:

```bash
# In RunPod terminal
python scripts/generate_api_keys.py --count 5 --prefix prod

# Output:
# prod_abc123def456...
# prod_xyz789uvw012...
```

### Use in Your Code:

```python
# .env file
RUNPOD_TTS_API_KEY=prod_abc123def456...

# Code automatically uses it
tts = RunPodTTSClient()  # Reads from .env
audio = tts.generate("Hello world")
```

---

## 📦 **8. Complete Integration Example**

```python
"""
Complete production integration example
File: tts_service.py
"""

import os
from typing import Optional
from pathlib import Path
from dotenv import load_dotenv
import logging

# Your production TTS client (from above)
from runpod_tts_client import RunPodTTSClient, TTSMetrics

load_dotenv()
logger = logging.getLogger(__name__)


class VoiceService:
    """High-level voice service for your application"""
    
    def __init__(self):
        self.tts = RunPodTTSClient(
            cache_dir=".voice_cache"
        )
        self.metrics = TTSMetrics()
        
        # Verify service is available
        health = self.tts.health_check()
        if health.get('status') != 'healthy':
            logger.warning("TTS service unhealthy, some features may not work")
    
    def say(
        self, 
        text: str, 
        voice: str = "emily-en-us",
        save_to: Optional[str] = None
    ) -> bytes:
        """
        Generate speech from text
        
        Args:
            text: What to say
            voice: Which voice to use
            save_to: Optional path to save audio file
        
        Returns:
            Audio data as bytes
        """
        import time
        
        start = time.time()
        
        try:
            audio = self.tts.generate(text, voice)
            duration = time.time() - start
            
            self.metrics.record_request(len(text), duration)
            
            if save_to:
                Path(save_to).write_bytes(audio)
                logger.info(f"✓ Saved audio to {save_to}")
            
            return audio
            
        except Exception as e:
            self.metrics.record_error()
            logger.error(f"TTS failed: {e}")
            raise
    
    def get_stats(self) -> dict:
        """Get usage statistics"""
        return self.metrics.report()


# Global instance (singleton pattern)
_voice_service = None

def get_voice_service() -> VoiceService:
    """Get or create voice service instance"""
    global _voice_service
    if _voice_service is None:
        _voice_service = VoiceService()
    return _voice_service


# Simple API for your application
def generate_speech(text: str, voice: str = "emily-en-us") -> bytes:
    """
    Simple function to generate speech
    Use this in your application code
    """
    service = get_voice_service()
    return service.say(text, voice)


# Example usage in your app
if __name__ == "__main__":
    # Simple usage
    audio = generate_speech("Hello from your application!")
    
    with open("output.wav", "wb") as f:
        f.write(audio)
    
    # Get statistics
    service = get_voice_service()
    print(service.get_stats())
```

---

## 🧪 **9. Testing Your Integration**

```python
"""
Test your TTS integration
File: test_tts_integration.py
"""

import pytest
from your_project.tts_service import generate_speech, get_voice_service


def test_health_check():
    """Test TTS service is available"""
    service = get_voice_service()
    health = service.tts.health_check()
    
    assert health['status'] == 'healthy'
    assert health['model_loaded'] == True


def test_simple_generation():
    """Test basic TTS generation"""
    audio = generate_speech("Hello world")
    
    assert audio is not None
    assert len(audio) > 0
    assert audio[:4] == b'RIFF'  # Valid WAV file


def test_all_voices():
    """Test all available voices"""
    service = get_voice_service()
    voices = service.tts.list_voices()
    
    for voice_info in voices:
        voice_slug = voice_info['slug']
        audio = generate_speech(f"Testing {voice_slug}", voice=voice_slug)
        assert len(audio) > 0


def test_caching():
    """Test cache works"""
    service = get_voice_service()
    
    # First request (miss)
    audio1 = service.say("Test caching", voice="emily-en-us")
    
    # Second request (hit)
    audio2 = service.say("Test caching", voice="emily-en-us")
    
    # Should be identical
    assert audio1 == audio2


def test_error_handling():
    """Test error handling"""
    with pytest.raises(ValueError):
        generate_speech("")  # Empty text
    
    with pytest.raises(ValueError):
        generate_speech("a" * 3000)  # Too long


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

---

## 📚 **10. Configuration File**

**Create `config/tts.yaml`:**

```yaml
runpod:
  base_url: https://sbwpfh7exfn63d-8888.proxy.runpod.net/api/tts
  timeout: 60
  max_retries: 3
  
voice_defaults:
  default_voice: emily-en-us
  temperature: 0.8
  exaggeration: 1.3
  cfg_weight: 0.5
  speed_factor: 1.0

caching:
  enabled: true
  cache_dir: .voice_cache
  max_cache_size_mb: 500
  ttl_days: 7

available_voices:
  - slug: emily-en-us
    name: Emily
    use_cases: [general, customer_service, notifications]
  
  - slug: james-en-us
    name: James
    use_cases: [professional, announcements]
  
  - slug: sophia-en-gb
    name: Sophia
    use_cases: [british_english, formal]
  
  - slug: marcus-en-us
    name: Marcus
    use_cases: [authoritative, deep_voice]
  
  - slug: luna-en-us
    name: Luna
    use_cases: [energetic, friendly]
```

---

## ✅ **Quick Start Checklist**

- [ ] Create `.env` file with `RUNPOD_TTS_URL`
- [ ] Install dependencies: `pip install requests python-dotenv tenacity`
- [ ] Copy `RunPodTTSClient` class to your project
- [ ] Test health check: `tts.health_check()`
- [ ] Generate test audio: `tts.generate("test")`
- [ ] Enable caching for production
- [ ] Add monitoring/logging
- [ ] (Optional) Enable API key authentication

---

## 🎯 **Your RunPod Endpoint**

```
Base URL: https://sbwpfh7exfn63d-8888.proxy.runpod.net
TTS Endpoint: /api/tts
Health: /health
Voices: /api/voices
Docs: /docs
```

**Status:** ✅ Live and ready for integration!

---

Would you like me to create the complete client library file for you to drop into your project? 🚀

