import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';

const Color kPrimaryColor = Color(0xFF0D102C);
const Color kAccentColor = Color(0xFFFFC107);
const Color kButtonColor = Color(0xFF7B4DFF);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  Future<void> _requestReset() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your username.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verify user exists in Firestore
      final user = await FirebaseService.findUserByUsername(username);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No account found with that username.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Mark reset requested in Firestore (admin can see this)
      await FirebaseService.updateUserProfile(user['uid'], {
        'passwordResetRequested': true,
        'passwordResetRequestedAt': DateTime.now().toIso8601String(),
      });

      setState(() => _submitted = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('Forgot Password'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: _submitted ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_reset, size: 80, color: kAccentColor),
        const SizedBox(height: 24),
        const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Enter your username and your teacher or\n'
          'administrator will reset your password.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
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
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _requestReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: kButtonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child:
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                      'Request Reset',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.greenAccent,
        ),
        const SizedBox(height: 24),
        const Text(
          'Request Sent!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Your password reset request has been submitted.\n\n'
          'Please contact your teacher or administrator '
          'and they will reset your password for you.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Back to Login',
            style: TextStyle(color: kAccentColor, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
