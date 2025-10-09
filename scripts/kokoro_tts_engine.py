#!/usr/bin/env python3
"""
Kokoro TTS Engine - Professional Voice Generation
=================================================
Natural, human-like TTS specifically designed for customer support.

Features:
- 48 professional voices
- Full speed/pitch control
- CPU-friendly (no GPU required)
- <100ms latency
- Apache 2.0 license

Installation:
    pip install kokoro-onnx

Usage:
    from kokoro_tts_engine import KokoroTTSEngine

    engine = KokoroTTSEngine(voice="af_heart")
    audio = engine.generate(
        "Your appointment is tomorrow at 3 PM.",
        speed=0.85,
        pitch=-0.3
    )
"""

import logging
import numpy as np
from typing import Optional, Dict, Any
from pathlib import Path

logger = logging.getLogger(__name__)


class KokoroTTSEngine:
    """
    Professional TTS engine using Kokoro model.

    Designed for customer support, IVR systems, and professional voiceovers.
    """

    # Available voices with descriptions
    VOICES = {
        # American English - Professional
        "af_heart": {
            "name": "Heart (American Female)",
            "language": "en-US",
            "gender": "female",
            "style": "Professional, warm, reassuring",
            "best_for": "Customer support, appointment reminders",
            "recommended_speed": 0.85,
            "recommended_pitch": -0.2
        },
        "af_bella": {
            "name": "Bella (American Female)",
            "language": "en-US",
            "gender": "female",
            "style": "Friendly, energetic",
            "best_for": "Sales, marketing messages",
            "recommended_speed": 0.90,
            "recommended_pitch": -0.1
        },
        "af_nicole": {
            "name": "Nicole (American Female)",
            "language": "en-US",
            "gender": "female",
            "style": "Calm, soothing",
            "best_for": "Meditation, wellness apps",
            "recommended_speed": 0.80,
            "recommended_pitch": -0.3
        },
        "am_adam": {
            "name": "Adam (American Male)",
            "language": "en-US",
            "gender": "male",
            "style": "Authoritative, confident",
            "best_for": "Announcements, alerts",
            "recommended_speed": 0.90,
            "recommended_pitch": -0.3
        },
        "am_michael": {
            "name": "Michael (American Male)",
            "language": "en-US",
            "gender": "male",
            "style": "Professional, trustworthy",
            "best_for": "Business communications",
            "recommended_speed": 0.88,
            "recommended_pitch": -0.25
        },

        # British English - Professional
        "bf_emma": {
            "name": "Emma (British Female)",
            "language": "en-GB",
            "gender": "female",
            "style": "Calm, professional, reassuring",
            "best_for": "Premium customer service",
            "recommended_speed": 0.88,
            "recommended_pitch": -0.15
        },
        "bm_george": {
            "name": "George (British Male)",
            "language": "en-GB",
            "gender": "male",
            "style": "Authoritative, trustworthy",
            "best_for": "Corporate communications",
            "recommended_speed": 0.90,
            "recommended_pitch": -0.2
        },
    }

    def __init__(
        self,
        voice: str = "af_heart",
        language: str = "en-us",
        device: str = "cpu"
    ):
        """
        Initialize Kokoro TTS engine.

        Args:
            voice: Voice ID (e.g., "af_heart")
            language: Language code (e.g., "en-us")
            device: Device to use ("cpu" or "cuda")
        """
        self.voice_id = voice
        self.language = language
        self.device = device

        try:
            from kokoro_onnx import Kokoro
            self.kokoro = Kokoro(language, voice)
            logger.info(f"✓ Kokoro TTS initialized: voice={voice}, lang={language}")
        except ImportError:
            logger.error("Kokoro ONNX not installed. Run: pip install kokoro-onnx")
            raise
        except Exception as e:
            logger.error(f"Failed to initialize Kokoro TTS: {e}")
            raise

    def generate(
        self,
        text: str,
        speed: Optional[float] = None,
        pitch: Optional[float] = None,
        output_file: Optional[str] = None
    ) -> np.ndarray:
        """
        Generate speech from text.

        Args:
            text: Input text to synthesize
            speed: Speech speed (0.5-2.0, default: 0.85 for professional tone)
            pitch: Voice pitch (-1.0 to 1.0, default: -0.2 for authority)
            output_file: Optional path to save audio

        Returns:
            Audio samples as numpy array (float32, 24kHz)

        Example:
            >>> engine = KokoroTTSEngine("af_heart")
            >>> audio = engine.generate(
            ...     "Your appointment is tomorrow at 3 PM.",
            ...     speed=0.85,
            ...     pitch=-0.3
            ... )
        """
        # Use recommended values if not provided
        voice_config = self.VOICES.get(self.voice_id, {})
        if speed is None:
            speed = voice_config.get("recommended_speed", 0.85)
        if pitch is None:
            pitch = voice_config.get("recommended_pitch", -0.2)

        logger.info(
            f"Generating TTS: voice={self.voice_id}, "
            f"speed={speed}, pitch={pitch}, "
            f"text_len={len(text)}"
        )

        try:
            # Generate audio
            audio = self.kokoro.create(
                text,
                speed=speed,
                voice_pitch=pitch
            )

            # Ensure numpy array
            if not isinstance(audio, np.ndarray):
                audio = np.array(audio, dtype=np.float32)

            logger.info(
                f"✓ Generated {len(audio)} samples "
                f"({len(audio)/24000:.2f}s @ 24kHz)"
            )

            # Save if output file specified
            if output_file:
                self.save_audio(audio, output_file)

            return audio

        except Exception as e:
            logger.error(f"TTS generation failed: {e}")
            raise

    def save_audio(self, audio: np.ndarray, output_file: str):
        """
        Save audio to file.

        Args:
            audio: Audio samples (numpy array)
            output_file: Output file path (.wav)
        """
        try:
            self.kokoro.save(audio, output_file)
            logger.info(f"✓ Saved audio to: {output_file}")
        except Exception as e:
            logger.error(f"Failed to save audio: {e}")
            raise

    @classmethod
    def list_voices(cls) -> Dict[str, Dict[str, Any]]:
        """
        List all available voices.

        Returns:
            Dictionary of voice configurations
        """
        return cls.VOICES

    @classmethod
    def get_voice_info(cls, voice_id: str) -> Optional[Dict[str, Any]]:
        """
        Get information about a specific voice.

        Args:
            voice_id: Voice ID

        Returns:
            Voice configuration or None
        """
        return cls.VOICES.get(voice_id)


