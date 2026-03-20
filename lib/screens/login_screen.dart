import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/role_navigation.dart';
import 'package:elearningapp_flutter/screens/student_signup_screen.dart';
import 'package:elearningapp_flutter/screens/forgot_password_screen.dart';
import 'package:elearningapp_flutter/admin/admin_panel_screen.dart';

const Color kPrimaryColor = Color(0xFF0D102C);
const Color kAccentColor = Color(0xFFFFC107);
const Color kButtonColor = Color(0xFF7B4DFF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C1F3E),
            title: const Text(
              'Login Failed',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.purpleAccent),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both username and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in via Firebase Auth
      await FirebaseService.signIn(username: username, password: password);
      final uid = FirebaseService.currentUser!.uid;

      // Fetch Firestore profile
      final profile = await FirebaseService.getUserProfile(uid);

      if (profile == null) {
        _showErrorDialog(
          'Account data not found. Please contact the administrator.',
        );
        await FirebaseService.signOut();
        return;
      }

      if (profile['isActive'] == false) {
        _showErrorDialog(
          'Your account has been deactivated. '
          'Please contact the administrator.',
        );
        await FirebaseService.signOut();
        return;
      }

      final role = profile['role'] as String;
      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoleNavigation(role: role, username: username),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Invalid username or password.';
      if (e.code == 'user-not-found')
        msg = 'No account found with that username.';
      if (e.code == 'wrong-password') msg = 'Incorrect password.';
      if (e.code == 'too-many-requests')
        msg = 'Too many failed attempts. Try again later.';
      _showErrorDialog(msg);
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SciLearn',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: kAccentColor,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.purple,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const Text(
                'Science Learning Platform',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 30),
              Image.asset('lib/assets/owl.png', height: 120),
              const SizedBox(height: 20),
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in to continue your learning adventure',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Username Field
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1C1F3E),
                  prefixIcon: const Icon(Icons.person, color: kAccentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: kButtonColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1C1F3E),
                  prefixIcon: const Icon(Icons.lock, color: kAccentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: kButtonColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kButtonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 30),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.purpleAccent, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentSignupScreen(),
                      ),
                    ),
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
