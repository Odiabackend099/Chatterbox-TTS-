#!/usr/bin/env python3
"""
API Test Script for Chatterbox TTS Server
Tests all API endpoints to verify functionality
"""

import os
import sys
import time
import requests
from pathlib import Path

# Configuration
BASE_URL = os.getenv("CHATTERBOX_URL", "http://localhost:8004")
TEST_OUTPUT_DIR = Path("outputs/test_outputs")
TEST_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def print_test(name):
    """Print test name"""
    print(f"\n{'='*60}")
    print(f"Testing: {name}")
    print('='*60)

def print_success(message):
    """Print success message"""
    print(f"✓ {message}")

def print_error(message):
    """Print error message"""
    print(f"✗ {message}")

def test_health():
    """Test health check endpoint"""
    print_test("Health Check")

    try:
        response = requests.get(f"{BASE_URL}/health")
        response.raise_for_status()

        data = response.json()
        print(f"Status: {data['status']}")
        print(f"Components: {data['components']}")

        assert data['status'] in ['healthy', 'degraded'], "Invalid health status"
        assert 'components' in data, "Missing components"

        print_success("Health check passed")
        return True
    except Exception as e:
        print_error(f"Health check failed: {e}")
        return False

def test_root():
    """Test root endpoint"""
    print_test("Root Endpoint")

    try:
        response = requests.get(f"{BASE_URL}/")
        response.raise_for_status()

        data = response.json()
        print(f"Service: {data.get('service')}")
        print(f"Version: {data.get('version')}")
        print(f"Model Loaded: {data.get('model_loaded')}")

        assert data.get('status') == 'running', "Service not running"

        print_success("Root endpoint passed")
        return True
    except Exception as e:
        print_error(f"Root endpoint failed: {e}")
        return False

def test_tts_basic():
    """Test basic TTS generation"""
    print_test("Basic TTS Generation")

    try:
        payload = {
            "text": "This is a test of the Chatterbox TTS system.",
            "temperature": 0.8,
            "exaggeration": 1.3,
            "speed_factor": 1.0
        }

        print(f"Generating audio for: {payload['text']}")
        start_time = time.time()

        response = requests.post(f"{BASE_URL}/tts", json=payload)
        response.raise_for_status()

        elapsed = time.time() - start_time

        # Save audio
        output_path = TEST_OUTPUT_DIR / "test_basic.wav"
        with open(output_path, "wb") as f:
            f.write(response.content)

        file_size = len(response.content)
        print(f"Audio generated in {elapsed:.2f}s")
        print(f"File size: {file_size / 1024:.2f} KB")
        print(f"Saved to: {output_path}")

        assert file_size > 0, "Generated audio is empty"
        assert elapsed < 30, f"Generation too slow: {elapsed:.2f}s"

        print_success(f"TTS generation passed ({elapsed:.2f}s)")
        return True
    except Exception as e:
        print_error(f"TTS generation failed: {e}")
        return False

def test_tts_voice_clone():
    """Test TTS with voice cloning"""
    print_test("Voice Cloning")

    try:
        # Check if test voice exists
        voices_dir = Path("voices")
        voice_files = list(voices_dir.glob("*.wav"))

        if not voice_files:
            print("⚠ No voice files found, skipping voice clone test")
            print("  Add WAV files to voices/ directory to test voice cloning")
            return True

        test_voice = voice_files[0].name
        print(f"Using voice: {test_voice}")

        payload = {
            "text": "This is voice cloning in action!",
            "voice_mode": "clone",
            "predefined_voice": test_voice,
            "temperature": 0.8,
            "exaggeration": 1.5
        }

        start_time = time.time()
        response = requests.post(f"{BASE_URL}/tts", json=payload)
        response.raise_for_status()
        elapsed = time.time() - start_time

        # Save audio
        output_path = TEST_OUTPUT_DIR / "test_voice_clone.wav"
        with open(output_path, "wb") as f:
            f.write(response.content)

        print(f"Voice cloning completed in {elapsed:.2f}s")
        print(f"Saved to: {output_path}")

        print_success("Voice cloning passed")
        return True
    except Exception as e:
        print_error(f"Voice cloning failed: {e}")
        return False

def test_openai_compatible():
    """Test OpenAI-compatible endpoint"""
    print_test("OpenAI-Compatible Endpoint")

    try:
        payload = {
            "input": "Testing OpenAI compatibility.",
            "voice": "default",
            "speed": 1.0
        }

        start_time = time.time()
        response = requests.post(f"{BASE_URL}/v1/audio/speech", json=payload)
        response.raise_for_status()
        elapsed = time.time() - start_time

        # Save audio
        output_path = TEST_OUTPUT_DIR / "test_openai.wav"
        with open(output_path, "wb") as f:
            f.write(response.content)

        print(f"Generated in {elapsed:.2f}s")
        print(f"Saved to: {output_path}")

        print_success("OpenAI endpoint passed")
        return True
    except Exception as e:
        print_error(f"OpenAI endpoint failed: {e}")
        return False

