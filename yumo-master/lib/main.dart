import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumo/pages/auth_page.dart';
import 'package:yumo/pages/profile_page.dart';
import 'package:yumo/pages/intro_page.dart';
import 'package:yumo/pages/home_page.dart';
import 'package:yumo/pages/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Replace these with your actual Supabase project credentials
  await Supabase.initialize(
    url: 'https://ugonqknqghgohtawdbfy.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVnb25xa25xZ2hnb2h0YXdkYmZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTExMzExODAsImV4cCI6MjA2NjcwNzE4MH0.e0LEVybNUAtrE096Pzh-oImZ23GbZJ1Q-mN2zx-81Vk', 
  );

  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yumo',
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const SplashScreen(), // Splash then AuthGate
      routes: {
        '/home': (context) => const HomePage(),
        '/intropage': (context) => const IntroPage(),
        '/profile': (context) => const ProfilePage(),
        '/auth': (context) => const AuthPage(),
      },
    );
  }
}

