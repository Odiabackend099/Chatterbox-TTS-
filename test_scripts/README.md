# 🎙️ TTS Test Scripts

Natural-sounding scripts for testing your Chatterbox TTS service.

---

## 📝 Available Scripts

### 1. One-Minute Welcome Script
**File**: `one_minute_script.txt`  
**Length**: ~160 words (~60 seconds)  
**Use Case**: Company introduction, welcome message  
**Voices**: Works great with both `naija_female` and `naija_male`

**Preview**:
> "Welcome to Chatterbox, Nigeria's premier text-to-speech service. We're changing the way businesses communicate..."

---

## 🚀 Quick Generate

### Generate All Samples:
```bash
./test_scripts/generate_audio.sh
```

This creates 5 audio samples in `outputs/audio_samples/`:
1. **welcome_female_1min.mp3** - Welcome script (female)
2. **welcome_male_1min.mp3** - Welcome script (male)
3. **customer_service.mp3** - Bank IVR message
4. **delivery_notification.mp3** - Delivery alert
5. **educational_content.mp3** - Tech education intro

---

## 🎯 Generate Single Audio

### Using curl (Direct API):

```bash
# Female voice
curl -X POST "https://sbwpfh7exfn63d-8888.proxy.runpod.net/api/tts" \
  -H "Authorization: Bearer cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU" \
  -F "text=$(cat test_scripts/one_minute_script.txt)" \
  -F "voice_id=naija_female" \
  --output my_audio.mp3
```

### Using n8n:

```bash
curl -X POST "https://your-n8n.com/webhook/tts-trigger" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"$(cat test_scripts/one_minute_script.txt | tr '\n' ' ')\", \"voice_id\": \"naija_female\"}" \
  --output my_audio.mp3
```

---

## 📊 Script Details

### Word Counts & Timing

| Script | Words | Est. Duration | Use Case |
|--------|-------|---------------|----------|
| One-Minute Welcome | 160 | 60 seconds | Company intro |
| Customer Service | 65 | 25 seconds | IVR menu |
| Delivery Notification | 70 | 28 seconds | SMS/Call alert |
| Educational Content | 85 | 32 seconds | E-learning intro |

**Speaking Rate**: ~150-160 words per minute (natural pace)

---

## ✍️ Create Your Own Script

### Guidelines for Natural Speech:

1. **Length**: 150-160 words = ~1 minute
2. **Sentences**: Keep to 15-20 words max
3. **Punctuation**: Use commas and periods for natural pauses
4. **Numbers**: Spell out for better pronunciation
   - ❌ "2025" → ✅ "two thousand twenty five"
   - ❌ "JK20259" → ✅ "J-K-2-0-2-5-9"
5. **Local context**: Use Nigerian place names, brands
6. **Tone**: Conversational, not robotic

### Example Template:

```
[Opening greeting - 1 sentence]

[Main message - 2-3 sentences explaining key points]

[Benefits or features - 2-3 sentences with examples]

[Call to action - 1 sentence]
```

---

## 🎨 Script Categories

### Business/Corporate:
- Welcome messages
- Company introductions
- Product announcements
- Service updates

### Customer Service:
- IVR menus
- Hold messages
- Appointment reminders
- Payment confirmations

### E-commerce:
- Order confirmations
- Delivery notifications
- Promotional messages
- Review requests

### Education:
- Course introductions
- Lesson summaries
- Quiz instructions
- Achievement notifications

### Healthcare:
- Appointment reminders
- Health tips
- Prescription notifications
- Emergency instructions

---

## 🎭 Voice Selection Guide

### naija_female
**Best for**:
- Customer service
- Friendly announcements
- Educational content
- Healthcare messages

**Characteristics**: Warm, clear, professional

### naija_male
**Best for**:
- Corporate announcements
- Technical content
- Security messages
- News/updates

**Characteristics**: Authoritative, confident, clear

---

## 📝 Sample Scripts Library

