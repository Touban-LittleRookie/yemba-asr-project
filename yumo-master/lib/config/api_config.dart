class ApiConfig {
  // ASR API Configuration
  // Your deployed API URL
  static const String asrApiBaseUrl = 'https://yemba-asr-api.onrender.com';
  static const String validatePronunciationEndpoint =
      '/validate-pronunciation/';

  // Full URL for pronunciation validation
  static String get pronunciationValidationUrl =>
      '$asrApiBaseUrl$validatePronunciationEndpoint';

  // For local development, uncomment the line below and comment the production URL above
  // static const String asrApiBaseUrl = 'http://192.168.85.214:8000';

  // Timeout configurations
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
}
