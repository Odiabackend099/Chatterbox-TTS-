# 🚀 START DEPLOYMENT HERE

**Pod**: aav4qfa6yqgt3k (Port 8000)  
**Status**: ✅ Everything ready to deploy  
**Time needed**: 15-20 minutes

---

## ⚡ Quick Start (Copy & Paste)

### **Step 1: Transfer Model Cache (from your local machine)**

```bash
cd /Users/odiadev/chatterbox-twilio-integration
./transfer_model_cache.sh
```

**What it does**: Copies 2-3GB of models from old pod to new pod (saves 10+ minutes)

---

### **Step 2: Deploy Service (in RunPod Web Terminal)**

1. Go to: https://www.runpod.io/console/pods
2. Find pod: `scared_jade_sloth` (aav4qfa6yqgt3k)
3. Click **"Connect"** → **"Start Web Terminal"**
4. Copy-paste these commands:

```bash
cd /workspace
git clone https://github.com/Odiabackend099/Chatterbox-TTS-.git chatterbox-twilio-integration || (cd chatterbox-twilio-integration && git pull)
cd chatterbox-twilio-integration
chmod +x runpod/DEPLOY_PORT_8000.sh
./runpod/DEPLOY_PORT_8000.sh
```

**Wait for**: `🎉 Ready to use!` message

---

### **Step 3: Test Deployment (from your local machine)**

```bash
cd /Users/odiadev/chatterbox-twilio-integration
./test_new_pod.sh
```

**Expected**: `🎉 ALL TESTS PASSED!`

---

### **Step 4: Verify Health**

```bash
curl https://aav4qfa6yqgt3k-8000.proxy.runpod.net/api/health
```

**Expected**: `{"status":"healthy","model_loaded":true}`

---

## ✅ What's Already Done

- ✅ n8n workflows updated with new pod URL
- ✅ All documentation updated
- ✅ Deployment scripts created and tested
- ✅ Port 8000 configured (avoids Jupyter's 8888)
- ✅ Model cache transfer script ready
- ✅ Comprehensive test suite created

---

## 📁 Files You'll Use

| File | Purpose | When |
|------|---------|------|
| `transfer_model_cache.sh` | Transfer models | Step 1 (local) |
| `runpod/DEPLOY_PORT_8000.sh` | Deploy TTS service | Step 2 (RunPod) |
| `test_new_pod.sh` | Test everything | Step 3 (local) |

---

## 🎯 Success Checklist

After deployment, verify:

- [ ] Health endpoint returns `healthy` and `model_loaded: true`
- [ ] `test_new_pod.sh` passes all 5 tests
- [ ] Generated audio files play correctly
- [ ] n8n workflows tested (optional, but already updated)

---

## 🔄 Migration Summary

| | Old Pod | New Pod |
|---|---------|---------|
| **Pod ID** | a288y3vpbfxwkk | aav4qfa6yqgt3k |
| **Port** | 8888 | 8000 |
| **URL** | https://a288y3vpbfxwkk-8888.proxy.runpod.net | https://aav4qfa6yqgt3k-8000.proxy.runpod.net |

---

## 📚 Documentation

- **Quick Commands**: `DEPLOY_NEW_POD_QUICK.txt`
- **Full Guide**: `DEPLOY_NEW_POD.md`
- **Implementation Summary**: `MIGRATION_COMPLETE.md`
- **n8n Setup**: `N8N_COMPLETE_SETUP.md`

---

## 🐛 Troubleshooting

### Service not responding?

```bash
# On RunPod (Web Terminal)
cd /workspace/chatterbox-twilio-integration
tail -f logs/tts.log
```

### Model not loading?

```bash
# Verify model cache exists
ls -lh /workspace/model_cache/

# Wait 2-3 minutes for GPU loading
```

### Wrong port?

```bash
# Check service is on port 8000
netstat -tlnp | grep 8000
```

---

## 💰 Cost Savings

Once new pod works:
1. Verify everything thoroughly (24-48 hours)
2. Stop old pod via RunPod dashboard
3. **Save**: ~$180/month ($0.25/hr)

---

## 🚨 Important

- **Don't skip Step 1** (model cache transfer) - saves significant time
- **Monitor logs** during first startup
- **Test thoroughly** before stopping old pod
- **Keep old pod** running for 24-48 hours as backup

---

**Ready?** Run this command to start:

```bash
./transfer_model_cache.sh
```

Then follow Steps 2-4 above!

---

**Status**: ✅ **READY TO DEPLOY**  
**Created**: October 10, 2025  
**Risk Level**: LOW (all configs tested)

🎉 **Let's deploy!**

