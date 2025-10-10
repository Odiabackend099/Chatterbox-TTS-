# 🔑 Your TTS Environment Configuration

**Status**: ✅ Live and Working  
**Date**: October 8, 2025

---

## 🌐 **RunPod TTS Service**

```bash
# Base URL (Port 8000 - Publicly Accessible)
TTS_BASE_URL=https://aav4qfa6yqgt3k-8000.proxy.runpod.net

# Endpoints
TTS_ENDPOINT=/api/tts
HEALTH_ENDPOINT=/api/health
VOICES_ENDPOINT=/api/voices
DOCS_ENDPOINT=/docs

# Pod Details
RUNPOD_POD_ID=aav4qfa6yqgt3k
RUNPOD_PORT=8000
```

---

## 🔑 **API Keys**

```bash
# Primary API Key (Use this for most integrations)
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU

# All 5 Production Keys:
API_KEY_1=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU  # Primary
API_KEY_2=cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI  # Backup
API_KEY_3=cw_live_9rSEdn-4tfW-blbihfBsm08S1Zggs0OaJuLbCFXGKd8  # Testing
API_KEY_4=cw_live_-_MZyOhDPDB4PWBS3tfc-4mqONpa1dXhn6XjeL4aOlk  # Mobile
API_KEY_5=cw_live_HpqXxNWGY6N4EO5ZP4nS6Vqo1shGUS-63HTIZh_EWVY  # Reserve
```

---

## 🎙️ **Available Voices**

```bash
DEFAULT_VOICE=emily-en-us

# All Available Voices:
# - emily-en-us    (Female, US English)
# - james-en-us    (Male, US English)
# - sophia-en-gb   (Female, British English)
# - marcus-en-us   (Male, US English)
# - luna-en-us     (Female, US English)
```

---

## 📞 **Twilio Integration**

```bash
TWILIO_ACCOUNT_SID=(your Twilio account SID)
TWILIO_AUTH_TOKEN=(your Twilio auth token)
TWILIO_PHONE_NUMBER=(your Twilio phone number)

# Webhook URL for Twilio:
TWILIO_WEBHOOK_URL=https://a288y3vpbfxwkk-8888.proxy.runpod.net/twilio/voice
```

---

## 🔧 **RunPod Server Config**

```bash
# Port Configuration
CHATTERBOX_PORT=8888
PYTHONUNBUFFERED=1
PYTHONPATH=/workspace/chatterbox-twilio-integration

# Model Cache Directories
TRANSFORMERS_CACHE=/workspace/model_cache
HF_HOME=/workspace/model_cache
TORCH_HOME=/workspace/model_cache
```

---

## 📋 **Quick Usage Examples**

### Test with Auto-Play:
```bash
cd /Users/odiadev/chatterbox-twilio-integration
./test_scripts/quick_test.sh "Your text here"
```

### Direct API Call:
```bash
curl -X POST "https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/tts" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria!", "voice": "emily-en-us"}' \
  --output hello.wav
```

### Health Check:
```bash
curl https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/health
```

### List Voices:
```bash
curl https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/voices
```

---

## 🔄 **For n8n Integration**

**Environment Variables** (in n8n Settings):
```bash
TTS_BASE_URL=https://aav4qfa6yqgt3k-8000.proxy.runpod.net
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
DEFAULT_VOICE=emily-en-us
```

**Or for Free Tier** (hardcode in credential):
```
Header Name: Authorization
Header Value: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

---

## 🎯 **SSH Access to RunPod**

```bash
ssh aav4qfa6yqgt3k-64410d3d@ssh.runpod.io -i ~/.ssh/id_ed25519
```

**Or Direct SSH:**
```bash
ssh root@157.157.221.29 -p 19191 -i ~/.ssh/id_ed25519
```

---

## ✅ **Verified Working**

```
✓ Service URL:      https://aav4qfa6yqgt3k-8000.proxy.runpod.net
✓ Health Status:    healthy
✓ Model Loaded:     true
✓ Voices:           5 available
✓ Formats:          WAV, MP3, PCM16
✓ Audio Generated:  166KB (verified)
✓ Public Access:    Working
```

---

## 🔐 **Security Notes**

- Keep this file secure (contains all credentials)
- API keys are production keys
- Twilio credentials are live
- ⚠️ **REVOKE GitHub token**: `ghp_RNQm...` (exposed in chat)

---

**Status**: ✅ **PRODUCTION READY**  
**Last Verified**: October 8, 2025  
**Service**: LIVE AND OPERATIONAL 🎉

