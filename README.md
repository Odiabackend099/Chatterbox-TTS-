# Chatterbox TTS Server with Twilio Integration

Complete production-ready voice agent system combining Chatterbox TTS, LLM (Claude/GPT), and Twilio for phone-based AI assistants.

## Features

✅ **Open Source TTS** - MIT-licensed Chatterbox TTS model
✅ **Zero-Shot Voice Cloning** - Clone any voice from 10-20 second samples
✅ **Multilingual Support** - 23 languages supported
✅ **Emotion Control** - Adjust exaggeration from neutral to theatrical
✅ **LLM Integration** - Built-in support for Anthropic Claude and OpenAI GPT
✅ **Twilio Ready** - Complete webhook handlers for voice calls
✅ **Production Ready** - Docker, RunPod, and cloud deployment
✅ **Low Latency** - 500ms-1s generation time on GPU
✅ **FastAPI Server** - RESTful API with OpenAI-compatible endpoints

## Quick Start

### Prerequisites

- Python 3.10 or 3.11
- NVIDIA GPU with 8GB+ VRAM (recommended) or CPU
- Twilio account with phone number
- Anthropic or OpenAI API key

### Installation

```bash
# Clone repository
git clone <your-repo-url>
cd chatterbox-twilio-integration

# Run installation script
chmod +x setup/install_local.sh
./setup/install_local.sh

# Activate environment
source activate.sh

# Edit .env with your credentials
nano .env

# Test installation
python tests/test_installation.py

# Start server
python scripts/server.py
```

Server will be available at `http://localhost:8004`

## System Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Twilio    │─────▶│  FastAPI     │─────▶│   Claude    │
│   Phone     │      │  Server      │      │   LLM       │
│   Call      │◀─────│              │◀─────│             │
└─────────────┘      └──────┬───────┘      └─────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │  Chatterbox  │
                     │     TTS      │
                     └──────────────┘
```

**Call Flow:**
1. User calls Twilio number
2. Twilio webhook → `/twilio/voice`
3. Server responds with greeting
4. User speaks → transcribed by Twilio
5. Text → LLM (Claude/GPT) → response
6. Response text → Chatterbox TTS → audio
7. Audio → Twilio → User hears response

## Configuration

### Environment Variables (.env)

```bash
# Twilio
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+15555555555

# LLM (choose one)
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx

# Server
CHATTERBOX_HOST=0.0.0.0
CHATTERBOX_PORT=8004
CHATTERBOX_DEVICE=auto  # auto, cuda, mps, cpu
```

### Config File (config/config.yaml)

```yaml
server:
  host: 0.0.0.0
  port: 8004
  workers: 1

model:
  device: auto  # auto, cuda, mps, cpu
  default_voice: "Emily.wav"

generation_defaults:
  temperature: 0.8      # 0-2, controls variation
  exaggeration: 1.3     # 0-2, controls emotion
  cfg_weight: 0.5       # 0-2, text adherence
  speed_factor: 1.0     # Playback speed

llm:
  provider: anthropic   # anthropic or openai
  model: claude-3-5-sonnet-20241022
  max_tokens: 150
  temperature: 0.7
```

## API Reference

### Health Check

```bash
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "components": {
    "tts_model": true,
    "llm_client": true,
    "twilio_client": true
  }
}
```

### Generate TTS

```bash
POST /tts
Content-Type: application/json

{
  "text": "Hello, this is a test.",
  "voice_mode": "clone",
  "predefined_voice": "Emily.wav",
  "temperature": 0.8,
  "exaggeration": 1.3,
  "speed_factor": 1.0,
  "language": "en"
}
```

**Response:** WAV audio file

### OpenAI-Compatible TTS

```bash
POST /v1/audio/speech
Content-Type: application/json

{
  "input": "Hello world!",
  "voice": "Emily.wav",
  "speed": 1.0
}
```

**Response:** WAV audio file

### LLM Generation

```bash
POST /llm
Content-Type: application/json

{
  "prompt": "What is the weather like?",
  "max_tokens": 150,
  "temperature": 0.7
}
```

**Response:**
```json
{
  "response": "I don't have access to real-time weather..."
}
```

### Upload Voice

```bash
POST /upload-voice
Content-Type: multipart/form-data

voice_name: "MyVoice"
audio_file: <file.wav>
```

**Requirements:**
- 10-20 seconds of clean audio
- 24kHz sample rate (recommended)
- WAV format
- Single speaker, no background noise

### List Voices

```bash
GET /voices
```

**Response:**
```json
{
  "voices": ["Emily.wav", "John.wav", "MyVoice.wav"]
}
```

## Deployment

### Local Development

```bash
# Activate environment
source activate.sh

