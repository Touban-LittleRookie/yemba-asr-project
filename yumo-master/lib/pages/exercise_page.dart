import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:yumo/themes/colors.dart';
import 'package:yumo/services/progress_service.dart';
import 'package:yumo/pages/pronunciation_practice_page.dart';

class ExercisePage extends StatefulWidget {
  final String language;

  const ExercisePage({super.key, required this.language});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage>
    with TickerProviderStateMixin {
  int currentExercise = 0;
  int score = 0;
  int totalExercises = 0;
  int completedExercises = 0;
  bool hasAnswered = false;
  bool isCorrect = false;
  String selectedAnswer = '';
  List<Map<String, dynamic>> failedExercises = [];
  List<Map<String, dynamic>> exercises = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadExercises();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchVocabulary() async {
    try {
      final response = await Supabase.instance.client
          .from('vocabulary')
          .select()
          .eq('category', 'nature');
      return response;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching vocabulary: $e')),
        );
      }
      return [];
    }
  }

  Future<void> updateUserProgress(
    int vocabularyId,
    bool completed,
    int score,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client.from('user_progress').upsert({
          'user_id': userId,
          'vocabulary_id': vocabularyId,
          'completed': completed,
          'score': score,
          'last_attempted': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating progress: $e')),
          );
        }
      }
    }
  }

  Future<void> _loadExercises() async {
    final data = await fetchVocabulary();
    setState(() {
      exercises =
          data.map((item) {
            return {
              'id': item['id'],
              'word': item['yemba_word'],
              'phonetic': item['phonetic'],
              'english': item['english_translation'],
              'french': item['french_translation'],
              'correctImage': item['image_url'].split('/').last,
              'audio_url': item['audio_url'],
              'options': _generateOptions(item, data),
            };
          }).toList();
      totalExercises = exercises.length;
    });
  }

  List<Map<String, String>> _generateOptions(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> allItems,
  ) {
    final correctOption = {
      'image': item['image_url'].split('/').last,
      'label': item['english_translation'],
    };
    final otherOptions =
        allItems
            .where((i) => i['yemba_word'] != item['yemba_word'])
            .toList()
            .asMap()
            .entries
            .take(3)
            .map(
              (entry) => {
                'image': entry.value['image_url'].split('/').last,
                'label': entry.value['english_translation'],
              },
            )
            .toList();
    final options = [correctOption, ...otherOptions]..shuffle();
    return options.map((e) => e.cast<String, String>()).toList();
  }

  void _playAudio(String audioUrl) async {
    final fullUrl = Supabase.instance.client.storage
        .from('audio')
        .getPublicUrl(audioUrl);
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

  void _selectAnswer(String imageName) {
    if (hasAnswered) return;

    setState(() {
      selectedAnswer = imageName;
      hasAnswered = true;
      isCorrect = imageName == exercises[currentExercise]['correctImage'];
    });

    _feedbackController.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextExercise();
    });
  }

  void _nextExercise() {
    final currentVocabularyId = exercises[currentExercise]['id'];
    if (isCorrect) {
      score += 1;
      updateUserProgress(currentVocabularyId, true, 1);
    } else {
      updateUserProgress(currentVocabularyId, false, 0);
    }

    completedExercises++;
    exercises.removeAt(currentExercise);

    // Save progress
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      ProgressService.saveProgress(
        userId: userId,
        language: widget.language,
        exerciseType: 'vocabulary',
        currentIndex: completedExercises,
        totalItems: totalExercises,
        score: score,
      );
    }

    if (completedExercises >= totalExercises) {
      // Clear progress and show final results
      if (userId != null) {
        ProgressService.clearProgress(userId);
      }
      _showFinalResults();
      return;
    }

    if (exercises.isNotEmpty) {
      setState(() {
        hasAnswered = false;
        isCorrect = false;
        selectedAnswer = '';
      });
      _feedbackController.reset();
    } else {
      // If no more exercises, show results
      if (userId != null) {
        ProgressService.clearProgress(userId);
      }
      _showFinalResults();
    }
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
            'Exercise Complete!',
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
                    Icon(Icons.quiz, size: 50, color: primarycolor),
                    const SizedBox(height: 16),
                    Text(
                      'Exercise Results',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: textcolor.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'Score: ${score * 2}',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primarycolor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Passed: $score/$totalExercises',
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => PronunciationPracticePage(
                            language: widget.language,
                            previousScore: score * 2,
                          ),
                    ),
                  );
                },
                child: Text(
                  'Continue to Pronunciation',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1C1C1C),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final current = exercises[currentExercise];

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: LinearProgressIndicator(
          value: (exercises.length - currentExercise) / exercises.length,
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation<Color>(secondarycolor),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _playAudio(current['audio_url']),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primarycolor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  current['word'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: secondarycolor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Select the correct image:',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children:
                    current['options'].map<Widget>((option) {
                      final isSelected = selectedAnswer == option['image'];
                      final isCorrectOption =
                          option['image'] == current['correctImage'];

                      Color borderColor = Colors.grey[600]!;
                      if (hasAnswered && isSelected) {
                        borderColor = isCorrect ? secondarycolor : Colors.red;
                      } else if (hasAnswered && isCorrectOption && !isCorrect) {
                        borderColor = secondarycolor;
                      }

                      return GestureDetector(
                        onTap: () => _selectAnswer(option['image']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            border: Border.all(color: borderColor, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Image.asset(
                                    'lib/images/${option['image']}',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Text(
                                option['label'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            if (hasAnswered) ...[
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _feedbackController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.9 + (_feedbackController.value * 0.1),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCorrect ? secondarycolor : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCorrect ? 'Correct!' : 'Wrong!',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
