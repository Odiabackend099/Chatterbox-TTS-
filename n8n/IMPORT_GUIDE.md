# 📥 n8n Import Guide

## ✅ JSON Files Ready for Import

Both workflow files are **fully compatible** with n8n and ready to import.

---

## 📦 What Was Fixed

### ✓ Updated to Latest n8n Format

**Changes Made:**

1. **Node Type Versions Updated**
   - Webhook: `1.1` (latest)
   - Set Node: `3.3` (latest with assignments structure)
   - HTTP Request: `4.2` (latest)
   - Respond to Webhook: `1.1` (latest)

2. **Proper UUID Node IDs**
   - Changed from simple IDs to proper UUIDs
   - Ensures compatibility with all n8n versions

3. **Updated Set Node Structure**
   - Changed from old `values.string` to new `assignments.assignments`
   - Uses modern `mode: "manual"` parameter
   - Proper typing with `type: "string"`

4. **Fixed HTTP Request Parameters**
   - Changed `specifyBody: "form-data"` to `"multipart-form-data"` (correct format)
   - Updated `options.response` structure with all required fields
   - Fixed retry structure: `waitBetweenRetries` instead of `retryInterval`

5. **Modern Expression Syntax**
   - Changed `$json["field"]` to `$json.field` (cleaner)
   - Used optional chaining: `$json.body?.text` (safer)
   - Removed escaped quotes in expressions

6. **Added Metadata**
   - Added `meta.instanceId` field
   - Ensures proper workflow tracking

---

## 🚀 How to Import

### Method 1: Import Complete Workflow

1. **Open n8n** → Go to **Workflows**
2. Click **Import from File** (or press `Ctrl+O` / `Cmd+O`)
3. Select `n8n/tts_workflow.json`
4. Click **Import**

The workflow will appear with 4 connected nodes:
```
Webhook → Set → HTTP Request → Respond to Webhook
```

### Method 2: Import Single Node

1. **Open existing workflow** in n8n
2. Click **+** to add a node
3. Click **Import from URL or File**
4. Select `n8n/tts_http_node.json`
5. Connect it to your existing nodes

---

## ⚙️ Setup After Import

### 1. Set Environment Variables

Go to **Settings** → **Environments** and add:

```bash
TTS_BASE_URL=https://your-pod-id-8888.proxy.runpod.net
TTS_API_KEY=cw_demo_12345
DEFAULT_VOICE_ID=naija_female
```

### 2. Create HTTP Header Auth Credential

**Option A: During First Activation**
- When you activate the workflow, n8n will prompt you to create credentials
- Click **Create New Credential**
- Select **Header Auth**
- Fill in:
  - **Name**: `TTS Bearer Auth`
  - **Header Name**: `Authorization`
  - **Header Value**: `Bearer {{$env.TTS_API_KEY}}`

**Option B: Manual Creation**
1. Go to **Credentials** → **Add Credential**
2. Search for **Header Auth**
3. Create with:
   - **Name**: `TTS Bearer Auth`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bearer {{$env.TTS_API_KEY}}`
4. Save

> **Important**: The credential name must be exactly `TTS Bearer Auth` or update the node's credential reference.

### 3. Activate Workflow

1. Toggle the workflow to **Active**
2. Click on the **Webhook** node
3. Copy the **Production URL** (e.g., `https://your-n8n.com/webhook/tts-trigger`)

---

## 🧪 Testing

### Test with cURL

```bash
# JSON body
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello from Nigeria!", "voice_id": "naija_female"}' \
  --output test.mp3

# Form data
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -F "text=Hello from Nigeria!" \
  -F "voice_id=naija_female" \
  --output test.mp3

# Minimal (uses defaults)
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test"}' \
  --output test.mp3
```

### Test from n8n UI

1. Click **Test workflow**
2. Click **Execute Workflow** on the Webhook node
3. Use the test webhook URL in another tool/browser
4. Check execution results

---

## 📊 Workflow Details

### Node Breakdown

**1. Webhook Node** (`Webhook`)
- Accepts POST requests at `/tts-trigger`
- Response mode: `responseNode` (waits for response from last node)
- Accepts both JSON and form data

**2. Set Node** (`Set`)
- Extracts `text` and `voice_id` from request
- Handles both `$json.body.text` (nested) and `$json.text` (direct)
- Falls back to environment variable or hardcoded default
- Uses modern assignments structure

**3. HTTP Request Node** (`HTTP Request`)
- Calls TTS API with Bearer auth
- Sends multipart form data
- Returns binary MP3 file
- 30-second timeout with 3 retries

