import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:yumo/themes/colors.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String? currentPlayingStory;

  // Mock data for stories - in a real app, this would come from your database
  final List<Map<String, dynamic>> stories = [
    {
      'id': '1',
      'title': 'The Wise Tortoise',
      'subtitle': 'A traditional Yemba folktale',
      'description':
          'Learn about wisdom and patience through this beautiful story of a tortoise who outwitted the fastest animals in the forest.',
      'duration': '5 min',
      'difficulty': 'Beginner',
      'language': 'Yemba',
      'image': 'lib/images/african-mask.png',
      'audio_url': 'story_1.mp3',
      'content':
          'Once upon a time, in the heart of the African forest, there lived a wise old tortoise...',
      'moral':
          'Slow and steady wins the race. Wisdom is more valuable than speed.',
      'vocabulary': ['Tortoise - Kɔ̀p', 'Forest - Fòm', 'Wisdom - Njìŋ'],
    },
    {
      'id': '2',
      'title': 'The Dancing Drum',
      'subtitle': 'A story of music and community',
      'description':
          'Discover how music brings people together in this tale of a magical drum that could make anyone dance.',
      'duration': '7 min',
      'difficulty': 'Intermediate',
      'language': 'Yemba',
      'image': 'lib/images/zulu-mask.png',
      'audio_url': 'story_2.mp3',
      'content':
          'In a village where music was forbidden, a young girl found a magical drum...',
      'moral': 'Music and joy are essential parts of life and community.',
      'vocabulary': ['Drum - Ngòm', 'Dance - Sɛ̀', 'Music - Njɛ̀m'],
    },
    {
      'id': '3',
      'title': 'The Generous Spider',
      'subtitle': 'A tale of sharing and kindness',
      'description':
          'Follow Anansi the spider as he learns the importance of sharing with his community.',
      'duration': '6 min',
      'difficulty': 'Beginner',
      'language': 'Yemba',
      'image': 'lib/images/warrior-dance.png',
      'audio_url': 'story_3.mp3',
      'content':
          'Anansi was known throughout the land for his cleverness, but not for his generosity...',
      'moral': 'Sharing brings more joy than keeping everything to yourself.',
      'vocabulary': ['Spider - Lɛ̀bɛ̀', 'Share - Kɛ̀', 'Kind - Mbɔ̀m'],
    },
  ];

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playStory(String storyId, String audioUrl) async {
    try {
      if (currentPlayingStory == storyId && isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          isPlaying = false;
        });
      } else {
        // In a real app, you would get the audio from Supabase storage
        // final fullUrl = Supabase.instance.client.storage
        //     .from('stories')
        //     .getPublicUrl(audioUrl);
        // await _audioPlayer.play(UrlSource(fullUrl));

        // For now, we'll just simulate playing
        setState(() {
          currentPlayingStory = storyId;
          isPlaying = true;
        });

        // Simulate audio ending after some time
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              isPlaying = false;
              currentPlayingStory = null;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundcolor,
      appBar: AppBar(
        backgroundColor: backgroundcolor,
        elevation: 0,
        iconTheme: IconThemeData(color: textcolor),
        title: Text(
          'Cultural Stories',
          style: GoogleFonts.poppins(
            color: primarycolor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textcolor),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    secondarycolor,
                    secondarycolor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: secondarycolor.withValues(alpha: 0.3),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover African Tales',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Learn language through traditional stories',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip('${stories.length} Stories', Icons.book),
                      const SizedBox(width: 12),
                      _buildInfoChip('Audio Narration', Icons.headphones),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stories List
            Text(
              'Featured Stories',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textcolor,
              ),
            ),

            const SizedBox(height: 16),

            ...stories.map((story) => _buildStoryCard(story)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final isCurrentlyPlaying = currentPlayingStory == story['id'] && isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Story Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Story Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: primarycolor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    color: primarycolor,
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                // Story Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textcolor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story['subtitle'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textcolor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStoryTag(story['duration'], Icons.access_time),
                          const SizedBox(width: 8),
                          _buildStoryTag(
                            story['difficulty'],
                            Icons.signal_cellular_alt,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Play Button
                GestureDetector(
                  onTap: () => _playStory(story['id'], story['audio_url']),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCurrentlyPlaying ? Colors.red : primarycolor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isCurrentlyPlaying
                                  ? Colors.red
                                  : primarycolor)
                              .withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Story Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              story['description'],
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: textcolor.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStoryDetails(story),
                    icon: Icon(Icons.visibility, size: 18),
                    label: Text(
                      'Read Story',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primarycolor,
                      side: BorderSide(color: primarycolor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showVocabulary(story),
                    icon: Icon(Icons.translate, size: 18),
                    label: Text(
                      'Vocabulary',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondarycolor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryTag(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: secondarycolor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: secondarycolor, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: secondarycolor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showStoryDetails(Map<String, dynamic> story) {
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story['title'],
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textcolor,
                              ),
                            ),
                            Text(
                              story['subtitle'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: textcolor.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textcolor),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Story',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textcolor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          story['content'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textcolor.withValues(alpha: 0.8),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Moral of the Story',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textcolor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primarycolor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            story['moral'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: primarycolor,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showVocabulary(Map<String, dynamic> story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
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
                      Icon(Icons.translate, color: primarycolor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Story Vocabulary',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
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

                // Vocabulary List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: story['vocabulary'].length,
                    itemBuilder: (context, index) {
                      final vocab = story['vocabulary'][index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundcolor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: secondarycolor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: secondarycolor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.volume_up,
                                color: secondarycolor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                vocab,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textcolor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
}
