"""
Text Pre-Processing Filters for Natural TTS
============================================
Industry best practices from OpenAI, ElevenLabs, WellSaid Labs, and Amazon Polly.

Improves clarity, rhythm, and naturalness of synthesized speech.
"""

import re
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)


def clean_text(raw: str) -> str:
    """
    Basic text cleaning and normalization.

    Args:
        raw: Raw input text

    Returns:
        Cleaned text suitable for TTS
    """
    # Strip whitespace
    text = raw.strip()

    # Normalize whitespace (multiple spaces → single space)
    text = re.sub(r'\s+', ' ', text)

    # Fix common abbreviations for better pronunciation
    text = re.sub(r'\bAI\b', 'A.I.', text)
    text = re.sub(r'\bAPI\b', 'A.P.I.', text)
    text = re.sub(r'\bTTS\b', 'T.T.S.', text)
    text = re.sub(r'\bSMS\b', 'S.M.S.', text)
    text = re.sub(r'\bURL\b', 'U.R.L.', text)
    text = re.sub(r'\bFAQ\b', 'F.A.Q.', text)
    text = re.sub(r'\bCEO\b', 'C.E.O.', text)
    text = re.sub(r'\bCTO\b', 'C.T.O.', text)

    # Fix number + letter combinations (e.g., "5G" → "5 G")
    text = re.sub(r'(\d)([A-Z])\b', r'\1 \2', text)

    # Expand common contractions for clarity
    contractions = {
        "won't": "will not",
        "can't": "cannot",
        "n't": " not",
        "'re": " are",
        "'ve": " have",
        "'ll": " will",
        "'d": " would",
        "'m": " am"
    }

    for contraction, expansion in contractions.items():
        text = re.sub(rf"{contraction}\b", expansion, text, flags=re.IGNORECASE)

    return text


def add_prosody_breaks(text: str, style: str = "neutral") -> str:
    """
    Add natural pauses and rhythm markers.

    This mimics how ElevenLabs and WellSaid add micro-pauses
    for more natural speech flow.

    Args:
        text: Input text
        style: Speech style (neutral, calm, urgent, apologetic, etc.)

    Returns:
        Text with prosody markers
    """
    # Add pauses after punctuation
    if style == "calm" or style == "apologetic":
        # Longer pauses for calm/apologetic tones
        text = text.replace('?', '? <break time="400ms"/>')
        text = text.replace('.', '. <break time="300ms"/>')
        text = text.replace('!', '! <break time="350ms"/>')
        text = text.replace(',', ', <break time="200ms"/>')
    elif style == "urgent":
        # Shorter pauses for urgent tone
        text = text.replace('?', '? <break time="150ms"/>')
        text = text.replace('.', '. <break time="100ms"/>')
        text = text.replace('!', '! <break time="100ms"/>')
        text = text.replace(',', ', <break time="80ms"/>')
    else:
        # Neutral pacing
        text = text.replace('?', '? <break time="300ms"/>')
        text = text.replace('.', '. <break time="200ms"/>')
        text = text.replace('!', '! <break time="250ms"/>')
        text = text.replace(',', ', <break time="150ms"/>')

    # Add emphasis on key words (optional, can be configured)
    # text = re.sub(r'\b(important|urgent|critical|attention)\b', r'<emphasis level="strong">\1</emphasis>', text, flags=re.IGNORECASE)

    return text


