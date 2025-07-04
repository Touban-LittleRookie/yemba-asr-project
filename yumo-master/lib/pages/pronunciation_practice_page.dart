import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumo/config/api_config.dart';
import 'package:yumo/themes/colors.dart';

class PronunciationPracticePage extends StatefulWidget {
  final String language;
  final int previousScore;

  const PronunciationPracticePage({
    super.key,
    required this.language,
    required this.previousScore,
  });

  @override
  State<PronunciationPracticePage> createState() =>
      _PronunciationPracticePageState();
}

class _PronunciationPracticePageState extends State<PronunciationPracticePage>
    with TickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordedFilePath;
  bool isListening = false;
  bool hasAnswered = false;
  bool isCorrect = false;
  int currentWordIndex = 0;
  int pronunciationScore = 0;
  int totalExercises = 0;
  int completedExercises = 0;
  late AnimationController _feedbackController;
  List<Map<String, dynamic>> practiceWords = [];

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _initRecorder();
    _loadPracticeWords();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  Future<void> _loadPracticeWords() async {
    final response = await Supabase.instance.client
        .from('vocabulary')
        .select()
        .eq('category', 'nature');
    setState(() {
      practiceWords =
          (response as List<dynamic>)
              .map(
                (item) => {
                  'word': item['yemba_word'],
                  'phonetic': item['phonetic'],
                  'audio_url': item['audio_url'],
                  'id': item['id'],
                },
              )
              .toList();
      totalExercises = practiceWords.length;
    });
  }

  Future<void> _startListening() async {
    final tempDir = await getTemporaryDirectory();
    _recordedFilePath = '${tempDir.path}/recording.wav';
    await _recorder.startRecorder(
      toFile: _recordedFilePath,
      codec: Codec.pcm16WAV,
    );
    setState(() => isListening = true);
  }

  Future<void> _stopListening() async {
    await _recorder.stopRecorder();
    setState(() => isListening = false);
    if (_recordedFilePath != null) {
      await _sendToASR();
    }
  }

  Future<void> _sendToASR() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.pronunciationValidationUrl),
    );
    request.fields['expected_word'] = practiceWords[currentWordIndex]['word'];
    request.files.add(
      await http.MultipartFile.fromPath('audio', _recordedFilePath!),
    );
    try {
      final response = await request.send().timeout(ApiConfig.requestTimeout);
      final responseBody = await http.Response.fromStream(response);
      if (response.statusCode == 200) {
        final result = jsonDecode(responseBody.body);
        setState(() {
          isCorrect = result['score'] >= 80;
          hasAnswered = true;
          if (isCorrect) pronunciationScore++;
        });
        _updateUserProgress();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['result']),
              backgroundColor: isCorrect ? Colors.green : Colors.orange,
            ),
          );
        }
        _feedbackController.forward();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) _nextWord();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ASR Error: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage =
            'Connection error. Please check your internet connection.';
        if (e.toString().contains('TimeoutException')) {
          errorMessage =
              'Request timed out. The server may be starting up, please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _updateUserProgress() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await Supabase.instance.client.from('user_progress').upsert({
        'user_id': userId,
        'vocabulary_id': practiceWords[currentWordIndex]['id'],
        'completed': isCorrect,
        'score': isCorrect ? 10 : 0,
        'last_attempted': DateTime.now().toIso8601String(),
      });
    }
  }

  void _nextWord() {
    completedExercises++;

    if (completedExercises >= totalExercises) {
      // Show final results
      _showFinalResults();
      return;
    }

    setState(() {
      hasAnswered = false;
      isCorrect = false;
      _feedbackController.reset();
      currentWordIndex = (currentWordIndex + 1) % practiceWords.length;
    });
  }

  void _showFinalResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Practice Complete!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primarycolor,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: secondarycolor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(Icons.star, size: 50, color: primarycolor),
                    const SizedBox(height: 16),
                    Text(
                      'Total Score',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textcolor.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '${widget.previousScore + pronunciationScore}',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primarycolor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Passed: $pronunciationScore/$totalExercises',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: secondarycolor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primarycolor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _playAudio() async {
    final fullUrl = Supabase.instance.client.storage
        .from('audio')
        .getPublicUrl(practiceWords[currentWordIndex]['audio_url']);
    try {
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundcolor,
      appBar: AppBar(
        backgroundColor: backgroundcolor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textcolor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pronunciation Practice',
          style: GoogleFonts.poppins(
            color: primarycolor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body:
          practiceWords.isEmpty
              ? Center(child: CircularProgressIndicator(color: primarycolor))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Language: ${widget.language}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textcolor.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: secondarycolor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Progress ${completedExercises + 1}/$totalExercises',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: secondarycolor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.star, color: primarycolor, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Score: ${widget.previousScore + pronunciationScore}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: textcolor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Word display card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primarycolor,
                            primarycolor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primarycolor.withValues(alpha: 0.3),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Practice Word',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            practiceWords[currentWordIndex]['word'],
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            practiceWords[currentWordIndex]['phonetic'],
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Audio play button
                    GestureDetector(
                      onTap: _playAudio,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: secondarycolor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: secondarycolor.withValues(alpha: 0.3),
                              spreadRadius: 2,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Tap to hear pronunciation',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textcolor.withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Recording section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            isListening ? 'Recording...' : 'Ready to Record',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textcolor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Record button
                          GestureDetector(
                            onTap:
                                isListening ? _stopListening : _startListening,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isListening ? 100 : 80,
                              height: isListening ? 100 : 80,
                              decoration: BoxDecoration(
                                color: isListening ? Colors.red : primarycolor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isListening
                                            ? Colors.red
                                            : primarycolor)
                                        .withValues(alpha: 0.3),
                                    spreadRadius: isListening ? 4 : 2,
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isListening ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: isListening ? 40 : 36,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text(
                            isListening
                                ? 'Tap to stop recording'
                                : 'Tap to start recording',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: textcolor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Feedback section
                    AnimatedBuilder(
                      animation: _feedbackController,
                      builder: (context, child) {
                        return AnimatedOpacity(
                          opacity: hasAnswered ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:
                                  isCorrect
                                      ? secondarycolor.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCorrect ? secondarycolor : Colors.red,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color:
                                      isCorrect ? secondarycolor : Colors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isCorrect ? 'Excellent!' : 'Try Again!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    color:
                                        isCorrect ? secondarycolor : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