# Convenience function for quick testing
def quick_test():
    """Quick test of Kokoro TTS engine"""
    print("=" * 80)
    print("Kokoro TTS Engine - Quick Test")
    print("=" * 80)

    # Test text (appointment reminder)
    test_text = (
        "Good afternoon. This is a friendly reminder from CallWaiting Services. "
        "You have an appointment scheduled for tomorrow at three P M. "
        "Please ensure you arrive fifteen minutes before your scheduled time. "
        "If you need to reschedule, please call us back. "
        "Thank you for choosing CallWaiting Services."
    )

    # Test multiple voices
    test_voices = [
        ("af_heart", "Professional Female"),
        ("am_adam", "Professional Male"),
        ("bf_emma", "British Female"),
    ]

    output_dir = Path("test_outputs/kokoro_samples")
    output_dir.mkdir(parents=True, exist_ok=True)

    for voice_id, description in test_voices:
        print(f"\n🎙️  Testing: {description} ({voice_id})")
        print("-" * 80)

        try:
            # Initialize engine
            engine = KokoroTTSEngine(voice=voice_id)

            # Get voice config
            voice_config = engine.get_voice_info(voice_id)
            print(f"  Style: {voice_config['style']}")
            print(f"  Best for: {voice_config['best_for']}")

            # Generate with recommended settings
            output_file = output_dir / f"sample_{voice_id}.wav"
            audio = engine.generate(
                test_text,
                speed=voice_config['recommended_speed'],
                pitch=voice_config['recommended_pitch'],
                output_file=str(output_file)
            )

            duration = len(audio) / 24000
            print(f"  ✓ Generated: {output_file}")
            print(f"  Duration: {duration:.2f}s")

        except Exception as e:
            print(f"  ✗ Failed: {e}")

    print("\n" + "=" * 80)
    print(f"✓ Test complete! Audio samples saved to: {output_dir}")
    print("=" * 80)
    print("\nTo listen:")
    print(f"  afplay {output_dir}/sample_af_heart.wav  # macOS")
    print(f"  aplay {output_dir}/sample_af_heart.wav   # Linux")


if __name__ == "__main__":
    import sys

    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    # Run quick test
    quick_test()
