# Yumo ASR Integration Guide

## Overview

This guide explains how to integrate the Yemba ASR (Automatic Speech Recognition) model with the Yumo Flutter app for pronunciation practice.

## Architecture

```
Flutter App (Yumo) → HTTP Request → Deployed ASR API → Whisper Model → Response
```

## Setup Instructions

### 1. Deploy the ASR API

1. **Choose a deployment platform** (recommended: Render for free tier):
   - Render: https://render.com
   - Railway: https://railway.app
   - Hugging Face Spaces: https://huggingface.co/spaces

2. **Deploy using the provided files**:
   - `main.py` - FastAPI application
   - `requirements.txt` - Python dependencies
   - `Dockerfile` - Container configuration
   - `render.yaml` - Render deployment config

3. **Get your deployed URL** (e.g., `https://your-app-name.onrender.com`)

### 2. Configure the Flutter App

1. **Update API configuration**:
   - Open `yumo-master/lib/config/api_config.dart`
   - Replace `https://your-app-name.onrender.com` with your actual deployed URL

2. **For local development**:
   - Uncomment the local development line in `api_config.dart`
   - Make sure your local API is running on the correct IP/port

### 3. Test the Integration

1. **Run the Flutter app**:
   ```bash
   cd yumo-master
   flutter run
   ```

2. **Navigate to Pronunciation Practice**:
   - Go to the pronunciation practice screen
   - Try recording your voice
   - The app should send the audio to your deployed API

## API Endpoints

### POST /validate-pronunciation/

Validates pronunciation by comparing recorded audio with expected word.

**Parameters:**
- `expected_word` (form field): The word to compare against
- `audio` (file): WAV audio file to transcribe

**Response:**
```json
{
  "result": "✅ Good pronunciation" | "❌ Incorrect",
  "transcription": "transcribed text",
  "score": 85
}
```

## Features

### Current Implementation

- ✅ Audio recording in Flutter app
- ✅ HTTP multipart file upload to ASR API
- ✅ Whisper-based speech recognition
- ✅ Fuzzy matching for pronunciation scoring
- ✅ Real-time feedback to user
- ✅ Progress tracking
- ✅ Error handling with user-friendly messages
- ✅ Timeout handling for slow API responses

### Error Handling

The app handles various error scenarios:
- Network connectivity issues
- API timeout (30 seconds)
- Server errors (4xx, 5xx)
- Invalid audio format
- Microphone permission issues

## Deployment Considerations

### Free Tier Limitations

- **Cold starts**: First request may take 30-60 seconds
- **Resource limits**: Limited CPU/memory on free tiers
- **Request timeouts**: May need to increase timeout for model loading

### Production Recommendations

- Use paid hosting for better performance
- Implement caching for frequently used words
- Add request queuing for high traffic
- Monitor API usage and performance

## Troubleshooting

### Common Issues

1. **"Connection error"**:
   - Check internet connection
   - Verify API URL is correct
   - Ensure API is deployed and running

2. **"Request timed out"**:
   - API may be cold starting (wait and retry)
   - Check if API is overloaded
   - Increase timeout in `api_config.dart`

3. **"ASR Error: 500"**:
   - Check API logs for errors
   - Verify audio file format (should be WAV)
   - Check if Whisper model loaded correctly

### Testing API Directly

```bash
# Test API health
curl https://your-api-url.onrender.com/

# Test pronunciation validation
curl -X POST "https://your-api-url.onrender.com/validate-pronunciation/" \
  -F "expected_word=hello" \
  -F "audio=@test_audio.wav"
```

## Next Steps

1. Deploy your ASR API to your preferred platform
2. Update the API URL in the Flutter app configuration
3. Test the integration thoroughly
4. Consider implementing additional features like:
   - Offline mode with local speech recognition
   - Multiple language support
   - Advanced pronunciation analytics
   - Voice activity detection
