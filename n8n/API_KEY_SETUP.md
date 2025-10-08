# 🔑 TTS API Key Setup for n8n

## Your Production API Keys

From `generated_api_keys.txt`, you have **5 production API keys**:

```
1. cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
2. cw_live_1MAkaV2KdHJuSKSc2LJd_cO71o-_kEijBg5fJgxnZoI
3. cw_live_9rSEdn-4tfW-blbihfBsm08S1Zggs0OaJuLbCFXGKd8
4. cw_live_-_MZyOhDPDB4PWBS3tfc-4mqONpa1dXhn6XjeL4aOlk
5. cw_live_HpqXxNWGY6N4EO5ZP4nS6Vqo1shGUS-63HTIZh_EWVY
```

**Recommended**: Use **Key #1** for your TTS integration.

---

## 🎯 How to Set Up in n8n

### Step 1: Set Environment Variable

1. Open **n8n** → **Settings** → **Environments**
2. Add this variable:

```bash
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

> 💡 **Tip**: Use Key #1 for n8n, save the others for different integrations or as backups.

### Step 2: Create Header Auth Credential

1. Go to **Credentials** → **New Credential**
2. Select **Header Auth**
3. Fill in:

```
Credential Name: TTS Bearer Auth
Header Name: Authorization
Header Value: Bearer {{$env.TTS_API_KEY}}
```

> ⚠️ **Important**: Keep the `{{$env.TTS_API_KEY}}` syntax exactly as shown. n8n will replace it with the actual key at runtime.

### Step 3: Verify Setup

The credential should look like this in n8n:

```
┌─────────────────────────────────────────┐
│ Credential: TTS Bearer Auth             │
├─────────────────────────────────────────┤
│ Type: Header Auth                       │
│                                         │
│ Header Name:                            │
│ Authorization                           │
│                                         │
│ Header Value:                           │
│ Bearer {{$env.TTS_API_KEY}}            │
│                                         │
│ [Save]                                  │
└─────────────────────────────────────────┘
```

---

## 🧪 Test Your Setup

### Test 1: Check Environment Variable

In an n8n workflow, add a **Code** node:

```javascript
return [{ 
  json: { 
    apiKey: $env.TTS_API_KEY 
  } 
}];
```

**Expected output**: `cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU`

### Test 2: Test HTTP Request

Use the imported workflow and call:

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test"}' \
  --output test.mp3
```

**Expected**: Valid MP3 file

### Test 3: Direct API Test

Test the key directly against your RunPod TTS:

```bash
curl -X POST "https://your-pod-id-8888.proxy.runpod.net/synthesize" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=Hello from Nigeria!" \
  -F "voice_id=naija_female" \
  --output test.mp3
```

---

## 🔐 Security Best Practices

### ✅ DO:
- Store API keys in n8n environment variables
- Use different keys for different environments (dev/prod)
- Rotate keys periodically
- Monitor API key usage
- Keep `generated_api_keys.txt` in a secure location

### ❌ DON'T:
- Hardcode API keys in workflows
- Share API keys in screenshots or logs
- Commit API keys to git
- Use the same key for all integrations
- Share keys via unencrypted channels

---

## 📊 API Key Management

### Key Rotation

If you need to rotate keys:

1. **Generate new keys**:
   ```bash
   python3 scripts/generate_api_keys.py -n 5
   ```

2. **Update n8n environment variable** with new key

3. **Test workflows** to ensure they still work

4. **Revoke old key** (if database-backed)

### Key Assignment

Suggested usage:

| Key | Purpose | Location |
|-----|---------|----------|
| Key #1 | n8n workflows | n8n environment |
| Key #2 | Direct API calls | Local `.env.tts` |
| Key #3 | Twilio integration | Twilio webhook config |
| Key #4 | Mobile app | App config |
| Key #5 | Backup/Testing | Keep in reserve |

---

## 🐛 Troubleshooting

### "Unauthorized" or 401 Error

**Cause**: API key not set or incorrect

**Fix**:
1. Check environment variable is set: `TTS_API_KEY=cw_live_...`
2. Verify credential uses: `Bearer {{$env.TTS_API_KEY}}`
3. Check for typos in the key
4. Test key directly with curl (see Test 3 above)

### "Cannot find $env.TTS_API_KEY"

**Cause**: Environment variable not set in n8n

**Fix**:
1. Go to n8n Settings → Environments
2. Add `TTS_API_KEY` variable
3. Restart n8n (if self-hosted)
4. Re-test workflow

### "Credential not found"

**Cause**: Credential name mismatch

**Fix**:
1. Check credential name is exactly: `TTS Bearer Auth`
2. Or update HTTP Request node to use your credential name

---

## 🎯 Quick Reference

### For n8n Environment Variables:

```bash
TTS_BASE_URL=https://your-pod-id-8888.proxy.runpod.net
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
DEFAULT_VOICE_ID=naija_female
```

### For n8n Header Auth Credential:

```
Name: TTS Bearer Auth
Header Name: Authorization
Header Value: Bearer {{$env.TTS_API_KEY}}
```

### For Local Testing (.env.tts):

```bash
TTS_BASE_URL=https://your-pod-id-8888.proxy.runpod.net
TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
DEFAULT_VOICE_ID=naija_female
```

---

## ✅ Setup Checklist

- [ ] Choose which API key to use (recommend Key #1)
- [ ] Set `TTS_API_KEY` in n8n environment variables
- [ ] Create `TTS Bearer Auth` credential with correct syntax
- [ ] Import `tts_workflow.json`
- [ ] Test with curl command
- [ ] Verify MP3 is generated
- [ ] Store remaining keys securely
- [ ] Document which key is used where

---

**Status**: 🔑 **All 5 production API keys available**  
**Recommended for n8n**: `cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU` (Key #1)  
**Security**: ✅ Use environment variables, never hardcode

---

**Next**: Set the environment variable in n8n and create the credential!

