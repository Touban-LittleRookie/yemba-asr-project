import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumo/pages/home_page.dart';
import 'package:yumo/themes/colors.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  bool isLogin = true;

  Future<void> _authenticate() async {
    setState(() => isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (isLogin) {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) {
          // Successful login, navigate to HomePage
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        }
      } else {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );
        if (response.user != null) {
          // Successful registration, navigate to HomePage
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Unexpected error")));
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundcolor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // App Logo and Welcome
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primarycolor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'lib/images/african-mask (1).png',
                  width: 60,
                  height: 60,
                  color: primarycolor,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "YUMO",
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: primarycolor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Learn African Languages",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: textcolor.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 40),

              // Auth Form Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLogin ? "Welcome Back!" : "Create Account",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textcolor,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isLogin
                          ? "Sign in to continue your learning journey"
                          : "Join thousands learning African languages",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textcolor.withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email Field
                    Text(
                      "Email Address",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textcolor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        hintStyle: GoogleFonts.poppins(
                          color: textcolor.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
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
                          borderSide: BorderSide(color: primarycolor, width: 2),
                        ),
                        filled: true,
                        fillColor: backgroundcolor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    Text(
                      "Password",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textcolor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        hintStyle: GoogleFonts.poppins(
                          color: textcolor.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
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
                          borderSide: BorderSide(color: primarycolor, width: 2),
                        ),
                        filled: true,
                        fillColor: backgroundcolor,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Auth Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _authenticate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLoading ? Colors.grey : secondarycolor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  isLogin ? "Sign In" : "Create Account",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Switch Auth Mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin
                              ? "Don't have an account? "
                              : "Already have an account? ",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: textcolor.withValues(alpha: 0.7),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => isLogin = !isLogin);
                          },
                          child: Text(
                            isLogin ? "Sign Up" : "Sign In",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primarycolor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Footer
              Text(
                "By continuing, you agree to our Terms of Service\nand Privacy Policy",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: textcolor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
