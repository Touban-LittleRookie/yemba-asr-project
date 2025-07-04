# Yemba ASR API Deployment Guide

## Deploy to Render (Free)

1. **Create a Render account** at https://render.com

2. **Create a new Web Service**:
   - Connect your GitHub repository
   - Choose "Build and deploy from a Git repository"
   - Select your repository

3. **Configure the service**:
   - **Name**: `yemba-asr-api`
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Plan**: Free

4. **Deploy**: Click "Create Web Service"

The API will be available at: `https://your-service-name.onrender.com`

## Alternative: Deploy to Railway

1. **Create a Railway account** at https://railway.app

2. **Deploy from GitHub**:
   - Click "Deploy from GitHub repo"
   - Select your repository
   - Railway will auto-detect the Python app

3. **Configure environment**:
   - Railway should automatically detect the Dockerfile
   - No additional configuration needed

## Alternative: Deploy to Hugging Face Spaces

1. **Create a Hugging Face account** at https://huggingface.co

2. **Create a new Space**:
   - Choose "Gradio" as the SDK
   - Upload your files
   - The space will automatically deploy

## API Endpoints

Once deployed, your API will have these endpoints:

- `GET /` - Health check
- `POST /validate-pronunciation/` - Pronunciation validation
  - Parameters:
    - `expected_word` (form field): The word to compare against
    - `audio` (file): WAV audio file to transcribe

## Testing the Deployed API

```bash
curl -X POST "https://your-api-url.onrender.com/validate-pronunciation/" \
  -F "expected_word=hello" \
  -F "audio=@test_audio.wav"
```

## Important Notes

- The first request may take 30-60 seconds as the Whisper model loads
- Free tier services may have cold start delays
- Consider upgrading to paid plans for production use
