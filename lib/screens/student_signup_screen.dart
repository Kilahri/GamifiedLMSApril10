import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/login_screen.dart';

const Color kPrimaryColor = Color(0xFF6A1B9A);
const Color kAccentColor = Color(0xFFFFC107);
const double kLargeFontSize = 18.0;
const double kSpacing = 22.0;

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});
  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String? selectedSection;
  final List<String> sections = ['Section A', 'Section B', 'Section C'];

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _parentContactController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        selectedSection == null ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Please complete all required fields.');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Create Firebase Auth account first
      final credential = await FirebaseService.signUp(
        username: username,
        password: password,
      );
      final uid = credential.user!.uid;

      // 2. Now authenticated — check if username already exists
      try {
        final existing = await FirebaseService.findUserByUsername(username);
        if (existing != null && existing['uid'] != uid) {
          // Username taken — delete the auth account we just created
          await FirebaseService.currentUser?.delete();
          await FirebaseService.signOut();
          if (!mounted) return;
          _showSnack('Username already taken. Please choose another.');
          setState(() => _isLoading = false);
          return;
        }
      } catch (_) {
        // If username check fails, continue — username is likely unique
      }

      // 3. Save profile to Firestore
      await FirebaseService.createUserProfile(
        uid: uid,
        data: {
          'username': username,
          'displayName': _nameController.text.trim(),
          'role': 'student',
          'section': selectedSection,
          'studentId': _studentIdController.text.trim(),
          'parentContact': _parentContactController.text.trim(),
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'signup',
        },
      );

      // 4. Sign out so user must log in manually
      await FirebaseService.signOut();

      if (!mounted) return;

      // 5. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please log in.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // 6. Redirect to LoginScreen and clear the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Sign up failed. Please try again.';
      if (e.code == 'weak-password') {
        msg = 'Password too weak. Use at least 6 characters.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Username already taken. Please choose another.';
      } else if (e.code == 'network-request-failed') {
        msg = 'No internet connection. Please check your network.';
      }
      _showSnack(msg);
    } catch (e) {
      debugPrint('Signup error: $e'); // helps you see exact error in console
      _showSnack('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatter,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      inputFormatters: formatter,
      style: const TextStyle(color: kPrimaryColor, fontSize: kLargeFontSize),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kPrimaryColor),
        prefixIcon: Icon(icon, color: kAccentColor),
        filled: true,
        fillColor: kPrimaryColor.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kAccentColor),
        filled: true,
        fillColor: kPrimaryColor.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Sign Up 🧪',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Fill in your details to start learning!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: kSpacing * 1.5),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name (Required) *',
              icon: Icons.person,
            ),
            const SizedBox(height: kSpacing),

            _buildDropdown(
              label: 'Section (Required) *',
              icon: Icons.group,
              value: selectedSection,
              items: sections,
              onChanged: (v) => setState(() => selectedSection = v),
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _studentIdController,
              label: 'Student ID (Optional)',
              icon: Icons.badge,
              type: TextInputType.number,
              formatter: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _parentContactController,
              label: 'Parent/Guardian Contact (Optional)',
              icon: Icons.phone,
              type: TextInputType.phone,
            ),
            const SizedBox(height: kSpacing),

            const Divider(thickness: 1.2, color: kPrimaryColor),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _usernameController,
              label: 'Username (Required) *',
              icon: Icons.vpn_key,
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _passwordController,
              label: 'Password (Required) *',
              icon: Icons.lock,
              obscure: true,
            ),
            const SizedBox(height: kSpacing * 2),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _signup,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: kPrimaryColor,
                            strokeWidth: 2,
                          ),
                        )
                        : const Icon(Icons.check_circle),
                label: const Text(
                  'Create Account',
                  style: TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