### Banking IVR:
```
Welcome to GTBank customer service. For account inquiries, press one. 
For card services, press two. For loan information, press three. 
To speak with a representative, press four. For all other services, press five.
```

### E-commerce Order:
```
Hello! Your order from Konga has been confirmed. We've received your payment 
of fifteen thousand naira. Your items will be delivered to your address in 
Victoria Island within three to five business days. Track your order using 
reference number K-G-A-2-0-2-5-1-2-3.
```

### Educational:
```
Welcome to Python Programming Fundamentals. In this course, you'll learn 
the basics of coding, from variables and functions to building your first 
application. By the end, you'll be able to create simple programs and 
understand how software works. Let's begin!
```

### Healthcare:
```
This is a reminder from Lagos University Teaching Hospital. Your appointment 
with Doctor Adeyemi is scheduled for tomorrow, Friday the fifteenth, at 
ten AM. Please arrive fifteen minutes early and bring your patient card. 
If you need to reschedule, call zero eight zero three four five six seven eight nine.
```

### Real Estate:
```
Welcome to Property Pro Nigeria. We have over five thousand listings across 
Lagos, Abuja, and Port Harcourt. Whether you're buying, selling, or renting, 
our expert agents are here to help you find your perfect home. Browse our 
website or call us today for a free consultation.
```

---

## 🧪 Testing Checklist

After generating audio:

- [ ] Audio file is created (check file size > 1KB)
- [ ] Audio plays without errors
- [ ] Voice sounds natural and clear
- [ ] Pronunciation is correct
- [ ] Pace is appropriate (not too fast/slow)
- [ ] Volume is consistent
- [ ] No distortion or artifacts
- [ ] Background noise is minimal
- [ ] Emphasis on key words is natural

---

## 🔧 Customization

### Adjust Speed:
Most TTS systems support speed adjustment. Check your API docs for parameters like:
- `speed_factor: 0.8` (slower)
- `speed_factor: 1.0` (normal)
- `speed_factor: 1.2` (faster)

### Adjust Tone:
Some systems support emotional tone:
- `tone: "friendly"`
- `tone: "professional"`
- `tone: "urgent"`

### Add Pauses:
Use punctuation for natural pauses:
- Period `.` → 0.5-1 second pause
- Comma `,` → 0.2-0.3 second pause
- Ellipsis `...` → 1-2 second pause

---

## 📦 Output Formats

Default: **MP3** (compressed, small file size)

Other options (if supported):
- WAV (uncompressed, high quality)
- OGG (alternative compression)
- FLAC (lossless)

---

## 💡 Tips for Best Results

1. **Test short first**: Start with 1-2 sentences before generating long scripts
2. **Use both voices**: Compare male and female for your use case
3. **Listen carefully**: Check for mispronunciations
4. **Iterate**: Adjust wording if something sounds off
5. **Save favorites**: Keep track of phrases that work well
6. **Consider context**: Phone calls need different pacing than videos

---

## 📞 Integration Examples

### With Twilio:
```python
# Generate TTS
audio_url = generate_and_upload_tts(script_text)

# Use in call
twiml = f'<Response><Play>{audio_url}</Play></Response>'
```

### With n8n:
```
Trigger → Read Script File → TTS Node → S3 Upload → Send URL
```

### With Web App:
```javascript
// Fetch audio
const response = await fetch('/api/tts', {
  method: 'POST',
  body: JSON.stringify({ text: scriptText })
});

// Play in browser
const audioBlob = await response.blob();
const audioUrl = URL.createObjectURL(audioBlob);
const audio = new Audio(audioUrl);
audio.play();
```

---

## 🎉 Next Steps

1. **Generate samples**: Run `./test_scripts/generate_audio.sh`
2. **Listen and compare**: Check all generated files
3. **Create custom scripts**: Use templates above
4. **Integrate**: Add to your application
5. **Share**: Show your team the results!

---

**Need more scripts?** Check out the examples above or create your own using the guidelines! 🚀

