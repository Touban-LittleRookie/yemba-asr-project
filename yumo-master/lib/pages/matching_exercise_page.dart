import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:yumo/themes/colors.dart';

class MatchingExercisePage extends StatefulWidget {
  final String language;
  final int previousScore;

  const MatchingExercisePage({
    super.key,
    required this.language,
    required this.previousScore,
  });

  @override
  State<MatchingExercisePage> createState() => _MatchingExercisePageState();
}

class _MatchingExercisePageState extends State<MatchingExercisePage>
    with TickerProviderStateMixin {
  int correctMatches = 0;
  int totalAttempts = 0;
  List<String> selectedAudio = [];
  List<String> selectedImages = [];
  String? matchedPair;
  bool isProcessingMatch = false;
  List<Map<String, String>> failedExercises = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> currentExercises = [];

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching vocabulary: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating progress: $e')));
      }
    }
  }

  Future<void> _loadExercises() async {
    final data = await fetchVocabulary();
    setState(() {
      currentExercises =
          data.map((item) {
            return {
              'id': item['id'],
              'yemba': item['yemba_word'],
              'phonetic': item['phonetic'],
              'image': item['image_url'].split('/').last,
              'audio_url': item['audio_url'],
            };
          }).toList();
    });
  }

  void _startNewRound() {
    setState(() {
      if (failedExercises.isNotEmpty) {
        currentExercises.addAll(failedExercises);
        failedExercises.clear();
      }
    });
  }

  void _playAudio(String audioUrl) async {
    final fullUrl = Supabase.instance.client.storage
        .from('audio')
        .getPublicUrl(audioUrl);
    try {
      await _audioPlayer.play(UrlSource(fullUrl));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
    }
  }

  void _selectAudio(String yembaWord) {
    if (isProcessingMatch) return;
    setState(() {
      selectedAudio = [yembaWord];
    });
    final audioUrl =
        currentExercises.firstWhere(
          (w) => w['yemba'] == yembaWord,
        )['audio_url'];
    _playAudio(audioUrl);
    _checkForMatch();
  }

  void _selectImage(String image) {
    if (isProcessingMatch) return;
    setState(() {
      selectedImages = [image];
    });
    _checkForMatch();
  }

  void _checkForMatch() {
    if (selectedAudio.isNotEmpty && selectedImages.isNotEmpty) {
      setState(() {
        isProcessingMatch = true;
        totalAttempts++;
      });

      final selectedYemba = selectedAudio.first;
      final selectedImage = selectedImages.first;

      final correctImage =
          currentExercises.firstWhere(
            (word) => word['yemba'] == selectedYemba,
            orElse: () => {},
          )['image'];
      final vocabularyId =
          currentExercises.firstWhere(
            (word) => word['yemba'] == selectedYemba,
            orElse: () => {},
          )['id'];

      final isCorrect = correctImage == selectedImage;

      if (isCorrect) {
        correctMatches++;
        updateUserProgress(vocabularyId, true, 1);
        setState(() => matchedPair = '$selectedYemba-$selectedImage');
        _feedbackController.forward();
        Future.delayed(const Duration(milliseconds: 1000), () {
          setState(() {
            currentExercises.removeWhere((w) => w['yemba'] == selectedYemba);
            selectedAudio.clear();
            selectedImages.clear();
            matchedPair = null;
            isProcessingMatch = false;
          });
          _feedbackController.reset();
          if (currentExercises.isEmpty && failedExercises.isEmpty) {
            _showCompletionDialog();
          }
        });
      } else {
        updateUserProgress(vocabularyId, false, 0);
        _feedbackController.forward();
        Future.delayed(const Duration(milliseconds: 900), () {
          setState(() {
            final failed = currentExercises.firstWhere(
              (w) => w['yemba'] == selectedYemba,
            );
            failedExercises.add({
              'id': failed['id'].toString(),
              'yemba': failed['yemba'] ?? '',
              'phonetic': failed['phonetic'] ?? '',
              'image': failed['image'] ?? '',
              'audio_url': failed['audio_url'] ?? '',
            });
            currentExercises.remove(failed);
            selectedAudio.clear();
            selectedImages.clear();
            isProcessingMatch = false;
          });
          _feedbackController.reset();
          if (currentExercises.isEmpty) _startNewRound();
        });
      }
    }
  }

  void _showCompletionDialog() {
    final total = correctMatches + failedExercises.length;
    final firstTryCorrect = correctMatches;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration, size: 60, color: secondarycolor),
                const SizedBox(height: 16),
                Text(
                  'All Exercises Complete!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primarycolor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Great job! You matched all nature words in Yemba.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 15, color: textcolor),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: secondarycolor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Your Score',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textcolor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$firstTryCorrect / $total',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: secondarycolor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Correct on first try',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textcolor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondarycolor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentExercises.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1C1C1C),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final progress =
        (correctMatches) /
        (correctMatches + currentExercises.length + failedExercises.length);

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
          value: progress,
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation(secondarycolor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match the sound to the image',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tap to hear the word:',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ...currentExercises.map((word) {
              final isSelected = selectedAudio.contains(word['yemba']);
              final isMatched =
                  matchedPair?.startsWith(word['yemba'] ?? '') ?? false;

              return Opacity(
                opacity: isMatched ? 0.3 : 1.0,
                child: GestureDetector(
                  onTap:
                      isMatched
                          ? null
                          : () => _selectAudio(word['yemba'] ?? ''),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? secondarycolor : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? secondarycolor : Colors.grey[700]!,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.volume_up,
                          color: isSelected ? Colors.white : primarycolor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          word['phonetic'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),
            Text(
              'Now choose the matching image:',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
              children:
                  currentExercises.map((word) {
                    final isSelected = selectedImages.contains(word['image']);
                    final isMatched =
                        matchedPair?.endsWith(word['image'] ?? '') ?? false;

                    return Opacity(
                      opacity: isMatched ? 0.3 : 1.0,
                      child: GestureDetector(
                        onTap:
                            isMatched
                                ? null
                                : () => _selectImage(word['image'] ?? ''),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? primarycolor
                                    : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected ? primarycolor : Colors.grey[700]!,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'lib/images/${word['image']}',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
            if (selectedAudio.isNotEmpty && selectedImages.isNotEmpty) ...[
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _feedbackController,
                builder: (context, child) {
                  final isCorrect = matchedPair != null;
                  return Transform.scale(
                    scale: 0.85 + (_feedbackController.value * 0.15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isCorrect ? 'Correct Match!' : 'Try Again!',
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
