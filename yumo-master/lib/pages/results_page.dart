import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yumo/themes/colors.dart';

class ResultsPage extends StatelessWidget {
  final int score;
  final int total;

  const ResultsPage({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final double percentage = (score / total) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                percentage >= 80
                    ? Icons.emoji_events
                    : percentage >= 50
                    ? Icons.thumb_up
                    : Icons.refresh,
                size: 80,
                color: secondarycolor,
              ),
              const SizedBox(height: 20),
              Text(
                'Your Score',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textcolor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$score / $total',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: secondarycolor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                percentage >= 80
                    ? "Excellent work!"
                    : percentage >= 50
                    ? "Great effort!"
                    : "Keep practicing!",
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.white70),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondarycolor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 32,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

