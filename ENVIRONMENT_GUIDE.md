# 🔧 Environment Configuration Guide

**Simplified and consolidated** - One file for everything.

---

## 📦 Master Configuration File

**Use**: `.env.master` - Contains ALL your credentials and configuration

```bash
# Quick setup
cp .env.master .env
source .env
```

---

## 🗂️ File Structure (Cleaned Up)

### ✅ **USE THESE** (Active Files)

```
.env.master                 ← Master configuration (copy to .env)
env.twilio.example          ← Twilio template (for reference)
env.tts.example             ← TTS template (for reference)
```

### 📚 **REFERENCE ONLY** (Keep for documentation)

```
env.example                 ← Original template
env.runpod.example          ← RunPod template
```

---

## ⚡ Quick Start

### Option 1: Use Master File (Recommended)

```bash
# Copy master to .env
cp .env.master .env

# Load variables
source .env

# Test everything
./test_scripts/quick_test.sh
./test_twilio.sh
```

### Option 2: Service-Specific

**For TTS only**:
```bash
cp env.tts.example .env.tts
source .env.tts
./test_scripts/quick_test.sh
```

**For Twilio only**:
```bash
cp env.twilio.example .env.twilio
source .env.twilio
./test_twilio.sh
```

---

## 🔑 Your Credentials (In .env.master)

### RunPod TTS
```
Pod ID:      a288y3vpbfxwkk
URL:         https://a288y3vpbfxwkk-8004.proxy.runpod.net
API Key:     cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

### Twilio
```
Account SID: (See .env.master)
Auth Token:  (See .env.master)
Phone:       (See .env.master)
```

---

## 🧹 Cleanup Commands

Remove old/conflicting files:

```bash
# Backup first (optional)
mkdir -p .backup
cp env.*.example .backup/ 2>/dev/null || true

# No cleanup needed - all files are templates!
# Just use .env.master for your actual config
```

---

## 📝 Environment Variables Reference

### TTS Service
| Variable | Value | Purpose |
|----------|-------|---------|
| `TTS_BASE_URL` | https://a288y3vpbfxwkk-8004.proxy.runpod.net | RunPod TTS endpoint |
| `TTS_API_KEY` | cw_live_gbgRb... | Authentication |
| `DEFAULT_VOICE_ID` | naija_female | Default voice |
| `TTS_PORT` | 8004 | Service port |

### Twilio
| Variable | Value | Purpose |
|----------|-------|---------|
| `TWILIO_ACCOUNT_SID` | AC... (from Twilio console) | Account identifier |
| `TWILIO_AUTH_TOKEN` | (from Twilio console) | Authentication |
| `TWILIO_PHONE_NUMBER` | +1... | Your Twilio number |

### API Keys
| Variable | Purpose |
|----------|---------|
| `API_KEY_1` | Production key #1 (n8n, primary) |
| `API_KEY_2` | Production key #2 (backup) |
| `API_KEY_3` | Production key #3 (testing) |
| `API_KEY_4` | Production key #4 (mobile) |
| `API_KEY_5` | Production key #5 (reserve) |

---

## 🎯 Which File to Use?

| Use Case | File | Command |
|----------|------|---------|
| **Everything** | `.env.master` | `cp .env.master .env && source .env` |
| **TTS only** | `env.tts.example` | `cp env.tts.example .env.tts && source .env.tts` |
| **Twilio only** | `env.twilio.example` | `cp env.twilio.example .env.twilio && source .env.twilio` |
| **n8n** | Use environment variables in n8n Settings |  |

---

## 🔐 Security Notes

1. **Never commit `.env` files** - Already in `.gitignore`
2. **Use `.example` files** for version control
3. **Rotate keys regularly** - You have 5 API keys for rotation
4. **Keep `.env.master` secure** - Contains all credentials

---

## ✅ Verification Checklist

After setup:

- [ ] Copied `.env.master` to `.env`
- [ ] Loaded variables: `source .env`
- [ ] All variables set: `env | grep TTS`
- [ ] TTS works: `./test_scripts/quick_test.sh`
- [ ] Twilio works: `./test_twilio.sh`

---

## 🆘 Troubleshooting

### "Variable not set"

```bash
# Check if loaded
echo $TTS_BASE_URL

# If empty, reload
source .env
```

### "File not found"

```bash
# Create from master
cp .env.master .env
```

### "Permission denied"

```bash
# Fix permissions
chmod 600 .env
```

---

## 📦 Files Summary

```
Active Configuration:
  .env.master              ← Master config (copy to .env)
  .env                     ← Your active config (git ignored)

Templates (Reference):
  env.twilio.example       ← Twilio credentials
  env.tts.example          ← TTS credentials
  env.example              ← General template
  env.runpod.example       ← RunPod template
```

**Simple rule**: Use `.env.master` for everything! 🎯

---

**Status**: ✅ All environment files cleaned up and organized  
**Recommended**: `cp .env.master .env && source .env`

