# Yemba ASR Project

A comprehensive Automatic Speech Recognition (ASR) system for the Yemba language, integrated with a Flutter mobile application for pronunciation practice.

## 🌟 Features

- **ASR API**: FastAPI-based speech recognition using OpenAI Whisper
- **Mobile App**: Flutter app (Yumo) for interactive language learning
- **Pronunciation Practice**: Real-time pronunciation feedback
- **Cloud Deployment**: Ready for deployment on free hosting platforms

## 📁 Project Structure

```
yemba_asr_project/
├── main.py                 # FastAPI ASR server
├── requirements.txt        # Python dependencies
├── Dockerfile             # Container configuration
├── render.yaml            # Render deployment config
├── DEPLOYMENT.md          # Deployment guide
├── INTEGRATION_GUIDE.md   # Integration documentation
├── metadata/              # Corpus and speaker data
│   ├── speakers_description.csv
│   └── words_corpus.csv
└── yumo-master/           # Flutter mobile application
    ├── lib/
    │   ├── pages/         # App screens
    │   ├── config/        # API configuration
    │   ├── images/        # App assets
    │   └── themes/        # UI themes
    ├── android/
    ├── ios/
    └── pubspec.yaml
```

## 🚀 Quick Start

### 1. ASR API Setup

```bash
# Install dependencies (use virtual environment)
pip install -r requirements.txt

# Run locally
python main.py
```

### 2. Deploy to Cloud

Follow the detailed instructions in [DEPLOYMENT.md](DEPLOYMENT.md) to deploy to:
- Render (recommended for free tier)
- Railway
- Hugging Face Spaces

### 3. Flutter App Setup

```bash
cd yumo-master
flutter pub get
flutter run
```

## 🔧 Configuration

### API Configuration

Update `yumo-master/lib/config/api_config.dart` with your deployed API URL:

```dart
static const String asrApiBaseUrl = 'https://your-app-name.onrender.com';
```

## 📱 Mobile App Features

- **Authentication**: User login/signup with African mask branding
- **Pronunciation Practice**: Record and get real-time feedback
- **Progress Tracking**: Monitor learning progress
- **Vocabulary Exercises**: Interactive word matching games
- **Stories**: Cultural stories in Yemba language

## 🛠️ Technology Stack

### Backend
- **FastAPI**: Modern Python web framework
- **OpenAI Whisper**: State-of-the-art speech recognition
- **FuzzyWuzzy**: Pronunciation similarity matching
- **SoundFile**: Audio processing

### Frontend
- **Flutter**: Cross-platform mobile development
- **Supabase**: Backend-as-a-Service for data storage
- **Google Fonts**: Typography
- **AudioPlayers**: Audio playback functionality

## 📊 API Endpoints

### `GET /`
Health check endpoint

### `POST /validate-pronunciation/`
Validates pronunciation accuracy

**Parameters:**
- `expected_word` (form): Target word for comparison
- `audio` (file): WAV audio recording

**Response:**
```json
{
  "result": "✅ Good pronunciation",
  "transcription": "recognized text",
  "score": 85
}
```

## 🔒 Security & Privacy

- Environment variables for sensitive configuration
- CORS enabled for cross-origin requests
- No audio files stored permanently
- User data handled securely through Supabase

## 📚 Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Detailed deployment instructions
- [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - App integration guide

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- OpenAI Whisper team for the excellent ASR model
- Flutter team for the amazing mobile framework
- Supabase for the backend infrastructure
- The Yemba language community

## 📞 Support

For questions or support, please open an issue in this repository.

---

**Note**: This project excludes large dataset files and preprocessed audio for repository size optimization. Contact the maintainer for access to training data if needed.
