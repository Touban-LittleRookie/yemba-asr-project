import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumo/components/button.dart';
import 'package:yumo/themes/colors.dart';
import 'package:yumo/services/progress_service.dart';
import 'exercise_page.dart';
import 'pronunciation_practice_page.dart';
import 'stories_page.dart';

class HomePage extends StatefulWidget {
  final String language;

  const HomePage({super.key, this.language = 'Yemba'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? currentProgress;
  bool isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final progress = await ProgressService.getProgress(userId);
      setState(() {
        currentProgress = progress;
        isLoadingProgress = false;
      });
    } else {
      setState(() {
        isLoadingProgress = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget drawerIcon(String assetPath) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Image.asset(assetPath, fit: BoxFit.contain),
    );
  }

  void _continueLesson() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    if (currentProgress == null) {
      // Start new lesson
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExercisePage(language: widget.language),
        ),
      );
    } else {
      final exerciseType = currentProgress!['exercise_type'] as String;
      final language = currentProgress!['language'] as String;
      final score = currentProgress!['score'] as int? ?? 0;

      switch (exerciseType) {
        case 'vocabulary':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExercisePage(language: language),
            ),
          );
          break;
        case 'pronunciation':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PronunciationPracticePage(
                    language: language,
                    previousScore: score,
                  ),
            ),
          );
          break;
        case 'stories':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StoriesPage()),
          );
          break;
        default:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExercisePage(language: widget.language),
            ),
          );
      }
    }
  }

  void _navigateToLanguageDetail(String language) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageDetailPage(language: language),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 253, 253),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Color.fromARGB(186, 12, 12, 12),
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          "YUMO",
          style: GoogleFonts.poppins(
            fontSize: 28,
            color: Color.fromARGB(255, 207, 94, 41),
          ),
        ),
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 207, 94, 41),
              ),
              child: Image.asset('lib/images/hut.png', fit: BoxFit.contain),
            ),
            ListTile(
              leading: drawerIcon('lib/images/book.png'),
              title: const Text('books'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: drawerIcon('lib/images/foreign-language.png'),
              title: const Text('Vocabulary'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: drawerIcon('lib/images/language-learning.png'),
              title: const Text('Quizzes'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: drawerIcon('lib/images/mythology.png'),
              title: const Text('Stories'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StoriesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.mic,
                color: Color.fromARGB(255, 12, 12, 12),
              ),
              title: const Text('Pronunciation Practice'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => const PronunciationPracticePage(
                          language: 'Yemba',
                          previousScore: 0,
                        ),
                  ),
                );
              },
            ),
            ListTile(
              leading: drawerIcon('lib/images/man(1).png'),
              title: const Text(
                "Profile",
                style: TextStyle(color: Color.fromARGB(255, 12, 12, 12)),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promo banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: secondarycolor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Continue Learning",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isLoadingProgress)
                          Text(
                            "Loading progress...",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          )
                        else
                          Text(
                            ProgressService.getProgressDescription(
                              currentProgress,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (currentProgress != null)
                          Container(
                            width: 200,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor:
                                  ProgressService.getCompletionPercentage(
                                    currentProgress!['current_index'] ?? 0,
                                    currentProgress!['total_items'] ?? 1,
                                  ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: primarycolor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: MyButton(
                            text:
                                currentProgress == null
                                    ? "Start Learning"
                                    : "Continue",
                            onTap: _continueLesson,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'lib/images/warrior-dance.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search available languages...",
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Horizontal scrollable languages
            Text(
              "Available Languages",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 230,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToLanguageDetail("Tunen"),
                    child: _languageCard(
                      'Tunen',
                      'lib/images/african-mask.png',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToLanguageDetail("Yemba"),
                    child: _languageCard('Yemba', 'lib/images/zulu-mask.png'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Favorites
            Text(
              "Favorites",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: const Color.fromARGB(
                255,
                207,
                94,
                41,
              ), // orange background
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Image.asset('lib/images/african-mask.png', width: 40),
                title: Text(
                  'Tunen',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                subtitle: Text(
                  "Added to favorites",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                trailing: const Icon(Icons.favorite, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageCard(String title, String imagePath) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 100, fit: BoxFit.contain),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class LanguageDetailPage extends StatefulWidget {
  final String language;
  const LanguageDetailPage({super.key, required this.language});

  @override
  State<LanguageDetailPage> createState() => _LanguageDetailPageState();
}

class _LanguageDetailPageState extends State<LanguageDetailPage> {
  int currentLesson = 1;

  String getLanguageDescription(String lang) {
    if (lang == 'Tunen') {
      return 'Tunen is spoken in parts of Cameroon. Rich in tonal patterns and cultural expressions.';
    } else {
      return 'Yemba is a Bamileke language rich in oral tradition and ceremonial heritage.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.language, style: GoogleFonts.poppins()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                widget.language == 'Tunen'
                    ? 'lib/images/african-mask.png'
                    : 'lib/images/zulu-mask.png',
                height: 120,
              ),
            ),
            const SizedBox(height: 20),

            // Updated: White background for description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    getLanguageDescription(widget.language),
                    style: GoogleFonts.poppins(),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Lesson $currentLesson",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (currentLesson > 1) currentLesson--;
                        });
                      },
                      icon: Icon(Icons.arrow_back_ios),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (currentLesson < 5) currentLesson++;
                        });
                      },
                      icon: Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Updated: Button with app green and white text
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondarycolor, // Green
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Navigate to exercise page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ExercisePage(language: widget.language),
                    ),
                  );
                },
                child: Text(
                  "Start Lesson",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
