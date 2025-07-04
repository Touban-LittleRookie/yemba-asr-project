from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import whisper
import tempfile
import os
from fuzzywuzzy import fuzz
import soundfile as sf
import io

# Initialize model as None - will load on first request to save memory
model = None


def get_model():
    global model
    if model is None:
        try:
            model = whisper.load_model("tiny")  # Smallest model for free tier
        except Exception as e:
            raise Exception(f"Failed to load Whisper model: {str(e)}")
    return model


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
    try:
        # Validate file extension
        if not audio.filename or not audio.filename.endswith(".wav"):
            raise HTTPException(status_code=400, detail="Only .wav files are supported")

        # Save the uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            tmp_path = tmp.name
            try:
                # Read audio file
                audio_data = await audio.read()
                if len(audio_data) == 0:
                    raise HTTPException(status_code=400, detail="Empty audio file")

                # Validate audio file format (optional - let Whisper handle most validation)
                try:
                    with sf.SoundFile(io.BytesIO(audio_data)) as sound_file:
                        # More lenient sample rate check
                        if (
                            sound_file.samplerate < 8000
                            or sound_file.samplerate > 48000
                        ):
                            raise HTTPException(
                                status_code=400,
                                detail=f"Unsupported sample rate: {sound_file.samplerate}Hz. Use 8kHz-48kHz",
                            )
                except Exception as e:
                    # If soundfile can't read it, let Whisper try anyway
                    print(f"SoundFile validation warning: {e}")

                tmp.write(audio_data)

                # Transcribe the audio with Whisper
                whisper_model = get_model()
                result = whisper_model.transcribe(tmp_path, language=None, fp16=False)
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
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)

    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        # Catch any other unexpected errors
        return JSONResponse(
            status_code=500, content={"detail": f"Unexpected server error: {str(e)}"}
        )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