# Start server
python scripts/server.py

# Server runs on http://localhost:8004
```

### Docker

```bash
# Build image
docker-compose build

# Start container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

### RunPod (Production)

See [RunPod Deployment Guide](runpod/RUNPOD_DEPLOYMENT.md) for detailed instructions.

**Quick Deploy:**
```bash
cd runpod/
export RUNPOD_API_KEY=your_key
./deploy_runpod.sh
```

**Recommended GPU:**
- **Development:** RTX 3090 (24GB) - ~$0.20/hr
- **Production:** RTX 4090 (24GB) - ~$0.40/hr
- **High Performance:** A100 (40GB) - ~$1.00/hr

## Twilio Setup

### 1. Configure Webhook

1. Go to [Twilio Console](https://console.twilio.com)
2. Phone Numbers → Manage → Active numbers
3. Select your number
4. Under "Voice Configuration":
   - **A CALL COMES IN:** Webhook
   - **URL:** `https://your-domain.com:8004/twilio/voice`
   - **HTTP:** POST
5. Save

### 2. Test Call

1. Call your Twilio number
2. You should hear: "Hello! I'm your AI assistant..."
3. Speak your question
4. AI responds with LLM + TTS

### 3. Monitor Calls

```bash
# View active call sessions
curl http://localhost:8004/health

# Check logs
tail -f logs/server.log
```

## Voice Cloning

### Prepare Reference Audio

**Best Practices:**
- 10-20 seconds of clear speech
- Single speaker, professional microphone
- No background noise or music
- Speaking style should match desired output
- 24kHz WAV format (or higher)

**Example:**
```bash
# Record or convert audio to proper format
ffmpeg -i input.mp3 -ar 24000 -ac 1 output.wav
```

### Upload Voice

**Via API:**
```bash
curl -X POST http://localhost:8004/upload-voice \
  -F "voice_name=MyVoice" \
  -F "audio_file=@path/to/voice.wav"
```

**Via File System:**
```bash
# Copy to voices directory
cp my_voice.wav voices/MyVoice.wav
```

### Use Cloned Voice

```bash
curl -X POST http://localhost:8004/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Hello in my voice!", "voice": "MyVoice.wav"}' \
  --output cloned.wav
```

## Multilingual Support

### Supported Languages

Arabic, Danish, German, Greek, English, Spanish, Finnish, French, Hebrew, Hindi, Italian, Japanese, Korean, Malay, Dutch, Norwegian, Polish, Portuguese, Russian, Swedish, Swahili, Turkish, Chinese

### Generate Multilingual TTS

```python
import requests

url = "http://localhost:8004/tts"
payload = {
    "text": "Bonjour le monde!",
    "language": "fr",  # French
    "temperature": 0.8
}

response = requests.post(url, json=payload)
with open("french.wav", "wb") as f:
    f.write(response.content)
```

### Language Codes

```
ar - Arabic    de - German    en - English   es - Spanish
fr - French    it - Italian   ja - Japanese  ko - Korean
pt - Portuguese  ru - Russian  zh - Chinese  hi - Hindi
```

## Performance Tuning

### GPU Optimization

```yaml
# config/config.yaml
model:
  device: cuda  # Force CUDA

generation_defaults:
  temperature: 0.7  # Lower = faster, less variation
  exaggeration: 1.0 # Lower = faster
```

### Latency Benchmarks

| GPU | Latency (avg) | Cost/hr* |
|-----|---------------|----------|
| RTX 3090 (24GB) | 2-3s | $0.20 |
| RTX 4090 (24GB) | 500ms-1s | $0.40 |
| A100 (40GB) | 300-500ms | $1.00 |
| CPU | 10-30s | N/A |

*RunPod Community Cloud pricing (approximate)

### Chunking Long Text

```python
# Automatic chunking for text >40 seconds
payload = {
    "text": "Very long text...",
    "split_text": True,
    "chunk_size": 200  # characters per chunk
}
```

## Monitoring

### Health Checks

```bash
# Basic health
curl http://localhost:8004/

# Detailed health
curl http://localhost:8004/health
```

### Logs

```bash
# Server logs
tail -f logs/server.log

# Docker logs
docker-compose logs -f

# RunPod logs
runpodctl logs <pod-id>
```

### Metrics

Enable Prometheus metrics (optional):
```yaml
# config/config.yaml
monitoring:
  enable_prometheus: true
  port: 9090
```

## Troubleshooting

### TTS Model Not Loading

**Error:** `TTS model not loaded`

**Solutions:**
- Check GPU availability: `nvidia-smi`
- Verify CUDA: `python -c "import torch; print(torch.cuda.is_available())"`
- Fallback to CPU: `CHATTERBOX_DEVICE=cpu python scripts/server.py`
- Check disk space for model cache (~3GB needed)

### High Latency

**Causes:**
- CPU mode (switch to GPU)
- Insufficient VRAM (upgrade GPU)
- Large text input (enable chunking)

**Check device:**
```bash
curl http://localhost:8004/health | jq .config.device
```

### Twilio Not Connecting

**Check webhook URL:**
- Must be HTTPS (use ngrok for local testing)
- Must be publicly accessible
- Port must be open

**Local testing with ngrok:**
```bash
ngrok http 8004
# Use ngrok URL in Twilio webhook
```

### Voice Cloning Quality Poor

**Improve quality:**
- Use longer reference (15-20s better than 5s)
- Use high-quality audio (professional mic)
- Remove background noise
- Match speaking style to desired output
- Use 24kHz or higher sample rate

## Security

### Production Checklist

- [ ] Enable authentication in config
- [ ] Use secrets for API keys (not env vars)
- [ ] Enable HTTPS/TLS
- [ ] Restrict CORS origins
- [ ] Implement rate limiting
- [ ] Use firewall rules
- [ ] Monitor for abuse
- [ ] Regular backups
- [ ] Keep dependencies updated

### Enable Authentication

```yaml
# config/config.yaml
security:
  enable_auth: true
  username: admin
  password: strong_password_here
```

### HTTPS with Nginx

See `nginx/nginx.conf` for SSL configuration.

## Development

### Project Structure

```
chatterbox-twilio-integration/
├── setup/
│   ├── install_local.sh       # Installation script (Unix)
│   └── install_local.ps1      # Installation script (Windows)
├── scripts/
│   └── server.py              # Main FastAPI server
├── config/
│   └── config.yaml            # Configuration file
├── tests/
│   ├── test_installation.py   # Installation tests
│   └── test_api.py            # API tests
├── voices/                    # Reference audio files
├── outputs/                   # Generated audio files
├── logs/                      # Server logs
├── runpod/                    # RunPod deployment
│   ├── deploy_runpod.sh
│   ├── Dockerfile.runpod
│   └── RUNPOD_DEPLOYMENT.md
├── Dockerfile                 # Docker configuration
├── docker-compose.yml         # Docker Compose
├── requirements.txt           # Python dependencies
├── .env                       # Environment variables
└── README.md                  # This file
```

### Running Tests

```bash
# Activate environment
source activate.sh

# Run installation test
python tests/test_installation.py

# Run API tests (server must be running)
python tests/test_api.py

# Run with pytest
pytest tests/
```

### Contributing

1. Fork repository
2. Create feature branch
3. Make changes
4. Run tests
5. Submit pull request

## FAQ

**Q: What's the difference between Chatterbox and Coqui TTS?**
A: Chatterbox is newer (2024), has emotion control, and is actively maintained. Coqui's company shut down in 2023 but community continues development.

**Q: Can I use this without GPU?**
A: Yes, but it's very slow (10-30s per generation). GPU strongly recommended for production.

**Q: What's the cost for production?**
A: RunPod RTX 4090: ~$0.40/hr = ~$290/month for 24/7. Use auto-shutdown to reduce costs.

**Q: How many concurrent calls can it handle?**
A: 1-3 calls per GPU depending on complexity. Use multiple pods + load balancer for scaling.

**Q: Is the voice cloning as good as ElevenLabs?**
A: Chatterbox scored 63.75% preference over ElevenLabs in blind tests according to official benchmarks.

**Q: Can I run this locally on Mac?**
A: Yes, Apple Silicon Macs use MPS acceleration. Intel Macs will be slower (CPU mode).

## Resources

- [Chatterbox TTS GitHub](https://github.com/resemble-ai/chatterbox)
- [Chatterbox Demo](https://www.resemble.ai/chatterbox/)
- [RunPod Documentation](https://docs.runpod.io)
- [Twilio Voice API](https://www.twilio.com/docs/voice)
- [FastAPI Documentation](https://fastapi.tiangolo.com)

## License

This project: MIT License

Chatterbox TTS: MIT License

Dependencies: See individual licenses

## Support

- GitHub Issues: [Create Issue](your-repo-issues-url)
- Discord: [Join Server](your-discord-url)
- Email: your-email@example.com

## Changelog

### v1.0.0 (2025-01-XX)
- Initial release
- Chatterbox TTS integration
- Twilio webhook support
- LLM integration (Claude + GPT)
- Docker deployment
- RunPod deployment
- Voice cloning
- Multilingual support

---

**Built with ❤️ for open-source voice AI**
