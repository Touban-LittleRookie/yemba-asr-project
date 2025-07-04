import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumo/themes/colors.dart';
import 'package:yumo/services/achievements_service.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();

  // User stats
  int totalScore = 0;
  int completedLessons = 0;
  int currentStreak = 0;
  int totalWords = 0;
  bool isLoading = true;
  List<Achievement> achievements = [];

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    final name = user?.userMetadata?['name'] ?? 'Yumo Learner';
    _nameController.text = name;
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        // Get user progress data
        final response = await supabase
            .from('user_progress')
            .select()
            .eq('user_id', userId);

        if (response.isNotEmpty) {
          int score = 0;
          int lessons = 0;
          Set<String> uniqueWords = {};

          for (var progress in response) {
            score += (progress['score'] as int? ?? 0);
            if (progress['completed'] == true) {
              lessons++;
            }
            uniqueWords.add(progress['vocabulary_id'].toString());
          }

          setState(() {
            totalScore = score;
            completedLessons = lessons;
            totalWords = uniqueWords.length;
            currentStreak = 5; // Mock data for now
            achievements = AchievementsService.getAllAchievements({
              'totalScore': score,
              'completedLessons': lessons,
              'currentStreak': 5,
              'totalWords': uniqueWords.length,
            });
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await supabase.auth.updateUser(UserAttributes(data: {'name': name}));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
      }
    }
  }

  void _changePassword() async {
    final email = supabase.auth.currentUser?.email;
    if (email != null) {
      await supabase.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent to your email.'),
          ),
        );
      }
    }
  }

  void _logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }
  }

  void _showAllAchievements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: primarycolor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All Achievements',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textcolor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textcolor),
                      ),
                    ],
                  ),
                ),

                // Achievements List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              achievement.isUnlocked
                                  ? achievement.color.withValues(alpha: 0.1)
                                  : backgroundcolor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                achievement.isUnlocked
                                    ? achievement.color.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color:
                                    achievement.isUnlocked
                                        ? achievement.color.withValues(
                                          alpha: 0.2,
                                        )
                                        : Colors.grey.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                achievement.icon,
                                color:
                                    achievement.isUnlocked
                                        ? achievement.color
                                        : Colors.grey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    achievement.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          achievement.isUnlocked
                                              ? textcolor
                                              : textcolor.withValues(
                                                alpha: 0.6,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    achievement.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color:
                                          achievement.isUnlocked
                                              ? textcolor.withValues(alpha: 0.7)
                                              : textcolor.withValues(
                                                alpha: 0.5,
                                              ),
                                    ),
                                  ),
                                  if (!achievement.isUnlocked &&
                                      achievement.currentValue > 0) ...[
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: achievement.progress,
                                      backgroundColor: Colors.grey.withValues(
                                        alpha: 0.2,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        achievement.color,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${achievement.currentValue}/${achievement.targetValue}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: textcolor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (achievement.isUnlocked)
                              Icon(
                                Icons.check_circle,
                                color: achievement.color,
                                size: 20,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? 'unknown@example.com';
    final name =
        _nameController.text.isNotEmpty ? _nameController.text : 'Yumo Learner';

    return Scaffold(
      backgroundColor: backgroundcolor,
      appBar: AppBar(
        backgroundColor: backgroundcolor,
        elevation: 0,
        iconTheme: IconThemeData(color: textcolor),
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: primarycolor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: textcolor),
            onPressed: () {
              // Settings functionality can be added here
            },
          ),
        ],
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator(color: primarycolor))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile Header
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
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: secondarycolor,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'Y',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Score',
                            totalScore.toString(),
                            Icons.star,
                            primarycolor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Lessons',
                            completedLessons.toString(),
                            Icons.book,
                            secondarycolor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Streak',
                            '$currentStreak days',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Words',
                            totalWords.toString(),
                            Icons.translate,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Edit Profile Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textcolor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              labelStyle: GoogleFonts.poppins(
                                color: textcolor.withValues(alpha: 0.7),
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: primarycolor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: textcolor.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primarycolor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: backgroundcolor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _updateName,
                              icon: const Icon(Icons.save),
                              label: Text(
                                'Save Changes',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondarycolor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Achievements Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: primarycolor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Achievements',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textcolor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: secondarycolor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: secondarycolor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: achievements.take(6).length,
                              itemBuilder: (context, index) {
                                final achievement = achievements[index];
                                return Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color:
                                              achievement.isUnlocked
                                                  ? achievement.color
                                                      .withValues(alpha: 0.2)
                                                  : Colors.grey.withValues(
                                                    alpha: 0.1,
                                                  ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          achievement.icon,
                                          color:
                                              achievement.isUnlocked
                                                  ? achievement.color
                                                  : Colors.grey,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        achievement.title,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color:
                                              achievement.isUnlocked
                                                  ? textcolor
                                                  : textcolor.withValues(
                                                    alpha: 0.5,
                                                  ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showAllAchievements(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: primarycolor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'View All Achievements',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: primarycolor,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Settings Section
                    Container(
                      width: double.infinity,
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
                          _buildSettingsTile(
                            'Reset Password',
                            'Change your account password',
                            Icons.lock_outline,
                            _changePassword,
                          ),
                          Divider(
                            color: textcolor.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          _buildSettingsTile(
                            'Notifications',
                            'Manage your notification preferences',
                            Icons.notifications,
                            () {
                              // Notifications settings
                            },
                          ),
                          Divider(
                            color: textcolor.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          _buildSettingsTile(
                            'Privacy Policy',
                            'Read our privacy policy',
                            Icons.privacy_tip,
                            () {
                              // Privacy policy
                            },
                          ),
                          Divider(
                            color: textcolor.withValues(alpha: 0.1),
                            height: 1,
                          ),
                          _buildSettingsTile(
                            'Sign Out',
                            'Sign out of your account',
                            Icons.logout,
                            _logout,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textcolor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textcolor.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDestructive ? Colors.red : primarycolor).withValues(
            alpha: 0.1,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : primarycolor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : textcolor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: textcolor.withValues(alpha: 0.6),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: textcolor.withValues(alpha: 0.3),
        size: 16,
      ),
    );
  }
}
