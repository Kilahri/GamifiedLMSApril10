import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';

// Theme Colors
const Color kPrimaryColor = Color(0xFF1B263B);
const Color kAccentColor = Color(0xFF415A77);
const Color kBackgroundColor = Color(0xFF0D1B2A);
const Color kCardColor = Color(0xFF1B263B);
const Color kHighlightColor = Color(0xFF98C1D9);
const double kLargeFontSize = 16.0;
const double kSpacing = 18.0;

class EditProfileScreen extends StatefulWidget {
  final String currentUsername;

  const EditProfileScreen({super.key, required this.currentUsername});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _parentContactController =
      TextEditingController();

  // ── FIX: section is stored but NEVER editable by students ──────────────
  // Teachers can still see all three sections in TeacherContentManagement
  // because that screen uses its own SectionSelector widget.
  String? _studentSection; // read from Firestore; shown read-only in UI

  bool _isLoading = true;
  bool _obscurePassword = true;
  String userRole = "student";

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
    _displayNameController.dispose();
    _studentIdController.dispose();
    _parentContactController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseService.currentUser!.uid;
      final profile = await FirebaseService.getUserProfile(uid);

      if (profile == null) return;

      setState(() {
        userRole = profile['role'] ?? 'student';
        _nameController.text = profile['displayName'] ?? '';
        _displayNameController.text =
            profile['displayName'] ?? widget.currentUsername;
        _usernameController.text =
            profile['username'] ?? widget.currentUsername;
        _passwordController.text = '';

        if (userRole == 'student') {
          // Store the section locally — it will be displayed read-only.
          _studentSection = profile['section'] as String?;
          _studentIdController.text = profile['studentId'] ?? '';
          _parentContactController.text = profile['parentContact'] ?? '';
        }

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

    // ── FIX: students must have a section assigned (set by admin/teacher).
    //         We do NOT validate whether they "selected" one since the field
    //         is read-only — we just check it exists.
    if (userRole == 'student' && _studentSection == null) {
      _showErrorDialog(
        'Your account has no section assigned. Please contact your teacher.',
      );
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
        final existing = await FirebaseService.findUserByUsername(newUsername);
        if (existing != null && existing['uid'] != uid) {
          _showErrorDialog('Username already taken. Please choose another.');
          setState(() => _isLoading = false);
          return;
        }

        final user = FirebaseService.currentUser!;
        await user.verifyBeforeUpdateEmail(
          '${newUsername.toLowerCase()}@scilearn.internal',
        );
      }

      // 2. Update password if user entered a new one.
      if (newPassword.isNotEmpty) {
        if (newPassword.length < 6) {
          _showErrorDialog('Password must be at least 6 characters.');
          setState(() => _isLoading = false);
          return;
        }
        await FirebaseService.currentUser!.updatePassword(newPassword);
      }

      // 3. Update Firestore profile.
      //    NOTE: 'section' is intentionally NOT included in the update map
      //    for students — it can only be changed by a teacher/admin directly
      //    in Firestore or via a dedicated admin tool.
      final Map<String, dynamic> updates = {
        'displayName': _nameController.text.trim(),
        'leaderboardName': _displayNameController.text.trim(),
        'username': newUsername,
      };

      if (userRole == 'student') {
        // Only non-sensitive academic fields that students are allowed to edit.
        updates['studentId'] = _studentIdController.text.trim();
        updates['parentContact'] = _parentContactController.text.trim();
        // ── 'section' is deliberately omitted here ──────────────────────
      }

      await FirebaseService.updateUserProfile(uid, updates);

      // 4. Update leaderboard display name.
      try {
        final xp = await FirebaseService.getTotalXP(
          uid,
        ).timeout(const Duration(seconds: 8));
        await FirebaseService.updateLeaderboard(
          uid: uid,
          displayName: _displayNameController.text.trim(),
          xp: xp,
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        // Non-critical — profile was already saved; leaderboard update can be skipped
      }

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
            'For security, please log out and log back in before changing '
            'your username or password.';
      } else if (e.code == 'weak-password') {
        msg = 'Password too weak. Use at least 6 characters.';
      }
      _showErrorDialog(msg);
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
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
                Text("Validation Error", style: TextStyle(color: Colors.white)),
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
                  "OK",
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
    List<TextInputFormatter>? formatter,
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
                " *",
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          inputFormatters: formatter,
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

  // ── FIX: New read-only section widget (replaces the editable dropdown) ──
  Widget _buildReadOnlySectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Section',
              style: TextStyle(
                color: kHighlightColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(' *', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAccentColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.group, color: kAccentColor),
              const SizedBox(width: 12),
              Text(
                _studentSection ?? 'Not assigned',
                style: TextStyle(
                  color:
                      _studentSection != null ? Colors.white : Colors.white38,
                  fontSize: kLargeFontSize,
                ),
              ),
              const Spacer(),
              // Lock icon signals clearly that this field cannot be edited
              Icon(Icons.lock_outline, color: kAccentColor, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: Colors.white38),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Your section is assigned by your teacher and cannot be changed here.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
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
            "Edit Profile",
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
          "Edit Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Icons.person,
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
                userRole == "teacher" ? "Teacher Account" : "Student Account",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            _buildSectionHeader("Personal Information", Icons.person_outline),

            _buildTextField(
              controller: _nameController,
              label: "Full Name",
              icon: Icons.person,
              hint: "Enter your full name",
              required: true,
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _displayNameController,
              label: "Leaderboard Display Name",
              icon: Icons.leaderboard,
              hint: "Name shown on leaderboard",
              required: true,
            ),
            const SizedBox(height: kSpacing),

            _buildSectionHeader("Account Credentials", Icons.vpn_key),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Username',
                      style: TextStyle(
                        color: kHighlightColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' *',
                      style: TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kAccentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_circle, color: kAccentColor),
                      const SizedBox(width: 12),
                      Text(
                        _usernameController.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: kLargeFontSize,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.lock_outline, color: kAccentColor, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 13,
                        color: Colors.white38,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Your username can only be changed by an administrator.',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _buildTextField(
              controller: _passwordController,
              label: "New Password (optional)",
              icon: Icons.lock,
              hint: "Leave blank to keep current password",
              obscure: _obscurePassword,
              required: false,
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
                  Icon(Icons.info_outline, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      "Only fill this in if you want to change your password",
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

            if (userRole == 'student') ...[
              _buildSectionHeader("Academic Information", Icons.school),

              // ── FIX: replaced editable DropdownButtonFormField with the
              //         read-only _buildReadOnlySectionField() widget.
              //         The section value is loaded from Firestore on init
              //         and is NEVER written back in _saveProfile().
              _buildReadOnlySectionField(),
              const SizedBox(height: kSpacing),

              _buildTextField(
                controller: _studentIdController,
                label: "Student ID",
                icon: Icons.badge,
                hint: "Optional",
                type: TextInputType.number,
                formatter: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: kSpacing),

              _buildTextField(
                controller: _parentContactController,
                label: "Parent/Guardian Contact",
                icon: Icons.phone,
                hint: "Optional",
                type: TextInputType.phone,
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save, size: 22),
                label: const Text(
                  "Save Changes",
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

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text("Cancel", style: TextStyle(fontSize: 16)),
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
