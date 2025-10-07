"""
Voice Management - Production Ready
Handles voice loading without requiring physical audio files
"""

import json
import logging
from pathlib import Path
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

class VoiceManager:
    """Manages voice configurations for TTS generation"""

    def __init__(self, voices_dir: str = "voices"):
        self.voices_dir = Path(voices_dir)
        self.voices: Dict[str, Dict[str, Any]] = {}
        self.load_voices()

    def load_voices(self):
        """Load all voice configurations"""
        self.voices_dir.mkdir(exist_ok=True)

        # Check for voice files
        voice_files = list(self.voices_dir.glob("*.json"))

        if not voice_files or len(voice_files) <= 1:  # Only manifest
            logger.warning("No voice files found, creating defaults...")
            self._create_defaults()
            voice_files = list(self.voices_dir.glob("*.json"))

        # Load voices
        for voice_file in voice_files:
            if voice_file.name == "manifest.json":
                continue

            try:
                with open(voice_file) as f:
                    voice = json.load(f)
                    self.voices[voice['slug']] = voice
                    logger.info(f"✓ Loaded voice: {voice['name']} ({voice['slug']})")
            except Exception as e:
                logger.error(f"Failed to load voice {voice_file}: {e}")

        logger.info(f"✓ Loaded {len(self.voices)} voices")

    def _create_defaults(self):
        """Create default voices if none exist"""
        from scripts.bootstrap_voices import create_default_voices
        create_default_voices()

    def get_voice(self, slug: str) -> Optional[Dict[str, Any]]:
        """Get voice configuration by slug"""
        return self.voices.get(slug)

    def get_voice_params(self, slug: str) -> Dict[str, Any]:
        """Get TTS parameters for a voice"""
        voice = self.get_voice(slug)
        if not voice:
            logger.warning(f"Voice {slug} not found, using defaults")
            return self._get_default_params()

        return voice.get('params', self._get_default_params())

    def _get_default_params(self) -> Dict[str, Any]:
        """Get default TTS parameters"""
        return {
            "temperature": 0.8,
            "exaggeration": 1.3,
            "cfg_weight": 0.5,
            "speed_factor": 1.0
        }

    def list_voices(self) -> list:
        """List all available voices"""
        return [
            {
                "slug": slug,
                "name": voice['name'],
                "language": voice['language'],
                "gender": voice.get('gender'),
                "description": voice.get('description')
            }
            for slug, voice in self.voices.items()
        ]

    def get_default_voice(self) -> str:
        """Get default voice slug"""
        if 'emily-en-us' in self.voices:
            return 'emily-en-us'
        elif self.voices:
            return list(self.voices.keys())[0]
        else:
            return 'emily-en-us'  # Fallback

# Global voice manager instance
_voice_manager: Optional[VoiceManager] = None

def get_voice_manager() -> VoiceManager:
    """Get or create voice manager instance"""
    global _voice_manager
    if _voice_manager is None:
        _voice_manager = VoiceManager()
    return _voice_manager
