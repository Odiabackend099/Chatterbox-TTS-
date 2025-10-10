# 🧪 Test Your n8n Webhook Trigger - READY NOW

**Status**: ✅ Test script created  
**Script**: `test_n8n_webhook_trigger.sh`

---

## 📋 **Quick Test (3 Steps)**

### **Step 1: Get Your n8n Webhook URL**

1. Open your n8n workflow in browser
2. Click on the **Webhook** node (the first node)
3. Look for "Webhook URLs" panel
4. Copy the **Production URL**

It should look like:
```
https://your-n8n-instance.com/webhook/tts-trigger
```

Or if running locally:
```
http://localhost:5678/webhook/tts-trigger
```

---

### **Step 2: Activate Your Workflow**

**IMPORTANT**: The webhook won't work unless the workflow is **ACTIVE**.

1. Click the toggle switch at top-right of your workflow
2. Ensure it says "Active" (green)

---

### **Step 3: Run the Test**

```bash
cd /Users/odiadev/chatterbox-twilio-integration

# Replace with YOUR actual webhook URL
./test_n8n_webhook_trigger.sh "https://your-n8n-instance.com/webhook/tts-trigger"
```

---

## ✅ **Expected Output**

If working correctly:
```
🧪 Testing n8n Webhook Trigger
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Webhook URL: https://your-n8n-instance.com/webhook/tts-trigger

📤 Test 1: Minimal Payload
✅ Test 1 PASSED - HTTP 200 received

📤 Test 2: Full Payload with Voice
✅ Test 2 PASSED - HTTP 200 received

📤 Test 3: Nested Body Structure
✅ Test 3 PASSED - HTTP 200 received

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Webhook Trigger Tests Complete!
```

---

## 🐛 **Troubleshooting**

### ❌ **HTTP 404 - Webhook Not Found**

**Cause**: Workflow is not activated OR wrong URL

**Fix**:
1. Activate the workflow (toggle at top-right)
2. Double-check the webhook URL (copy again from Webhook node)
3. Ensure path matches: `/webhook/tts-trigger`

---

### ❌ **Connection Refused / Timeout**

**Cause**: n8n is not running OR firewall blocking

**Fix**:
1. Check if n8n is running:
   ```bash
   # If Docker:
   docker ps | grep n8n
   
   # If local:
   curl http://localhost:5678/
   ```
2. If using cloud n8n, check your instance URL
3. Check firewall/network settings

---

### ❌ **HTTP 500 - Internal Server Error**

**Cause**: Workflow has errors (missing nodes, wrong connections)

**Fix**:
1. Check n8n workflow execution history (click "Executions" in left sidebar)
2. Look for error messages in the failed execution
3. Most common issue: **No nodes connected after webhook**
   - You need to connect: Webhook → Set → HTTP Request → Respond

---

## 🔧 **Manual Test (Alternative)**

If you don't have the script working, test manually with curl:

```bash
curl -X POST "YOUR_WEBHOOK_URL_HERE" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test from terminal", "voice": "emily-en-us"}' \
  -v
```

Look for:
- `< HTTP/1.1 200 OK` ✅ Good
- `< HTTP/1.1 404 Not Found` ❌ Workflow not active or wrong URL
- `< HTTP/1.1 500` ❌ Workflow has errors

---

## 📊 **What Happens Next?**

Once the webhook trigger works:

1. **Webhook receives data** ✅ (you just tested this)
2. **Add Set node** - Extract text and voice parameters
3. **Add HTTP Request node** - Call RunPod TTS API
4. **Add Respond to Webhook node** - Return audio file

**Want me to create the complete workflow?** Let me know!

---

## 🎯 **Need Help?**

Common questions:

**Q: Where is n8n running?**
A: Check if you have n8n cloud account or running locally (docker/npm)

**Q: What if I don't have n8n yet?**
A: Install options:
- Cloud: https://n8n.io (free tier)
- Docker: `docker run -it --rm -p 5678:5678 n8nio/n8n`
- NPM: `npx n8n`

**Q: Can I test without completing the workflow?**
A: Yes! The webhook will return 200 even if no nodes are connected (but won't do anything useful yet)

---

**Status**: ✅ **READY TO TEST**  
**Created**: October 9, 2025  
**Next**: Complete the workflow nodes

