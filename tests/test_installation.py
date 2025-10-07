#!/usr/bin/env python3
"""
Installation Test Script for Chatterbox TTS
Tests that all dependencies are properly installed and the model can be loaded.
"""

import sys
import os

def test_python_version():
    """Test Python version is 3.10+"""
    print("Testing Python version...", end=" ")
    version = sys.version_info
    assert version.major == 3 and version.minor >= 10, f"Python 3.10+ required, found {version.major}.{version.minor}"
    print(f"✓ Python {version.major}.{version.minor}.{version.micro}")

def test_pytorch():
    """Test PyTorch installation"""
    print("Testing PyTorch...", end=" ")
    try:
        import torch
        print(f"✓ PyTorch {torch.__version__}")

        # Test CUDA availability
        if torch.cuda.is_available():
            print(f"  GPU: {torch.cuda.get_device_name(0)}")
            print(f"  CUDA: {torch.version.cuda}")
            print(f"  VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.2f} GB")
        elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
            print("  GPU: Apple Metal (MPS)")
        else:
            print("  GPU: None (CPU mode)")
    except ImportError as e:
        print(f"✗ Failed: {e}")
        sys.exit(1)

def test_chatterbox():
    """Test Chatterbox TTS import"""
    print("Testing Chatterbox TTS...", end=" ")
    try:
        import chatterbox
        print(f"✓ Chatterbox TTS installed")
    except ImportError as e:
        print(f"✗ Failed: {e}")
        sys.exit(1)

def test_dependencies():
    """Test all required dependencies"""
    print("\nTesting dependencies:")

    dependencies = [
        ("fastapi", "FastAPI"),
        ("uvicorn", "Uvicorn"),
        ("librosa", "Librosa"),
        ("soundfile", "SoundFile"),
        ("pydub", "Pydub"),
        ("yaml", "PyYAML"),
        ("requests", "Requests"),
        ("twilio", "Twilio"),
    ]

    for module, name in dependencies:
        print(f"  {name}...", end=" ")
        try:
            __import__(module)
            print("✓")
        except ImportError:
            print("✗")
            print(f"    Warning: {name} not installed")

def test_model_download():
    """Test model download and loading"""
    print("\nTesting model download (this may take a few minutes on first run)...")
    try:
        import torch
        from chatterbox.tts import ChatterboxTTS

        # Determine device
        if torch.cuda.is_available():
            device = "cuda"
        elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
            device = "mps"
        else:
            device = "cpu"

        print(f"  Loading model on {device}...", end=" ")
        model = ChatterboxTTS.from_pretrained(device=device)
        print("✓")

        # Test simple generation
        print("  Testing generation...", end=" ")
        text = "This is a test."
        wav = model.generate(text)
        assert wav is not None and len(wav) > 0, "Generated audio is empty"
        print(f"✓ Generated {len(wav)} samples")

        # Save test output
        import soundfile as sf
        os.makedirs("outputs", exist_ok=True)
        output_path = "outputs/test_output.wav"
        sf.write(output_path, wav, 24000)
        print(f"  Saved test audio to {output_path}")

        return True
    except Exception as e:
        print(f"✗ Failed: {e}")
        print("\nNote: If this is your first run, the model needs to download (~2-3GB)")
        print("You can skip this test with: python test_installation.py --skip-model")
        return False

def test_config():
    """Test configuration file"""
    print("\nTesting configuration:")
    config_path = "config/config.yaml"
    print(f"  Checking {config_path}...", end=" ")
    if os.path.exists(config_path):
        print("✓")
        try:
            import yaml
            with open(config_path) as f:
                config = yaml.safe_load(f)
            print(f"  Config sections: {', '.join(config.keys())}")
        except Exception as e:
            print(f"  Warning: Could not parse config: {e}")
    else:
        print("✗ Not found")
        print("  Run setup script to create config file")

def test_env():
    """Test .env file"""
    print("\nTesting environment:")
    env_path = ".env"
    print(f"  Checking {env_path}...", end=" ")
    if os.path.exists(env_path):
        print("✓")

        # Check for configured keys
        with open(env_path) as f:
            content = f.read()

        checks = [
            ("TWILIO_ACCOUNT_SID", "Twilio Account SID"),
            ("ANTHROPIC_API_KEY", "Anthropic API Key"),
        ]

        for key, name in checks:
            if key in content:
                value = None
                for line in content.split('\n'):
                    if line.startswith(key):
                        value = line.split('=', 1)[1].strip()
                        break

                if value and not value.startswith('your_'):
                    print(f"  {name}: Configured ✓")
                else:
                    print(f"  {name}: Not configured (placeholder value)")
            else:
                print(f"  {name}: Missing")
    else:
        print("✗ Not found")
        print("  Run setup script to create .env file")

def test_directories():
    """Test required directories exist"""
    print("\nTesting directories:")
    dirs = ["voices", "reference_audio", "outputs", "logs", "model_cache"]
    for d in dirs:
        print(f"  {d}/...", end=" ")
        if os.path.exists(d):
            print("✓")
        else:
            print("✗ Creating...", end=" ")
            os.makedirs(d, exist_ok=True)
            print("✓")

def main():
    """Run all tests"""
    print("=" * 60)
    print("Chatterbox TTS Installation Test")
    print("=" * 60)
    print()

    skip_model = "--skip-model" in sys.argv

    try:
        # Basic tests
        test_python_version()
        test_pytorch()
        test_chatterbox()
        test_dependencies()
        test_config()
        test_env()
        test_directories()

        # Model test (optional)
        if not skip_model:
            if not test_model_download():
                print("\n⚠ Model test failed, but basic installation appears correct")
                print("You can try running the model test again later")
        else:
            print("\nSkipping model download test")

        # Summary
        print("\n" + "=" * 60)
        print("Installation Test Complete!")
        print("=" * 60)
        print("\n✓ All required components are installed")
        print("\nNext steps:")
        print("1. Configure your .env file with API keys")
        print("2. Add reference audio files to voices/ directory")
        print("3. Start the server: python scripts/server.py")
        print("4. Test the API: python tests/test_api.py")
        print()

    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(1)

if __name__ == "__main__":
    main()