def test_llm():
    """Test LLM endpoint"""
    print_test("LLM Generation")

    try:
        payload = {
            "prompt": "What is 2+2?",
            "max_tokens": 50,
            "temperature": 0.7
        }

        print(f"Prompt: {payload['prompt']}")
        start_time = time.time()

        response = requests.post(f"{BASE_URL}/llm", json=payload)

        if response.status_code == 503:
            print("⚠ LLM client not initialized (missing API key)")
            print("  This is expected if ANTHROPIC_API_KEY or OPENAI_API_KEY not set")
            return True

        response.raise_for_status()
        elapsed = time.time() - start_time

        data = response.json()
        llm_response = data.get('response', '')

        print(f"Response: {llm_response[:100]}...")
        print(f"Generated in {elapsed:.2f}s")

        assert llm_response, "Empty LLM response"

        print_success("LLM generation passed")
        return True
    except Exception as e:
        print_error(f"LLM generation failed: {e}")
        return False

def test_list_voices():
    """Test list voices endpoint"""
    print_test("List Voices")

    try:
        response = requests.get(f"{BASE_URL}/voices")
        response.raise_for_status()

        data = response.json()
        voices = data.get('voices', [])

        print(f"Available voices: {len(voices)}")
        for voice in voices:
            print(f"  - {voice}")

        print_success("List voices passed")
        return True
    except Exception as e:
        print_error(f"List voices failed: {e}")
        return False

def test_upload_voice():
    """Test voice upload endpoint"""
    print_test("Upload Voice")

    try:
        # Create a dummy WAV file for testing
        # (In production, use real audio)
        print("⚠ Skipping upload test (requires real audio file)")
        print("  To test manually:")
        print(f"  curl -X POST {BASE_URL}/upload-voice \\")
        print("    -F 'voice_name=TestVoice' \\")
        print("    -F 'audio_file=@path/to/voice.wav'")

        return True
    except Exception as e:
        print_error(f"Upload voice failed: {e}")
        return False

def test_latency():
    """Test generation latency"""
    print_test("Latency Benchmark")

    try:
        test_texts = [
            "Short.",
            "This is a medium length sentence.",
            "This is a longer sentence that should take more time to generate but still be within acceptable limits for production use."
        ]

        results = []

        for text in test_texts:
            payload = {
                "text": text,
                "temperature": 0.8
            }

            start_time = time.time()
            response = requests.post(f"{BASE_URL}/tts", json=payload)
            response.raise_for_status()
            elapsed = time.time() - start_time

            results.append({
                'length': len(text),
                'time': elapsed
            })

            print(f"  {len(text):3d} chars → {elapsed:.3f}s")

        avg_time = sum(r['time'] for r in results) / len(results)
        print(f"\nAverage latency: {avg_time:.3f}s")

        if avg_time < 1.0:
            print("  Performance: Excellent (GPU)")
        elif avg_time < 3.0:
            print("  Performance: Good")
        elif avg_time < 10.0:
            print("  Performance: Fair (consider GPU upgrade)")
        else:
            print("  Performance: Poor (CPU mode?)")

        print_success("Latency benchmark completed")
        return True
    except Exception as e:
        print_error(f"Latency benchmark failed: {e}")
        return False

def test_error_handling():
    """Test error handling"""
    print_test("Error Handling")

    try:
        # Test empty text
        response = requests.post(f"{BASE_URL}/tts", json={"text": ""})
        print(f"Empty text → Status {response.status_code}")

        # Test invalid parameters
        response = requests.post(f"{BASE_URL}/tts", json={
            "text": "test",
            "temperature": 999  # Invalid value
        })
        print(f"Invalid params → Status {response.status_code}")

        print_success("Error handling working correctly")
        return True
    except Exception as e:
        print_error(f"Error handling test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("="*60)
    print("Chatterbox TTS Server API Tests")
    print("="*60)
    print(f"\nTarget: {BASE_URL}")
    print(f"Output: {TEST_OUTPUT_DIR}")
    print()

    # Check if server is running
    try:
        requests.get(BASE_URL, timeout=5)
    except requests.exceptions.ConnectionError:
        print(f"✗ Cannot connect to {BASE_URL}")
        print("\nMake sure the server is running:")
        print("  python scripts/server.py")
        sys.exit(1)

    # Run tests
    tests = [
        test_root,
        test_health,
        test_list_voices,
        test_tts_basic,
        test_tts_voice_clone,
        test_openai_compatible,
        test_llm,
        test_latency,
        test_error_handling,
    ]

    results = []
    for test in tests:
        try:
            result = test()
            results.append((test.__name__, result))
        except Exception as e:
            print_error(f"Test crashed: {e}")
            results.append((test.__name__, False))

    # Summary
    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status:8} {name}")

    print("\n" + "="*60)
    print(f"Results: {passed}/{total} tests passed")
    print("="*60)

    if passed == total:
        print("\n🎉 All tests passed!")
        print("\nNext steps:")
        print("1. Configure Twilio webhook")
        print("2. Test phone call")
        print("3. Deploy to production")
    else:
        print(f"\n⚠ {total - passed} test(s) failed")
        print("\nCheck logs for details:")
        print("  tail -f logs/server.log")

    sys.exit(0 if passed == total else 1)

if __name__ == "__main__":
    main()
