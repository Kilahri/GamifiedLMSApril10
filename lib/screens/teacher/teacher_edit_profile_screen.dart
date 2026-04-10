import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';

// Theme Colors
const Color kPrimaryColor = Color(0xFF1B263B);
const Color kAccentColor = Color(0xFF415A77);
const Color kBackgroundColor = Color(0xFF0D1B2A);
const Color kCardColor = Color(0xFF1B263B);
const Color kHighlightColor = Color(0xFF98C1D9);
const double kLargeFontSize = 16.0;
const double kSpacing = 18.0;

class TeacherEditProfileScreen extends StatefulWidget {
  final String currentUsername;

  const TeacherEditProfileScreen({super.key, required this.currentUsername});

  @override
  State<TeacherEditProfileScreen> createState() =>
      _TeacherEditProfileScreenState();
}

class _TeacherEditProfileScreenState extends State<TeacherEditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  bool _isLoading = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseService.currentUser!.uid;
      final profile = await FirebaseService.getUserProfile(uid);

      if (profile == null) return;

      setState(() {
        _nameController.text = profile['displayName'] ?? '';
        _usernameController.text =
            profile['username'] ?? widget.currentUsername;
        _passwordController.text = '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _departmentController.text = profile['department'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty) {
      _showErrorDialog('Please fill in all required fields (Name, Username).');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseService.currentUser!.uid;
      final newUsername = _usernameController.text.trim();
      final newPassword = _passwordController.text.trim();
      final usernameChanged = newUsername != widget.currentUsername;

      // 1. If username changed, check it's not already taken.
      if (usernameChanged) {
        // Validate no spaces in username
        if (newUsername.contains(' ')) {
          _showErrorDialog('Username cannot contain spaces.');
          setState(() => _isLoading = false);
          return;
        }

        final existing = await FirebaseService.findUserByUsername(newUsername);
        if (existing != null && existing['uid'] != uid) {
          _showErrorDialog('Username already taken. Please choose another.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Update password if user entered a new one.
      if (newPassword.isNotEmpty) {
        if (newPassword.length < 6) {
          _showErrorDialog('Password must be at least 6 characters.');
          setState(() => _isLoading = false);
          return;
        }
        try {
          final profile = await FirebaseService.getUserProfile(
            FirebaseService.currentUser!.uid,
          );
          final storedPassword = profile?['password'] as String? ?? '';

          if (storedPassword.isNotEmpty) {
            final cred = EmailAuthProvider.credential(
              email: FirebaseService.currentUser!.email!,
              password: storedPassword,
            );
            await FirebaseService.currentUser!.reauthenticateWithCredential(
              cred,
            );
          }

          // Update Firebase Auth password
          await FirebaseService.currentUser!.updatePassword(newPassword);

          // Sync to Firestore so future logins and admin resets work
          await FirebaseService.updateUserProfile(
            FirebaseService.currentUser!.uid,
            {'password': newPassword},
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            _showErrorDialog(
              'Please log out and log back in before changing your password.',
            );
          } else {
            _showErrorDialog('Failed to update password: ${e.message}');
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // 3. Update Firestore profile with teacher-specific fields.
      final Map<String, dynamic> updates = {
        'displayName': _nameController.text.trim(),
        'username': newUsername,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _departmentController.text.trim(),
        'role': 'teacher',
      };

      await FirebaseService.updateUserProfile(uid, updates);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context, usernameChanged ? newUsername : null);
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to update profile.';
      if (e.code == 'requires-recent-login') {
        msg =
            'For security, please log out and log back in before changing your password.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak. Use at least 6 characters.';
      }
      _showErrorDialog(msg);
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: kCardColor,
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Validation Error', style: TextStyle(color: Colors.white)),
              ],
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
                  style: TextStyle(color: kHighlightColor),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    String? hint,
    bool required = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: kHighlightColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: kLargeFontSize),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: kAccentColor),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: kCardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kAccentColor.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kAccentColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kHighlightColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: kHighlightColor, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kHighlightColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: kHighlightColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [kAccentColor, kHighlightColor],
                      ),
                    ),
                    child: const Icon(
                      Icons.school,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: kHighlightColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Teacher Account',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // ── Personal Information ────────────────────────────────────────
            _buildSectionHeader('Personal Information', Icons.person_outline),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              hint: 'Enter your full name',
              required: true,
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              hint: 'teacher@example.com',
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              hint: 'Optional',
              type: TextInputType.phone,
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _departmentController,
              label: 'Department / Subject',
              icon: Icons.subject,
              hint: 'e.g., Science, Mathematics',
            ),

            // ── Account Credentials ────────────────────────────────────────
            _buildSectionHeader('Account Credentials', Icons.vpn_key),

            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.account_circle,
              hint: 'Choose a unique username',
              required: true,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.amber.shade300,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Changing username will update your login credentials',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildTextField(
              controller: _passwordController,
              label: 'New Password (optional)',
              icon: Icons.lock,
              hint: 'Leave blank to keep current password',
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: kAccentColor,
                ),
                onPressed:
                    () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Only fill this in if you want to change your password',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save, size: 22),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHighlightColor,
                  foregroundColor: kBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text('Cancel', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
