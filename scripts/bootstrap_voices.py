#!/usr/bin/env python3
"""
Bootstrap script - Creates working voices automatically on server startup
NO MANUAL SETUP REQUIRED - Production ready
"""

import os
import sys
import json
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def create_default_voices():
    """Create default voice configurations that work with Chatterbox TTS"""

    voices_dir = Path("voices")
    voices_dir.mkdir(exist_ok=True)

    # Chatterbox TTS works WITHOUT reference audio for default voices
    # We just need voice config files

    default_voices = [
        {
            "name": "Emily",
            "slug": "emily-en-us",
            "language": "en-US",
            "gender": "female",
            "description": "Natural American English female voice",
            "params": {
                "temperature": 0.8,
                "exaggeration": 1.3,
                "cfg_weight": 0.5,
                "speed_factor": 1.0
            }
        },
        {
            "name": "James",
            "slug": "james-en-us",
            "language": "en-US",
            "gender": "male",
            "description": "Professional American English male voice",
            "params": {
                "temperature": 0.8,
                "exaggeration": 1.0,
                "cfg_weight": 0.5,
                "speed_factor": 1.0
            }
        },
        {
            "name": "Sophia",
            "slug": "sophia-en-gb",
            "language": "en-GB",
            "gender": "female",
            "description": "British English female voice",
            "params": {
                "temperature": 0.8,
                "exaggeration": 1.2,
                "cfg_weight": 0.5,
                "speed_factor": 1.0
            }
        },
        {
            "name": "Marcus",
            "slug": "marcus-en-us",
            "language": "en-US",
            "gender": "male",
            "description": "Deep authoritative male voice",
            "params": {
                "temperature": 0.7,
                "exaggeration": 0.8,
                "cfg_weight": 0.6,
                "speed_factor": 0.95
            }
        },
        {
            "name": "Luna",
            "slug": "luna-en-us",
            "language": "en-US",
            "gender": "female",
            "description": "Expressive energetic female voice",
            "params": {
                "temperature": 0.9,
                "exaggeration": 1.5,
                "cfg_weight": 0.4,
                "speed_factor": 1.05
            }
        }
    ]

    voices_manifest = []

    for voice in default_voices:
        # Create voice metadata file
        voice_file = voices_dir / f"{voice['slug']}.json"

        with open(voice_file, 'w') as f:
            json.dump(voice, f, indent=2)

        logger.info(f"✓ Created voice: {voice['name']} ({voice['slug']})")
        voices_manifest.append(voice)

    # Create manifest file
    manifest_path = voices_dir / "manifest.json"
    with open(manifest_path, 'w') as f:
        json.dump({
            "voices": voices_manifest,
            "version": "1.0.0",
            "total": len(voices_manifest)
        }, f, indent=2)

    logger.info(f"✓ Created manifest with {len(voices_manifest)} voices")

    # Create a README
    readme_path = voices_dir / "README.md"
    with open(readme_path, 'w') as f:
        f.write("# Voice Files\n\n")
        f.write("These are voice configuration files for Chatterbox TTS.\n\n")
        f.write("## Available Voices\n\n")
        for voice in voices_manifest:
            f.write(f"- **{voice['name']}** (`{voice['slug']}`): {voice['description']}\n")
        f.write("\n## Usage\n\n")
        f.write("Use the voice slug in API requests:\n\n")
        f.write("```json\n")
        f.write('{"text": "Hello", "voice": "emily-en-us"}\n')
        f.write("```\n")

    return len(voices_manifest)

def insert_voices_to_database():
    """Insert voices into database if available"""
    try:
        import asyncio
        import asyncpg
        import os

        async def _insert():
            dsn = f"postgresql://{os.getenv('POSTGRES_USER', 'postgres')}:{os.getenv('POSTGRES_PASSWORD', 'changeme123')}@{os.getenv('POSTGRES_HOST', 'localhost')}:{os.getenv('POSTGRES_PORT', 5432)}/{os.getenv('POSTGRES_DB', 'chatterbox')}"

            try:
                conn = await asyncpg.connect(dsn, timeout=5)

                voices_dir = Path("voices")
                for voice_file in voices_dir.glob("*.json"):
                    if voice_file.name == "manifest.json":
                        continue

                    with open(voice_file) as f:
                        voice = json.load(f)

                    # Insert or update voice
                    await conn.execute("""
                        INSERT INTO voices (slug, display_name, description, language, gender, is_public, params, status)
                        VALUES ($1, $2, $3, $4, $5, TRUE, $6, 'active')
                        ON CONFLICT (slug) DO UPDATE SET
                            display_name = EXCLUDED.display_name,
                            description = EXCLUDED.description,
                            params = EXCLUDED.params,
                            updated_at = NOW()
                    """, voice['slug'], voice['name'], voice['description'], voice['language'],
                         voice['gender'], json.dumps(voice['params']))

                    logger.info(f"✓ Inserted voice to database: {voice['name']}")

                await conn.close()
                logger.info("✓ All voices inserted to database")
                return True

            except Exception as e:
                logger.warning(f"Database not available, skipping DB insert: {e}")
                return False

        return asyncio.run(_insert())

    except Exception as e:
        logger.warning(f"Could not insert to database: {e}")
        return False

def main():
    logger.info("=" * 60)
    logger.info("Bootstrapping Default Voices")
    logger.info("=" * 60)

    # Create voice files
    count = create_default_voices()
    logger.info(f"✓ Created {count} default voices")

    # Try to insert to database if available
    if os.getenv('POSTGRES_HOST'):
        logger.info("Attempting to insert voices to database...")
        insert_voices_to_database()

    logger.info("=" * 60)
    logger.info("✓ Bootstrap complete - Server ready to use")
    logger.info("=" * 60)

    return 0

if __name__ == "__main__":
    sys.exit(main())
