#!/usr/bin/env python3
"""
Twilio + TTS Integration
=========================
Integrates Twilio voice calls with Chatterbox TTS service.

Features:
- Incoming call handling
- Text-to-speech synthesis
- Call recording
- Multi-language support
"""

import os
import httpx
from fastapi import FastAPI, Form, Request, Response
from fastapi.responses import PlainTextResponse
from twilio.rest import Client
from twilio.twiml.voice_response import VoiceResponse, Gather
import logging
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER")

TTS_BASE_URL = os.getenv("TTS_BASE_URL", "https://bh1ki2a4eg8ufz-8004.proxy.runpod.net")
TTS_API_KEY = os.getenv("TTS_API_KEY", "cw_live_gbgRbtMdunztT_nQ-scINXW7EuG_VTCMB9MkwPhlRFU")
DEFAULT_VOICE_ID = os.getenv("DEFAULT_VOICE_ID", "naija_female")

WEBHOOK_BASE_URL = os.getenv("WEBHOOK_BASE_URL", "https://your-server.com")

# Initialize Twilio client
twilio_client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

# Initialize FastAPI
app = FastAPI(title="Twilio TTS Integration")


async def generate_tts(text: str, voice_id: str = DEFAULT_VOICE_ID) -> bytes:
    """
    Generate TTS audio from text using RunPod TTS service.
    
    Args:
        text: Text to synthesize
        voice_id: Voice ID to use
    
    Returns:
        MP3 audio bytes
    """
    url = f"{TTS_BASE_URL}/synthesize"
    headers = {"Authorization": f"Bearer {TTS_API_KEY}"}
    data = {"text": text, "voice_id": voice_id}
    
    logger.info(f"Generating TTS: {text[:50]}... (voice: {voice_id})")
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, headers=headers, data=data)
        response.raise_for_status()
        
        logger.info(f"TTS generated: {len(response.content)} bytes")
        return response.content


async def upload_to_storage(audio_data: bytes, filename: str) -> str:
    """
    Upload audio to public storage and return URL.
    
    For now, this is a placeholder. Implement with:
    - AWS S3
    - Supabase Storage
    - CloudFlare R2
    - Your own server
    
    Args:
        audio_data: MP3 bytes
        filename: Desired filename
    
    Returns:
        Public URL to the audio file
    """
    # TODO: Implement actual storage
    # For now, return a placeholder
    logger.warning("Storage not implemented - using placeholder URL")
    return f"{WEBHOOK_BASE_URL}/audio/{filename}"


@app.get("/")
def root():
    """Root endpoint with service information."""
    return {
        "service": "Twilio TTS Integration",
        "version": "1.0.0",
        "twilio_number": TWILIO_PHONE_NUMBER,
        "endpoints": {
            "voice": "/twilio/voice",
            "gather": "/twilio/gather",
            "status": "/twilio/status"
        }
    }


@app.get("/health")
def health():
    """Health check endpoint."""
    return {"status": "healthy"}


@app.post("/twilio/voice", response_class=PlainTextResponse)
async def handle_incoming_call(
    From: str = Form(...),
    To: str = Form(...),
    CallSid: str = Form(...)
):
    """
    Handle incoming Twilio voice call.
    
    This is the initial webhook that Twilio calls when someone calls your number.
    """
    logger.info(f"Incoming call from {From} to {To} (CallSid: {CallSid})")
    
    # Create TwiML response
    response = VoiceResponse()
    
    # Greet the caller
    gather = Gather(
        num_digits=1,
        action='/twilio/gather',
        method='POST',
        timeout=5
    )
    
    gather.say(
        "Welcome to Chatterbox Voice Service. "
        "Press 1 for English. Press 2 for Pidgin. Press 3 to hear a demo.",
        voice='alice',
        language='en-US'
    )
    
    response.append(gather)
    
    # If no input, repeat
    response.say("We didn't receive any input. Goodbye!")
    
    return str(response)


@app.post("/twilio/gather", response_class=PlainTextResponse)
async def handle_gather(
    Digits: str = Form(...),
    CallSid: str = Form(...),
    From: str = Form(...)
):
    """
    Handle user input from Gather.
    """
    logger.info(f"Received digit: {Digits} from {From} (CallSid: {CallSid})")
    
    response = VoiceResponse()
    
    if Digits == '1':
        # English greeting
        text = "Hello! Thank you for calling Chatterbox. This is a demonstration of our Nigerian text-to-speech technology."
        voice = "naija_female"
        
    elif Digits == '2':
        # Pidgin greeting
        text = "Wetin dey happen! Thank you for calling Chatterbox. Na so our Nigerian text-to-speech technology dey work."
        voice = "naija_male"
        
    elif Digits == '3':
        # Demo message
        text = ("Welcome to Chatterbox, Nigeria's premier text-to-speech service. "
                "We provide natural-sounding Nigerian voices for your applications. "
                "From customer service to education, we make technology speak your language.")
        voice = "naija_female"
        
    else:
        response.say("Invalid option. Please try again.")
        response.redirect('/twilio/voice')
        return str(response)
    
    # For now, use Twilio's built-in TTS
    # In production, you'd generate audio and play URL
    response.say(text, voice='alice', language='en-US')
    
    # TODO: Implement async TTS generation and play
    # 1. Generate TTS audio
    # 2. Upload to storage
    # 3. Update call with Play URL
    
    response.say("Thank you for calling. Goodbye!")
    response.hangup()
    
    return str(response)


@app.post("/twilio/status")
async def call_status(request: Request):
    """
    Receive call status callbacks from Twilio.
    """
    data = await request.form()
    call_sid = data.get("CallSid")
    call_status = data.get("CallStatus")
    
    logger.info(f"Call status update: {call_sid} = {call_status}")
    
    return {"status": "received"}


# Advanced: Async TTS + Play in active call
async def play_tts_in_call(call_sid: str, text: str, voice_id: str = DEFAULT_VOICE_ID):
    """
    Generate TTS and play it in an active call.
    
    This is for advanced use cases where you want to:
    1. Answer call immediately
    2. Generate TTS asynchronously
    3. Play audio in the live call
    
    Args:
        call_sid: Twilio Call SID
        text: Text to speak
        voice_id: Voice to use
    """
    try:
        # Generate TTS
        audio_data = await generate_tts(text, voice_id)
        
        # Upload to storage
        filename = f"tts_{call_sid}.mp3"
        audio_url = await upload_to_storage(audio_data, filename)
        
        # Update the call to play the audio
        call = twilio_client.calls(call_sid).update(
            url=f"{WEBHOOK_BASE_URL}/twilio/play?url={audio_url}",
            method='POST'
        )
        
        logger.info(f"Updated call {call_sid} to play {audio_url}")
        
    except Exception as e:
        logger.error(f"Error playing TTS in call: {e}", exc_info=True)


@app.post("/twilio/play", response_class=PlainTextResponse)
async def play_audio(url: str = Form(...)):
    """
    TwiML endpoint to play audio URL.
    """
    response = VoiceResponse()
    response.play(url)
    return str(response)


if __name__ == "__main__":
    import uvicorn
    
    logger.info("Starting Twilio TTS Integration Service")
    logger.info(f"Twilio Number: {TWILIO_PHONE_NUMBER}")
    logger.info(f"TTS Service: {TTS_BASE_URL}")
    
    uvicorn.run(app, host="0.0.0.0", port=8080)

