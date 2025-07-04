from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse
import whisper
import tempfile
import os
from fuzzywuzzy import fuzz

# Load Whisper small model once at startup
model = whisper.load_model("small")

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Welcome to the Yemba Whisper ASR API"}

@app.post("/validate-pronunciation/")
async def validate_pronunciation(
    expected_word: str = Form(...),
    audio: UploadFile = File(...)
):
    # Save the uploaded file temporarily
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        tmp_path = tmp.name
        tmp.write(await audio.read())

    try:
        # Transcribe the audio with Whisper
        result = model.transcribe(tmp_path, language="fr", fp16=False)
        transcription = result["text"].strip()

        # Clean expected and actual strings
        transcription_clean = transcription.lower().strip()
        expected_clean = expected_word.lower().strip()

        # Fuzzy match score
        score = fuzz.ratio(expected_clean, transcription_clean)

        # Decide result
        if score >= 80:
            return {"result": "✅ Good pronunciation", "transcription": transcription, "score": score}
        else:
            return {"result": "❌ Incorrect", "transcription": transcription, "score": score}

    finally:
        os.remove(tmp_path)

