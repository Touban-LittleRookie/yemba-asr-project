import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Save user's current progress
  static Future<void> saveProgress({
    required String userId,
    required String language,
    required String exerciseType, // 'vocabulary', 'pronunciation', 'stories'
    required int currentIndex,
    required int totalItems,
    required int score,
  }) async {
    try {
      await _supabase.from('user_session_progress').upsert({
        'user_id': userId,
        'language': language,
        'exercise_type': exerciseType,
        'current_index': currentIndex,
        'total_items': totalItems,
        'score': score,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  // Get user's current progress
  static Future<Map<String, dynamic>?> getProgress(String userId) async {
    try {
      final response = await _supabase
          .from('user_session_progress')
          .select()
          .eq('user_id', userId)
          .order('last_updated', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
      return null;
    } catch (e) {
      print('Error getting progress: $e');
      return null;
    }
  }

  // Clear progress when session is completed
  static Future<void> clearProgress(String userId) async {
    try {
      await _supabase
          .from('user_session_progress')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing progress: $e');
    }
  }

  // Get user statistics
  static Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final response = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', userId);

      int totalScore = 0;
      int completedLessons = 0;
      Set<String> uniqueWords = {};

      for (var progress in response) {
        totalScore += (progress['score'] as int? ?? 0);
        if (progress['completed'] == true) {
          completedLessons++;
        }
        uniqueWords.add(progress['vocabulary_id'].toString());
      }

      return {
        'totalScore': totalScore,
        'completedLessons': completedLessons,
        'totalWords': uniqueWords.length,
        'currentStreak': 5, // Mock data for now - could be calculated from dates
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalScore': 0,
        'completedLessons': 0,
        'totalWords': 0,
        'currentStreak': 0,
      };
    }
  }

  // Calculate completion percentage
  static double getCompletionPercentage(int currentIndex, int totalItems) {
    if (totalItems == 0) return 0.0;
    return (currentIndex / totalItems).clamp(0.0, 1.0);
  }

  // Get next recommended exercise type
  static String getNextExerciseType(Map<String, dynamic>? progress) {
    if (progress == null) return 'vocabulary';
    
    final exerciseType = progress['exercise_type'] as String;
    final currentIndex = progress['current_index'] as int;
    final totalItems = progress['total_items'] as int;
    
    // If current exercise is not completed, continue with it
    if (currentIndex < totalItems) {
      return exerciseType;
    }
    
    // Move to next exercise type
    switch (exerciseType) {
      case 'vocabulary':
        return 'pronunciation';
      case 'pronunciation':
        return 'stories';
      case 'stories':
        return 'vocabulary'; // Loop back
      default:
        return 'vocabulary';
    }
  }

  // Get progress description for UI
  static String getProgressDescription(Map<String, dynamic>? progress) {
    if (progress == null) {
      return 'Start your learning journey';
    }
    
    final exerciseType = progress['exercise_type'] as String;
    final currentIndex = progress['current_index'] as int;
    final totalItems = progress['total_items'] as int;
    final percentage = (getCompletionPercentage(currentIndex, totalItems) * 100).round();
    
    String typeName;
    switch (exerciseType) {
      case 'vocabulary':
        typeName = 'Vocabulary';
        break;
      case 'pronunciation':
        typeName = 'Pronunciation';
        break;
      case 'stories':
        typeName = 'Stories';
        break;
      default:
        typeName = 'Learning';
    }
    
    if (currentIndex >= totalItems) {
      return '$typeName completed! Ready for next lesson';
    }
    
    return '$typeName: $percentage% complete';
  }
}
