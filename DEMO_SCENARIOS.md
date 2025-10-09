# Customer Support Demo Scenarios

**7 professional 30-second customer support scenarios using Kokoro TTS**

---

## 🎯 Purpose

Demonstrate how different Kokoro voices sound in real-world customer support scenarios:
- ✅ Appointment reminders
- ✅ Order confirmations
- ✅ Service updates
- ✅ Technical support
- ✅ Payment confirmations
- ✅ Apologies
- ✅ Announcements

---

## 🚀 Generate Demos (RunPod)

### Step 1: Deploy Kokoro (if not already done)

```bash
ssh root@<your-runpod-ip>
cd /workspace/chatterbox-twilio-integration
git pull origin main
./scripts/deploy_kokoro.sh
```

### Step 2: Generate All Demo Scenarios

```bash
python3 scripts/generate_demo.py
```

**This creates 7 professional audio samples (~30 seconds each)**

**Output:**
```
[1/7] Appointment Reminder
  Voice: af_heart (Professional Female)
  Speed: 0.85x
  Pitch: -0.2
  Duration: 28.5s
  ✓ Saved: demo_outputs/1_appointment_reminder.wav

[2/7] Order Confirmation
  Voice: af_bella (Friendly Female)
  Speed: 0.88x
  Pitch: -0.15
  Duration: 30.2s
  ✓ Saved: demo_outputs/2_order_confirmation.wav

...

✓ Successfully generated 7/7 scenarios
```

### Step 3: Download and Listen

```bash
# Download all demos to your local machine
scp root@<runpod-ip>:/workspace/chatterbox-twilio-integration/demo_outputs/*.wav .

# Play on macOS
afplay 1_appointment_reminder.wav
afplay 2_order_confirmation.wav
afplay 3_service_update.wav
# ... etc

# Or play all in sequence
for f in *.wav; do echo "Playing: $f"; afplay "$f"; done
```

---

## 🎭 Demo Scenarios

### 1. **Appointment Reminder** (28-30s)
- **Voice:** Professional Female (af_heart)
- **Tone:** Warm, reassuring, professional
- **Speed:** 0.85x (slower, clearer)
- **Pitch:** -0.2 (slightly lower for authority)
- **Use Case:** Medical appointments, service bookings
- **Text:**
  > "Good afternoon! This is a friendly reminder from CallWaiting Services. You have an appointment scheduled for tomorrow at 3 PM. Please ensure you arrive 15 minutes early and bring your ID and insurance card..."

---

### 2. **Order Confirmation** (28-32s)
- **Voice:** Friendly Female (af_bella)
- **Tone:** Friendly, energetic, helpful
- **Speed:** 0.88x (slightly slower)
- **Pitch:** -0.15 (natural)
- **Use Case:** E-commerce, order updates
- **Text:**
  > "Hello! Thank you for your order with CloudMaestro Services. Your order number is ABC12345. Your items will be delivered within 3-5 business days. You'll receive a tracking number via email shortly..."

---

### 3. **Service Update** (26-30s)
- **Voice:** Professional Female (af_heart)
- **Tone:** Professional, clear, reassuring
- **Speed:** 0.85x
- **Pitch:** -0.2
- **Use Case:** Subscription services, account updates
- **Text:**
  > "Good morning. This is an important service update from your account manager. Your monthly subscription has been successfully renewed for another month. Your next billing date is the 15th of next month..."

---

### 4. **Technical Support Greeting** (32-35s)
- **Voice:** Business Male (am_michael)
- **Tone:** Professional, trustworthy, helpful
- **Speed:** 0.88x
- **Pitch:** -0.25 (lower for authority)
- **Use Case:** Tech support callbacks, service appointments
- **Text:**
  > "Hello, and thank you for calling Technical Support. This is a courtesy callback regarding your recent service request. Our technician has reviewed your case and scheduled a visit for tomorrow between 2-4 PM..."

---

### 5. **Payment Confirmation** (30-33s)
- **Voice:** British Female (bf_emma)
- **Tone:** Calm, professional, premium
- **Speed:** 0.88x
- **Pitch:** -0.15
- **Use Case:** Billing confirmations, payment receipts
- **Text:**
  > "Good afternoon. This message confirms that your payment of $250 has been successfully processed. Your account is now current, and all services remain active. A receipt has been sent to your email address on file..."

---

### 6. **Calm Support (Apology)** (35-38s)
- **Voice:** Calm Female (af_nicole)
- **Tone:** Empathetic, soothing, apologetic
- **Speed:** 0.80x (slower for empathy)
- **Pitch:** -0.3 (softer tone)
- **Use Case:** Service recovery, apologies, sensitive situations
- **Text:**
  > "Hello. We're calling to sincerely apologize for the service interruption you experienced yesterday. We understand how frustrating this must have been. Our team has identified and resolved the issue..."

---

