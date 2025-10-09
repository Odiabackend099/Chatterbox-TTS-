# Generate 30-Second Demo RIGHT NOW

**One command to hear the difference!**

---

## 🚀 On RunPod (Fastest)

```bash
ssh root@<your-runpod-ip> "cd /workspace/chatterbox-twilio-integration && git pull && pip install kokoro-onnx -q && python3 scripts/generate_demo.py"
```

**Then download:**

```bash
scp root@<runpod-ip>:/workspace/chatterbox-twilio-integration/demo_outputs/1_appointment_reminder.wav .
afplay 1_appointment_reminder.wav
```

---

## 🎧 What You'll Hear

**Scenario:** Appointment Reminder (30 seconds)

**Voice:** Professional Female (warm, reassuring)

**Settings:**
- Speed: 0.85x (slower, professional)
- Pitch: -0.2 (lower, authoritative)

**Text:**
> "Good afternoon! This is a friendly reminder from CallWaiting Services. You have an appointment scheduled for tomorrow at 3 PM. Please ensure you arrive 15 minutes early and bring your ID and insurance card. If you need to reschedule, please call us at your earliest convenience. We look forward to seeing you. Thank you!"

---

## ✅ Compare This With Your Current Voice

| Aspect | Current Chatterbox | Kokoro TTS |
|--------|-------------------|------------|
| Pitch | ❌ Too high | ✅ Professional (lower) |
| Speed | ❌ Too fast | ✅ Perfect (0.85x) |
| Tone | ❌ Robotic | ✅ Natural, human-like |
| Quality | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 📝 Step-by-Step (If One-Liner Doesn't Work)

### Step 1: SSH to RunPod
```bash
ssh root@<your-runpod-ip>
```

### Step 2: Pull Code
```bash
cd /workspace/chatterbox-twilio-integration
git pull origin main
```

### Step 3: Install Kokoro
```bash
pip install kokoro-onnx
```

### Step 4: Generate Demo
```bash
python3 scripts/generate_demo.py
```

### Step 5: Download (On Your Local Machine)
```bash
scp root@<runpod-ip>:/workspace/chatterbox-twilio-integration/demo_outputs/1_appointment_reminder.wav .
```

### Step 6: Listen
```bash
afplay 1_appointment_reminder.wav  # macOS
aplay 1_appointment_reminder.wav   # Linux
```

---

## 🎯 Quick Decision Matrix

**After listening, ask yourself:**

| Question | If YES | If NO |
|----------|--------|-------|
| Is it more natural than current? | ✅ Use Kokoro | Stay with Chatterbox |
| Is the speed better? | ✅ Use Kokoro | Adjust speed setting |
| Is the pitch better? | ✅ Use Kokoro | Adjust pitch setting |
| Would customers prefer this? | ✅ Use Kokoro | Test another voice |

**If 3+ YES answers → Deploy Kokoro!**

---

## 🚀 Want All 7 Scenarios?

The demo script generates 7 different scenarios:
1. Appointment Reminder (professional female)
2. Order Confirmation (friendly female)
3. Service Update (professional female)
4. Technical Support (business male)
5. Payment Confirmation (British female)
6. Apology (calm female)
7. Announcement (professional male)

**Total time:** 3.5 minutes of demo audio

---

## ⏱️ Time Investment

- **Generate demo:** 2 minutes
- **Download:** 30 seconds
- **Listen:** 30 seconds
- **Decision:** 1 minute

**Total:** ~5 minutes to hear if Kokoro is right for you!

---

**Do it now!** 🎧

```bash
ssh root@<your-runpod-ip> "cd /workspace/chatterbox-twilio-integration && git pull && python3 scripts/generate_demo.py"
```