def detect_emotion(text: str) -> str:
    """
    Detect emotional context from text.

    This is how Amazon Connect and Google Dialogflow CX
    automatically adjust tone.

    Args:
        text: Input text

    Returns:
        Detected emotion/style
    """
    text_lower = text.lower()

    # Apologetic patterns
    if any(word in text_lower for word in ['sorry', 'apologize', 'apologies', 'regret', 'unfortunate']):
        return 'apologetic'

    # Grateful patterns
    if any(word in text_lower for word in ['thank', 'grateful', 'appreciate', 'thanks']):
        return 'grateful'

    # Urgent patterns
    if any(word in text_lower for word in ['urgent', 'immediately', 'asap', 'critical', 'emergency', 'hurry']):
        return 'urgent'

    # Professional/formal patterns
    if any(word in text_lower for word in ['regarding', 'pursuant', 'hereby', 'kindly', 'dear']):
        return 'professional'

    # Friendly patterns
    if any(word in text_lower for word in ['hello', 'hi ', 'hey', 'welcome', 'great', 'awesome']):
        return 'friendly'

    # Default
    return 'neutral'


def get_style_params(emotion: str) -> Dict[str, Any]:
    """
    Map emotions to TTS parameter adjustments.

    Args:
        emotion: Detected emotion

    Returns:
        Parameter overrides for TTS
    """
    style_map = {
        'grateful': {
            'speed_factor': 0.95,
            'pitch_shift': '+1st',
            'rate': '-5%',
            'exaggeration': 1.2
        },
        'apologetic': {
            'speed_factor': 0.85,
            'pitch_shift': '-3st',
            'rate': '-15%',
            'exaggeration': 1.1
        },
        'urgent': {
            'speed_factor': 1.1,
            'pitch_shift': '+2st',
            'rate': '+10%',
            'exaggeration': 1.5
        },
        'professional': {
            'speed_factor': 0.92,
            'pitch_shift': '-2st',
            'rate': '-8%',
            'exaggeration': 1.2
        },
        'friendly': {
            'speed_factor': 1.0,
            'pitch_shift': '+1st',
            'rate': '0%',
            'exaggeration': 1.3
        },
        'neutral': {
            'speed_factor': 1.0,
            'pitch_shift': '0st',
            'rate': '0%',
            'exaggeration': 1.3
        }
    }

    return style_map.get(emotion, style_map['neutral'])


def preprocess_for_tts(
    text: str,
    voice_style: str = None,
    auto_detect_emotion: bool = True
) -> tuple[str, Dict[str, Any]]:
    """
    Complete preprocessing pipeline for TTS input.

    This is the main function to use before TTS synthesis.

    Args:
        text: Raw input text
        voice_style: Predefined style (overrides auto-detection)
        auto_detect_emotion: Whether to auto-detect emotion

    Returns:
        Tuple of (processed_text, style_params)

    Example:
        >>> text, params = preprocess_for_tts("Sorry for the delay!")
        >>> print(params)
        {'speed_factor': 0.85, 'pitch_shift': '-3st', ...}
    """
    # Step 1: Clean text
    cleaned = clean_text(text)

    # Step 2: Detect emotion (if enabled and no style provided)
    if auto_detect_emotion and voice_style is None:
        detected_emotion = detect_emotion(cleaned)
        logger.info(f"Auto-detected emotion: {detected_emotion}")
        style = detected_emotion
    else:
        style = voice_style or 'neutral'

    # Step 3: Add prosody breaks
    processed = add_prosody_breaks(cleaned, style=style)

    # Step 4: Get style parameters
    style_params = get_style_params(style)
    style_params['detected_style'] = style

    logger.info(f"Text preprocessed: style={style}, length={len(processed)}")

    return processed, style_params


# Quick test
if __name__ == "__main__":
    test_texts = [
        "Sorry for the delay in responding to your request.",
        "Thank you so much for your patience!",
        "URGENT: Please respond immediately to this message.",
        "Welcome to CallWaiting AI customer service.",
        "Regarding your inquiry about our API service."
    ]

    print("=" * 80)
    print("TTS Text Preprocessing Tests")
    print("=" * 80)

    for text in test_texts:
        processed, params = preprocess_for_tts(text)
        print(f"\nOriginal: {text}")
        print(f"Processed: {processed[:80]}...")
        print(f"Style: {params['detected_style']}")
        print(f"Params: speed={params['speed_factor']}, pitch={params['pitch_shift']}")
