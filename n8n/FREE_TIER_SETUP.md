# 🆓 n8n Free Tier Setup (No Environment Variables)

**Problem**: n8n Cloud/Free tier doesn't support environment variables.

**Solution**: Hardcode values directly in credentials and nodes.

---

## 🔑 Your API Key (Use Key #1)

```
cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

---

## 🚀 Setup for n8n Free Tier (3 Steps)

### Step 1: Create Header Auth Credential

1. Go to **Credentials** → **New Credential**
2. Select **Header Auth**
3. Fill in **with actual values** (no environment variables):

```
Credential Name: TTS Bearer Auth

Header Name: 
Authorization

Header Value:
Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```

⚠️ **Important**: Use the **actual API key** directly, not `{{$env.TTS_API_KEY}}`

4. Click **Save**

---

### Step 2: Import Workflow

1. Download `tts_workflow.json` 
2. **Before importing**, we need to edit it to remove environment variable references

I'll create a free-tier compatible version for you below.

---

### Step 3: Update Nodes After Import

After importing the workflow, you need to manually update these values:

#### A. HTTP Request Node

1. Click on **HTTP Request** node
2. Update URL from:
   ```
   {{ $env.TTS_BASE_URL }}/synthesize
   ```
   
   To your actual RunPod URL:
   ```
   https://YOUR-POD-ID-8888.proxy.runpod.net/synthesize
   ```

3. Make sure **Credential** is set to `TTS Bearer Auth`

#### B. Set Node (for default voice)

1. Click on **Set** node
2. Find the `voice_id` assignment
3. Update the default from:
   ```
   {{ $json.body?.voice_id || $json.voice_id || $env.DEFAULT_VOICE_ID || 'naija_female' }}
   ```
   
   To:
   ```
   {{ $json.body?.voice_id || $json.voice_id || 'naija_female' }}
   ```

---

## 📦 Free Tier Compatible Workflow

I'll create a version with hardcoded values. You'll need to replace:
- `YOUR-POD-ID` with your actual RunPod pod ID

Save this as `tts_workflow_free_tier.json`:

```json
{
  "name": "TTS Synthesis Workflow (Free Tier)",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "POST",
        "path": "tts-trigger",
        "responseMode": "responseNode",
        "options": {}
      },
      "id": "a1b2c3d4-e5f6-47a8-b9c0-d1e2f3a4b5c6",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 1.1,
      "position": [240, 280],
      "webhookId": "tts-synthesis-trigger"
    },
    {
      "parameters": {
        "mode": "manual",
        "duplicateItem": false,
        "assignments": {
          "assignments": [
            {
              "id": "text-assignment",
              "name": "text",
              "value": "={{ $json.body?.text || $json.text || 'Hello from Nigeria!' }}",
              "type": "string"
            },
            {
              "id": "voice-assignment",
              "name": "voice_id",
              "value": "={{ $json.body?.voice_id || $json.voice_id || 'naija_female' }}",
              "type": "string"
            }
          ]
        },
        "options": {}
      },
      "id": "b2c3d4e5-f6a7-48b9-c0d1-e2f3a4b5c6d7",
      "name": "Set",
      "type": "n8n-nodes-base.set",
      "typeVersion": 3.3,
      "position": [440, 280]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "https://YOUR-POD-ID-8888.proxy.runpod.net/synthesize",
        "authentication": "predefinedCredentialType",
        "nodeCredentialType": "httpHeaderAuth",
        "sendBody": true,
        "specifyBody": "multipart-form-data",
        "bodyParameters": {
          "parameters": [
            {
              "name": "text",
              "value": "={{ $json.text }}"
            },
            {
              "name": "voice_id",
              "value": "={{ $json.voice_id }}"
            }
          ]
        },
        "options": {
          "timeout": 30000,
          "response": {
            "response": {
              "neverError": false,
              "responseFormat": "file",
              "outputPropertyName": "data",
              "fullResponse": false
            }
          },
          "retry": {
            "retry": {
              "maxRetries": 3,
              "retryOnFail": true,
              "waitBetweenRetries": 1000
            }
          }
        }
      },
      "id": "c3d4e5f6-a7b8-49c0-d1e2-f3a4b5c6d7e8",
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.2,
      "position": [640, 280],
      "credentials": {
        "httpHeaderAuth": {
          "id": "{{ $credentials.httpHeaderAuth }}",
          "name": "TTS Bearer Auth"
        }
      }
    },
    {
      "parameters": {
        "respondWith": "binary",
        "options": {
          "responseHeaders": {
            "entries": [
              {
                "name": "Content-Type",
                "value": "audio/mpeg"
              },
              {
                "name": "Content-Disposition",
                "value": "attachment; filename=\"synthesized.mp3\""
              }
            ]
          }
        }
      },
      "id": "d4e5f6a7-b8c9-40d1-e2f3-a4b5c6d7e8f9",
      "name": "Respond to Webhook",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1.1,
      "position": [840, 280]
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [
          {
            "node": "Set",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Set": {
      "main": [
        [
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "HTTP Request": {
      "main": [
        [
          {
            "node": "Respond to Webhook",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "pinData": {},
  "settings": {
    "executionOrder": "v1"
  },
  "staticData": null,
  "tags": [],
  "triggerCount": 0,
  "updatedAt": "2025-10-08T00:00:00.000Z",
  "versionId": "1",
  "meta": {
    "instanceId": "your-instance-id"
  }
}
```

---

## 🔧 Quick Setup Instructions

### Option A: Manual Setup (Recommended)

1. **Create credential** (Step 1 above) with actual API key
2. **Import** original `tts_workflow.json`
3. **Edit HTTP Request node** → Change URL to your RunPod URL
4. **Edit Set node** → Remove `$env.DEFAULT_VOICE_ID` reference
5. **Save & Activate**

### Option B: Use Pre-configured File

1. **Create credential** (Step 1 above) with actual API key
2. **Copy the JSON above** to `tts_workflow_free_tier.json`
3. **Replace** `YOUR-POD-ID` with your actual pod ID
4. **Import** the file into n8n
5. **Save & Activate**

---

## 🔐 Security Note

⚠️ **Important**: Since you're hardcoding the API key in the credential:

- ✅ Credentials are encrypted by n8n
- ✅ Not visible in workflow exports
- ⚠️ Anyone with access to your n8n workspace can see/use the credential
- ⚠️ Don't share workflow screenshots showing credential names

**Best Practice**: Use a dedicated API key for n8n (like Key #1) so you can revoke it independently if needed.

---

## 📝 What to Replace

### In Credential:
```
Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```
✅ Use this exactly as shown (your Key #1)

### In HTTP Request Node URL:
```
https://YOUR-POD-ID-8888.proxy.runpod.net/synthesize
```

Replace `YOUR-POD-ID` with your actual RunPod pod ID.

**Example**:
```
https://abc123def456-8888.proxy.runpod.net/synthesize
```

---

## 🧪 Testing

After setup, test with:

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria!"}' \
  --output test.mp3
```

Should return a valid MP3 file.

---

## 🆙 Upgrade Path

If you later upgrade to n8n self-hosted or paid tier:

1. **Add environment variables**:
   ```bash
   TTS_BASE_URL=https://your-pod-id-8888.proxy.runpod.net
   TTS_API_KEY=cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
   DEFAULT_VOICE_ID=naija_female
   ```

2. **Update credential** to use:
   ```
   Bearer {{$env.TTS_API_KEY}}
   ```

3. **Update HTTP Request URL** to:
   ```
   {{ $env.TTS_BASE_URL }}/synthesize
   ```

4. **Update Set node voice_id** to:
   ```
   {{ $json.body?.voice_id || $json.voice_id || $env.DEFAULT_VOICE_ID || 'naija_female' }}
   ```

---

## ✅ Free Tier Checklist

- [ ] Created Header Auth credential with actual API key
- [ ] API key includes `Bearer ` prefix in credential
- [ ] Imported workflow
- [ ] Updated HTTP Request URL with actual RunPod URL
- [ ] Updated Set node to remove environment variable references
- [ ] Tested with curl command
- [ ] Received valid MP3 file
- [ ] Workflow activated

---

## 🐛 Troubleshooting

### "Cannot find credential"

**Fix**: Make sure credential is named exactly `TTS Bearer Auth` or update the HTTP Request node to use your credential name.

### "401 Unauthorized"

**Fix**: Check credential has:
```
Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU
```
(with `Bearer ` at the start)

### "Cannot connect"

**Fix**: Verify your RunPod URL is correct and pod is running.

---

## 📊 Comparison: Free vs Paid Tier

| Feature | Free/Cloud Tier | Self-Hosted/Paid |
|---------|-----------------|------------------|
| Environment Variables | ❌ Not available | ✅ Available |
| Credentials | ✅ Available | ✅ Available |
| API Key Security | ⚠️ Hardcoded in credential | ✅ Environment variable |
| Setup Complexity | 🟡 Medium (manual edits) | 🟢 Easy (import & go) |
| Recommended for | Development/Testing | Production |

---

**Status**: 🆓 Free tier compatible setup complete!  
**Your API Key**: `cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU`  
**Next**: Create the credential with the actual key, then import workflow!