### 7. **Professional Male Announcement** (30-34s)
- **Voice:** Professional Male (am_adam)
- **Tone:** Authoritative, clear, confident
- **Speed:** 0.90x
- **Pitch:** -0.3 (deeper for authority)
- **Use Case:** Office announcements, system alerts, important notices
- **Text:**
  > "Attention valued customers. Our office will be closed this Monday in observance of the holiday. Normal business hours will resume on Tuesday at 9 AM. For urgent matters during this time, please use our online support portal..."

---

## 🎚️ Voice Settings Comparison

| Scenario | Voice | Speed | Pitch | Tone |
|----------|-------|-------|-------|------|
| Appointment Reminder | af_heart | 0.85x | -0.2 | Professional, warm |
| Order Confirmation | af_bella | 0.88x | -0.15 | Friendly, energetic |
| Service Update | af_heart | 0.85x | -0.2 | Professional, clear |
| Tech Support | am_michael | 0.88x | -0.25 | Helpful, trustworthy |
| Payment Confirmation | bf_emma | 0.88x | -0.15 | Premium, reassuring |
| Apology | af_nicole | 0.80x | -0.3 | Empathetic, calm |
| Announcement | am_adam | 0.90x | -0.3 | Authoritative |

---

## 💡 Key Takeaways

### Speed Settings:
- **0.80x** - Very slow (apologies, sensitive topics)
- **0.85x** - Professional customer support (RECOMMENDED)
- **0.88x** - Slightly slower than normal (business)
- **0.90x** - Normal but clear (announcements)
- **1.00x** - Natural speed (not recommended for customer support)

### Pitch Settings:
- **-0.3** - Lower (authority, urgency, empathy)
- **-0.25** - Slightly lower (professional male)
- **-0.2** - Slightly lower (professional female)
- **-0.15** - Natural professional
- **0.0** - Original voice pitch

### Voice Selection:
- **Customer Support:** `af_heart` (professional female) ⭐
- **Sales/Marketing:** `af_bella` (friendly female)
- **Apologies:** `af_nicole` (calm female)
- **Announcements:** `am_adam` (professional male)
- **Premium Brands:** `bf_emma` (British female)
- **Corporate:** `bm_george` (British male)
- **B2B:** `am_michael` (business male)

---

## 🎯 Recommended Settings for Your Use Case

### CallWaiting Services - Appointment Reminders

**BEST SETTINGS:**
```python
voice = "af_heart"  # Professional female
speed = 0.85        # Slower, more professional
pitch = -0.2        # Slightly lower for authority
```

**Why:**
- ✅ Warm, reassuring tone puts customers at ease
- ✅ Slower speed ensures clarity (especially for dates/times)
- ✅ Lower pitch sounds more professional and trustworthy
- ✅ Perfect for healthcare, professional services

**This is what Demo #1 uses!**

---

## 📊 User Testing Recommendations

1. **Listen to all 7 demos**
2. **Pick your favorite 2-3 voices**
3. **Test with real customers** (A/B testing)
4. **Measure:**
   - Appointment no-show rate
   - Customer callbacks
   - Satisfaction scores
   - Completion rate

5. **Fine-tune:**
   - Adjust speed ±0.05
   - Adjust pitch ±0.1
   - Test different voices

---

## 🚀 Next Steps

1. **Generate demos:** `python3 scripts/generate_demo.py`
2. **Download:** `scp root@<runpod-ip>:.../*.wav .`
3. **Listen:** `afplay 1_appointment_reminder.wav`
4. **Compare:** Listen to all 7 scenarios
5. **Choose:** Pick the best voice for your use case
6. **Integrate:** Update `scripts/server_production.py`
7. **Deploy:** Restart TTS service
8. **Test:** With real appointment reminders
9. **Monitor:** Track customer feedback
10. **Optimize:** Fine-tune settings

---

## 📁 Generated Files

After running `generate_demo.py`:

```
demo_outputs/
├── 1_appointment_reminder.wav          (28s)
├── 2_order_confirmation.wav            (30s)
├── 3_service_update.wav                (26s)
├── 4_technical_support_greeting.wav    (32s)
├── 5_payment_confirmation.wav          (30s)
├── 6_calm_support_(apology).wav        (35s)
└── 7_professional_male_announcement.wav (30s)
```

**Total:** ~3.5 minutes of professional demo audio

---

## 💰 Value

**What you get:**
- 7 professional voice samples
- 7 different scenarios
- 7 different voice profiles
- Real-world customer support examples
- Production-ready quality

**Cost:**
- Commercial TTS service: $50-100 for this
- **Kokoro TTS: $0** ✅

---

**Generate your demos now:**

```bash
ssh root@<your-runpod-ip>
cd /workspace/chatterbox-twilio-integration
python3 scripts/generate_demo.py
```

**Then download and listen to find your perfect voice!** 🎧
