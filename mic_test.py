import sounddevice as sd
from scipy.io.wavfile import write
import soundfile as sf
import requests
import os
import numpy as np
import librosa

# === Configuration ===
duration = 3  # seconds
default_sample_rate = 16000
output_file = "recorded.wav"
expected_word = "Mbǝŋ"
device_index = 0  # Change if you want a different mic

# === Detect Supported Sample Rate ===
try:
    device_info = sd.query_devices(device_index, "input")
    sample_rate = int(device_info["default_samplerate"])
    print(f"ℹ️ Using device '{device_info['name']}' with sample rate {sample_rate} Hz")
except Exception as e:
    print("❌ Could not detect input device:", e)
    exit(1)

# === Step 1: Record ===
try:
    print(f"🎙️ Speak the word: {expected_word}")
    recording = sd.rec(
        int(duration * sample_rate),
        samplerate=sample_rate,
        channels=1,
        dtype="float32",
        device=device_index,
    )
    sd.wait()
    temp_file = "temp_recorded.wav"
    sf.write(temp_file, recording, sample_rate)
    print("✅ Raw recording saved")

    # === Step 2: Resample to 16kHz for Whisper ===
    y, _ = librosa.load(temp_file, sr=default_sample_rate)
    sf.write(output_file, y, default_sample_rate)
    print("✅ Resampled and saved to", output_file)
except Exception as e:
    print("❌ Microphone recording failed:", str(e))
    exit(1)

# === Step 3: Send to Whisper FastAPI ===
url = "http://localhost:8000/validate-pronunciation/"
try:
    with open(output_file, "rb") as f:
        files = {"audio": f}
        data = {"expected_word": expected_word}
        print("📡 Sending to API...")
        response = requests.post(url, files=files, data=data)
        result = response.json()
        print("🔍 Result:", result)
except requests.exceptions.RequestException as e:
    print("❌ Failed to contact the API:", str(e))
except Exception as e:
    print("❌ Error:", str(e))

# (Optional) Clean up
for f in [output_file, "temp_recorded.wav"]:
    try:
        os.remove(f)
    except:
        pass