**4. Respond to Webhook Node** (`Respond to Webhook`)
- Returns binary MP3 to webhook caller
- Sets proper audio headers
- Suggests filename: `synthesized.mp3`

### Data Flow

```
Input (Webhook):
{
  "text": "Hello from Nigeria!",
  "voice_id": "naija_female"
}
    ↓
Set Node Output:
{
  "text": "Hello from Nigeria!",
  "voice_id": "naija_female"
}
    ↓
HTTP Request Input (Form Data):
POST https://your-pod.runpod.net/api/tts
Authorization: Bearer cw_demo_12345
text=Hello from Nigeria!
voice_id=naija_female
    ↓
HTTP Request Output (Binary):
{
  "data": <Buffer ff fb ... MP3 bytes>
}
    ↓
Webhook Response:
Content-Type: audio/mpeg
Content-Disposition: attachment; filename="synthesized.mp3"
<MP3 binary data>
```

---

## 🔧 Customization

### Change Default Voice

Edit the **Set** node → `voice_id` assignment:

```javascript
={{ $json.body?.voice_id || $json.voice_id || $env.DEFAULT_VOICE_ID || 'your_voice_here' }}
```

### Add Audio Storage (Save to S3)

After **HTTP Request** node, add:
1. **AWS S3** node (type: `n8n-nodes-base.awsS3`)
2. Configure to upload binary file
3. Get public URL
4. Optionally send URL to Twilio or other service

### Add Error Handling

After **HTTP Request** node:
1. Add **IF** node to check for errors
2. Add **Send Email** or **Slack** node for notifications
3. Add **Respond to Webhook** with error message

---

## 🐛 Troubleshooting

### "Credential not found"

**Cause**: Credential name mismatch

**Fix**:
1. Check credential name is exactly: `TTS Bearer Auth`
2. Or edit the **HTTP Request** node → **Credentials** section
3. Select your existing credential

### "Cannot read property of undefined"

**Cause**: Set node trying to access non-existent fields

**Fix**: The Set node handles this with optional chaining (`?.`)
- If still seeing errors, check incoming data structure
- Add **Edit Fields** node before Set to inspect data

### "Response is JSON, not binary"

**Cause**: TTS API returned error instead of MP3

**Fix**:
1. Check TTS_BASE_URL is correct
2. Verify TTS_API_KEY is valid
3. Test direct API call:
   ```bash
   curl $TTS_BASE_URL/api/tts \
     -H "Authorization: Bearer $TTS_API_KEY" \
     -F "text=Test" --output test.mp3
   ```

### "Timeout" errors

**Fix**: Increase timeout in HTTP Request node:
1. Click **HTTP Request** node
2. **Options** → **Response** → **Timeout**
3. Change from `30000` to `60000` (60 seconds)

### "Invalid webhook URL"

**Cause**: Webhook not activated

**Fix**:
1. Make sure workflow is **Active** (toggle at top)
2. Use the **Production URL**, not Test URL
3. Check webhook path is accessible (no firewall blocks)

---

## 🎯 Advanced Use Cases

### 1. Pre-process Text

Add **Code** node before Set to:
- Limit text length
- Remove special characters
- Translate text
- Apply text-to-speech optimizations

### 2. Post-process Audio

Add nodes after HTTP Request to:
- Convert MP3 to other formats
- Adjust audio levels
- Add background music
- Concatenate multiple TTS outputs

### 3. Integrate with Twilio

```
Webhook → Set → HTTP Request → S3 Upload → Twilio API
                                          ↓
                                   Respond to Webhook
```

See main TTS_INTEGRATION_SETUP.md for Twilio guide.

### 4. Cache Common Phrases

Add **Redis** or **Memory** node to cache:
- Check cache before calling TTS
- Store generated audio for reuse
- Reduce API calls and costs

---

## 📚 Additional Resources

- **n8n Documentation**: https://docs.n8n.io
- **HTTP Request Node**: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.httprequest/
- **Webhook Node**: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- **Set Node**: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.set/

---

## ✅ Validation Checklist

Before using in production:

- [ ] JSON files validated (both pass `json.tool`)
- [ ] Environment variables set in n8n
- [ ] Credential created and linked
- [ ] Workflow imported successfully
- [ ] Workflow activated
- [ ] Test webhook URL works
- [ ] MP3 file generates correctly
- [ ] Audio quality is acceptable
- [ ] Error handling tested
- [ ] Performance is acceptable

---

**Status**: ✅ Ready to Import  
**Compatibility**: n8n v1.0+  
**Last Updated**: 2025-10-08  
**Validation**: Both JSON files validated ✓

---

Need help? See `README.md` in this folder or main `TTS_INTEGRATION_SETUP.md`

