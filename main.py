from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import whisper
import tempfile
import os
from fuzzywuzzy import fuzz
import soundfile as sf
import io

# Load Whisper small model once at startup
try:
    model = whisper.load_model("small")
except Exception as e:
    raise Exception(f"Failed to load Whisper model: {str(e)}")

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)


@app.get("/")
def root():
    return {"message": "Welcome to the Yemba Whisper ASR API"}


@app.post("/validate-pronunciation/")
async def validate_pronunciation(
    expected_word: str = Form(...), audio: UploadFile = File(...)
):
    # Validate file extension
    if not audio.filename.endswith(".wav"):
        raise HTTPException(status_code=400, detail="Only .wav files are supported")

    # Save the uploaded file temporarily
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        tmp_path = tmp.name
        try:
            # Read and validate audio file
            audio_data = await audio.read()
            with sf.SoundFile(io.BytesIO(audio_data)) as sound_file:
                if sound_file.samplerate not in [16000, 44100]:
                    raise HTTPException(
                        status_code=400,
                        detail="Unsupported sample rate. Use 16kHz or 44.1kHz",
                    )
            tmp.write(audio_data)

            # Transcribe the audio with Whisper
            result = model.transcribe(tmp_path, language=None, fp16=False)
            transcription = result["text"].strip()

            # Clean expected and actual strings
            transcription_clean = transcription.lower().strip()
            expected_clean = expected_word.lower().strip()

            # Fuzzy match score
            score = fuzz.ratio(expected_clean, transcription_clean)

            # Decide result
            if score >= 80:
                return {
                    "result": "✅ Good pronunciation",
                    "transcription": transcription,
                    "score": score,
                }
            else:
                return {
                    "result": "❌ Incorrect",
                    "transcription": transcription,
                    "score": score,
                }

        except Exception as e:
            raise HTTPException(
                status_code=500, detail=f"Transcription error: {str(e)}"
            )
        finally:
            os.remove(tmp_path)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
