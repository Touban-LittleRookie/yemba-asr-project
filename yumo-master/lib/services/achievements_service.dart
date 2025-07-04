import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int targetValue;
  final String category; // 'score', 'lessons', 'streak', 'words'
  final bool isUnlocked;
  final int currentValue;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.targetValue,
    required this.category,
    this.isUnlocked = false,
    this.currentValue = 0,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
}

class AchievementsService {
  static List<Achievement> getAllAchievements(Map<String, int> userStats) {
    return [
      // Score-based achievements
      Achievement(
        id: 'first_points',
        title: 'First Steps',
        description: 'Earn your first 10 points',
        icon: Icons.star,
        color: Colors.amber,
        targetValue: 10,
        category: 'score',
        isUnlocked: userStats['totalScore']! >= 10,
        currentValue: userStats['totalScore']!,
      ),
      Achievement(
        id: 'century_club',
        title: 'Century Club',
        description: 'Reach 100 points',
        icon: Icons.emoji_events,
        color: Colors.orange,
        targetValue: 100,
        category: 'score',
        isUnlocked: userStats['totalScore']! >= 100,
        currentValue: userStats['totalScore']!,
      ),
      Achievement(
        id: 'high_scorer',
        title: 'High Scorer',
        description: 'Achieve 500 points',
        icon: Icons.military_tech,
        color: Colors.purple,
        targetValue: 500,
        category: 'score',
        isUnlocked: userStats['totalScore']! >= 500,
        currentValue: userStats['totalScore']!,
      ),

      // Lesson-based achievements
      Achievement(
        id: 'first_lesson',
        title: 'Getting Started',
        description: 'Complete your first lesson',
        icon: Icons.school,
        color: Colors.blue,
        targetValue: 1,
        category: 'lessons',
        isUnlocked: userStats['completedLessons']! >= 1,
        currentValue: userStats['completedLessons']!,
      ),
      Achievement(
        id: 'dedicated_learner',
        title: 'Dedicated Learner',
        description: 'Complete 10 lessons',
        icon: Icons.book,
        color: Colors.green,
        targetValue: 10,
        category: 'lessons',
        isUnlocked: userStats['completedLessons']! >= 10,
        currentValue: userStats['completedLessons']!,
      ),
      Achievement(
        id: 'lesson_master',
        title: 'Lesson Master',
        description: 'Complete 50 lessons',
        icon: Icons.auto_awesome,
        color: Colors.indigo,
        targetValue: 50,
        category: 'lessons',
        isUnlocked: userStats['completedLessons']! >= 50,
        currentValue: userStats['completedLessons']!,
      ),

      // Streak-based achievements
      Achievement(
        id: 'consistent',
        title: 'Consistent',
        description: 'Maintain a 3-day streak',
        icon: Icons.local_fire_department,
        color: Colors.red,
        targetValue: 3,
        category: 'streak',
        isUnlocked: userStats['currentStreak']! >= 3,
        currentValue: userStats['currentStreak']!,
      ),
      Achievement(
        id: 'on_fire',
        title: 'On Fire!',
        description: 'Maintain a 7-day streak',
        icon: Icons.whatshot,
        color: Colors.deepOrange,
        targetValue: 7,
        category: 'streak',
        isUnlocked: userStats['currentStreak']! >= 7,
        currentValue: userStats['currentStreak']!,
      ),
      Achievement(
        id: 'unstoppable',
        title: 'Unstoppable',
        description: 'Maintain a 30-day streak',
        icon: Icons.flash_on,
        color: Colors.yellow,
        targetValue: 30,
        category: 'streak',
        isUnlocked: userStats['currentStreak']! >= 30,
        currentValue: userStats['currentStreak']!,
      ),

      // Vocabulary-based achievements
      Achievement(
        id: 'word_collector',
        title: 'Word Collector',
        description: 'Learn 25 new words',
        icon: Icons.translate,
        color: Colors.teal,
        targetValue: 25,
        category: 'words',
        isUnlocked: userStats['totalWords']! >= 25,
        currentValue: userStats['totalWords']!,
      ),
      Achievement(
        id: 'vocabulary_builder',
        title: 'Vocabulary Builder',
        description: 'Learn 100 new words',
        icon: Icons.library_books,
        color: Colors.cyan,
        targetValue: 100,
        category: 'words',
        isUnlocked: userStats['totalWords']! >= 100,
        currentValue: userStats['totalWords']!,
      ),
      Achievement(
        id: 'word_master',
        title: 'Word Master',
        description: 'Learn 500 new words',
        icon: Icons.psychology,
        color: Colors.pink,
        targetValue: 500,
        category: 'words',
        isUnlocked: userStats['totalWords']! >= 500,
        currentValue: userStats['totalWords']!,
      ),

      // Special achievements
      Achievement(
        id: 'perfect_score',
        title: 'Perfect Score',
        description: 'Get 100% on any exercise',
        icon: Icons.grade,
        color: const Color.fromARGB(255, 255, 192, 19),
        targetValue: 1,
        category: 'special',
        isUnlocked: false, // This would need special tracking
        currentValue: 0,
      ),
      Achievement(
        id: 'culture_explorer',
        title: 'Culture Explorer',
        description: 'Read 5 traditional stories',
        icon: Icons.explore,
        color: Colors.brown,
        targetValue: 5,
        category: 'stories',
        isUnlocked: false, // This would need special tracking
        currentValue: 0,
      ),
    ];
  }

  static List<Achievement> getUnlockedAchievements(Map<String, int> userStats) {
    return getAllAchievements(userStats).where((achievement) => achievement.isUnlocked).toList();
  }

  static List<Achievement> getInProgressAchievements(Map<String, int> userStats) {
    return getAllAchievements(userStats)
        .where((achievement) => !achievement.isUnlocked && achievement.currentValue > 0)
        .toList();
  }

  static Achievement? getNextAchievement(Map<String, int> userStats, String category) {
    final achievements = getAllAchievements(userStats)
        .where((achievement) => achievement.category == category && !achievement.isUnlocked)
        .toList();
    
    if (achievements.isEmpty) return null;
    
    // Sort by target value to get the next closest achievement
    achievements.sort((a, b) => a.targetValue.compareTo(b.targetValue));
    return achievements.first;
  }

  static int getTotalAchievements() {
    return getAllAchievements({'totalScore': 0, 'completedLessons': 0, 'currentStreak': 0, 'totalWords': 0}).length;
  }
}
