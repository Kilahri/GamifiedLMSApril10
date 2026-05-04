import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/login_screen.dart';
import 'package:elearningapp_flutter/main.dart';
// Uncomment when you have these screens:
// import 'package:elearningapp_flutter/screens/teacher_home_screen.dart';
// import 'package:elearningapp_flutter/screens/student_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pencilBounce;

  @override
  void initState() {
    super.initState();

    // Looping animation for the pencil bounce
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pencilBounce = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 3), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    _goTo(const AuthGate()); // ← just go to AuthGate, let it handle routing
  }

  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF2D2B55),
      body: Stack(
        children: [
          // ── Full-screen splash image ──
          Positioned.fill(
            child: Image.asset(
              'lib/assets/SplashScreen.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ── Pencil + loading bar, placed just above the "SciLearn" text ──
          Positioned(
            top: screenHeight * 0.47,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  children: [
                    // Bouncing pencil icon
                    Transform.translate(
                      offset: Offset(0, _pencilBounce.value),
                      child: const Icon(
                        Icons.edit,
                        color: Color(0xFFE87B3A),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Thin orange loading bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 90),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          color: const Color(0xFFE87B3A),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
