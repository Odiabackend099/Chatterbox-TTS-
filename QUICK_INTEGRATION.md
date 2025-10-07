# 🚀 Quick Integration Guide

## Get Started in 5 Minutes

Your RunPod TTS API is live at:
```
https://sbwpfh7exfn63d-8888.proxy.runpod.net
```

---

## ⚡ **1. Quick Setup**

### Install Dependencies
```bash
pip install requests python-dotenv tenacity
```

### Create .env File
```bash
cp env.runpod.example .env
```

Edit `.env`:
```env
RUNPOD_TTS_URL=https://sbwpfh7exfn63d-8888.proxy.runpod.net/api/tts
```

---

## 🎯 **2. Simple Usage**

### Copy Client to Your Project
```bash
# Copy the ready-to-use client
cp runpod_tts_client.py your_project/
```

### Use in Your Code
```python
from runpod_tts_client import generate_speech

# Generate audio (3 lines!)
audio = generate_speech("Hello world!", voice="emily-en-us")

# Save it
with open("output.wav", "wb") as f:
    f.write(audio)

# That's it! ✅
```

---

## 📚 **3. Full Example**

```python
from runpod_tts_client import RunPodTTSClient
import logging

# Enable logging to see what's happening
logging.basicConfig(level=logging.INFO)

# Initialize client (reads from .env automatically)
tts = RunPodTTSClient(enable_cache=True)

# Health check
health = tts.health_check()
print(f"Status: {health}")

# List available voices
voices = tts.list_voices()
print(f"Voices: {[v['slug'] for v in voices]}")

# Generate with different voices
for voice in ["emily-en-us", "james-en-us", "sophia-en-gb"]:
    audio = tts.generate(
        text=f"Hello, this is {voice} speaking!",
        voice=voice
    )
    
    filename = f"{voice}.wav"
    with open(filename, "wb") as f:
        f.write(audio)
    
    print(f"✓ Generated {filename}")

# Cleanup
tts.close()
```

---

## 🎤 **4. Available Voices**

| Voice | Description | Best For |
|-------|-------------|----------|
| `emily-en-us` | Natural female, American | General, customer service |
| `james-en-us` | Professional male, American | Business, announcements |
| `sophia-en-gb` | Female, British | Formal, international |
| `marcus-en-us` | Deep male, American | Authority, narration |
| `luna-en-us` | Energetic female, American | Friendly, upbeat content |

---

## ⚙️ **5. Advanced Parameters**

```python
audio = tts.generate(
    text="Your text here",
    voice="emily-en-us",
    
    # Audio format
    format="wav",  # wav | mp3 | pcm16
    
    # Voice control
    temperature=0.8,      # 0.0-1.0: Higher = more variation
    exaggeration=1.3,     # 0.5-2.0: Higher = more expressive
    cfg_weight=0.5,       # 0.0-1.0: Guidance strength
    speed_factor=1.0,     # 0.5-2.0: Playback speed
    
    # Performance
    use_cache=True        # Cache identical requests
)
```

---

## 🔧 **6. Error Handling**

```python
from requests.exceptions import RequestException, Timeout

try:
    audio = tts.generate("Hello world!")
    
except ValueError as e:
    print(f"Invalid input: {e}")
    
except Timeout:
    print("Request timeout - text might be too long")
    
except RequestException as e:
    print(f"Network error: {e}")
    
except Exception as e:
    print(f"Unexpected error: {e}")
```

---

## 💾 **7. Caching (Saves Money!)**

Caching is **automatic** - identical requests return cached audio instantly!

```python
# First call: generates from server (~20s)
audio1 = tts.generate("Hello world!")

# Second call: instant from cache (<1ms)
audio2 = tts.generate("Hello world!")

# Clear cache if needed
tts.clear_cache()
```

**Cache location:** `.tts_cache/` directory

---

## 📊 **8. Testing Your Integration**

```bash
# Test the client
python runpod_tts_client.py

# Expected output:
# Service status: {'status': 'healthy', 'model_loaded': True}
# Available voices: ['luna-en-us', 'marcus-en-us', 'sophia-en-gb', 'james-en-us', 'emily-en-us']
# ✓ Audio saved: test_output.wav
```

---

## 🌐 **9. API Endpoints Reference**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check |
| `/api/health` | GET | Detailed health |
| `/api/voices` | GET | List voices |
| `/api/tts` | POST | Generate TTS |
| `/docs` | GET | API documentation |

**Base URL:** `https://sbwpfh7exfn63d-8888.proxy.runpod.net`

---

## 🎉 **You're Ready!**

**Three simple steps:**

1. ✅ Install: `pip install requests python-dotenv tenacity`
2. ✅ Copy: `runpod_tts_client.py` to your project
3. ✅ Use: `audio = generate_speech("Hello!")`

**That's it!** Your project now has production-grade TTS! 🚀

---

## 📞 **Need Help?**

- **API Docs:** `https://sbwpfh7exfn63d-8888.proxy.runpod.net/docs`
- **Health Check:** `https://sbwpfh7exfn63d-8888.proxy.runpod.net/health`
- **Full Guide:** See `INTEGRATION_BEST_PRACTICES.md`

