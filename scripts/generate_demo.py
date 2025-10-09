#!/usr/bin/env python3
"""
Generate 30-Second Customer Support Demo
=========================================
Creates professional customer support audio samples using Kokoro TTS.

Scenarios:
1. Appointment reminder (professional, calm)
2. Order confirmation (friendly, reassuring)
3. Service update (professional, clear)
4. Technical support greeting (helpful, warm)
5. Payment confirmation (professional, secure)
"""

import sys
import logging
from pathlib import Path

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def generate_customer_support_demos():
    """Generate various customer support demo scenarios"""

    try:
        from kokoro_tts_engine import KokoroTTSEngine
    except ImportError:
        logger.error("Kokoro TTS not installed. Run: pip install kokoro-onnx")
        return False

    # Create output directory
    output_dir = Path("demo_outputs")
    output_dir.mkdir(exist_ok=True)

    # Demo scenarios
    scenarios = [
        {
            "name": "Appointment Reminder",
            "voice": "af_heart",
            "speed": 0.85,
            "pitch": -0.2,
            "text": """Good afternoon! This is a friendly reminder from CallWaiting Services.
You have an appointment scheduled for tomorrow at three P M.
Please ensure you arrive fifteen minutes early and bring your I D and insurance card.
If you need to reschedule, please call us at your earliest convenience.
We look forward to seeing you. Thank you!"""
        },
        {
            "name": "Order Confirmation",
            "voice": "af_bella",
            "speed": 0.88,
            "pitch": -0.15,
            "text": """Hello! Thank you for your order with CloudMaestro Services.
Your order number is A B C one two three four five.
Your items will be delivered within three to five business days.
You'll receive a tracking number via email shortly.
If you have any questions, our support team is here to help.
Thank you for choosing us!"""
        },
        {
            "name": "Service Update",
            "voice": "af_heart",
            "speed": 0.85,
            "pitch": -0.2,
            "text": """Good morning. This is an important service update from your account manager.
Your monthly subscription has been successfully renewed for another month.
Your next billing date is the fifteenth of next month.
You can view your invoice in your account dashboard.
Thank you for being a valued customer!"""
        },
        {
            "name": "Technical Support Greeting",
            "voice": "am_michael",
            "speed": 0.88,
            "pitch": -0.25,
            "text": """Hello, and thank you for calling Technical Support.
This is a courtesy callback regarding your recent service request.
Our technician has reviewed your case and scheduled a visit for tomorrow between two and four P M.
Please ensure someone is available to provide access.
If this time doesn't work, please call us back to reschedule.
We appreciate your patience!"""
        },
        {
            "name": "Payment Confirmation",
            "voice": "bf_emma",
            "speed": 0.88,
            "pitch": -0.15,
            "text": """Good afternoon. This message confirms that your payment of two hundred and fifty dollars
has been successfully processed.
Your account is now current, and all services remain active.
A receipt has been sent to your email address on file.
If you have any questions about this transaction, please contact our billing department.
Thank you for your prompt payment!"""
        },
        {
            "name": "Calm Support (Apology)",
            "voice": "af_nicole",
            "speed": 0.80,
            "pitch": -0.3,
            "text": """Hello. We're calling to sincerely apologize for the service interruption you experienced yesterday.
We understand how frustrating this must have been.
Our team has identified and resolved the issue, and we've credited your account
as a gesture of goodwill.
We truly value your patience and loyalty.
If you have any concerns, please don't hesitate to reach out.
Thank you for your understanding."""
        },
        {
            "name": "Professional Male Announcement",
            "voice": "am_adam",
            "speed": 0.90,
            "pitch": -0.3,
            "text": """Attention valued customers.
Our office will be closed this Monday in observance of the holiday.
Normal business hours will resume on Tuesday at nine A M.
For urgent matters during this time, please use our online support portal
or leave a message, and we'll respond on the next business day.
We appreciate your understanding and wish you a wonderful holiday!"""
        }
    ]

    print("=" * 80)
    print("Generating 30-Second Customer Support Demo Scenarios")
    print("=" * 80)
    print()

    results = []

    for idx, scenario in enumerate(scenarios, 1):
        print(f"[{idx}/{len(scenarios)}] {scenario['name']}")
        print("-" * 80)

        try:
            # Initialize engine
            engine = KokoroTTSEngine(voice=scenario['voice'])

            # Generate audio
            output_file = output_dir / f"{idx}_{scenario['name'].lower().replace(' ', '_')}.wav"

            audio = engine.generate(
                scenario['text'],
                speed=scenario['speed'],
                pitch=scenario['pitch'],
                output_file=str(output_file)
            )

            duration = len(audio) / 24000

            print(f"  Voice: {scenario['voice']}")
            print(f"  Speed: {scenario['speed']}x")
            print(f"  Pitch: {scenario['pitch']}")
            print(f"  Duration: {duration:.1f}s")
            print(f"  ✓ Saved: {output_file}")

            results.append({
                "scenario": scenario['name'],
                "file": output_file,
                "duration": duration,
                "success": True
            })

        except Exception as e:
            print(f"  ✗ Failed: {e}")
            results.append({
                "scenario": scenario['name'],
                "success": False,
                "error": str(e)
            })

        print()

    # Summary
    print("=" * 80)
    print("Generation Complete!")
    print("=" * 80)
    print()

    successful = [r for r in results if r.get('success')]
    print(f"✓ Successfully generated {len(successful)}/{len(scenarios)} scenarios")
    print()

    if successful:
        print("Generated files:")
        for result in successful:
            print(f"  • {result['file']} ({result['duration']:.1f}s)")

        print()
        print("To listen (download to local machine first):")
        print()
        print(f"  # Download all demos")
        print(f"  scp root@<runpod-ip>:/workspace/chatterbox-twilio-integration/demo_outputs/*.wav .")
        print()
        print(f"  # Play on macOS")
        print(f"  afplay 1_appointment_reminder.wav")
        print()
        print(f"  # Play on Linux")
        print(f"  aplay 1_appointment_reminder.wav")
        print()

    return len(successful) == len(scenarios)


if __name__ == "__main__":
    success = generate_customer_support_demos()
    sys.exit(0 if success else 1)
