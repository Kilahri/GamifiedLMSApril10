import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/login_screen.dart';

// ── Design tokens (mirrors LoginScreen) ──────────────────────────────────────
const Color _kBg = Color(0xFF080B1E);
const Color _kCard = Color(0xFF181C3A);
const Color _kAccent = Color(0xFF7B4DFF);
const Color _kAccentGlow = Color(0xFF9D77FF);
const Color _kGold = Color(0xFFFFBF3C);
const Color _kBorder = Color(0xFF2A2D52);
const Color _kMuted = Color(0xFF6B6D8A);
const Color _kInputFill = Color(0xFF0E1128);
const Color _kTeal = Color(0xFF1DB8A0);
const Color _kCoral = Color(0xFFFF6B6B);

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({super.key});
  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedSection;
  final List<String> _sections = ['Section A', 'Section B', 'Section C'];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    _studentIdController.dispose();
    _parentContactController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? _kCoral : _kTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Signup logic ──────────────────────────────────────────────────────────
  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _selectedSection == null ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Please complete all required fields.');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnack('Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final credential = await FirebaseService.signUp(
        username: username,
        password: password,
      );
      final uid = credential.user!.uid;

      try {
        final existing = await FirebaseService.findUserByUsername(username);
        if (existing != null && existing['uid'] != uid) {
          await FirebaseService.currentUser?.delete();
          await FirebaseService.signOut();
          if (!mounted) return;
          _showSnack('Username already taken. Please choose another.');
          setState(() => _isLoading = false);
          return;
        }
      } catch (_) {}

      await FirebaseService.createUserProfile(
        uid: uid,
        data: {
          'username': username,
          'displayName': _nameController.text.trim(),
          'role': 'student',
          'section': _selectedSection,
          'studentId': _studentIdController.text.trim(),
          'parentContact': _parentContactController.text.trim(),
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'source': 'signup',
        },
      );

      await FirebaseService.signOut();
      if (!mounted) return;

      _showSnack('Account created! Please log in.', error: false);
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Sign up failed. Please try again.';
      if (e.code == 'weak-password')
        msg = 'Password too weak. Use at least 6 characters.';
      else if (e.code == 'email-already-in-use')
        msg = 'Username already taken.';
      else if (e.code == 'network-request-failed')
        msg = 'No internet connection.';
      _showSnack(msg);
    } catch (e) {
      debugPrint('Signup error: $e');
      _showSnack('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Decorative orbs ───────────────────────────────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _Orb(size: 260, color: _kAccent.withOpacity(0.18)),
          ),
          Positioned(
            top: 200,
            left: -80,
            child: _Orb(
              size: 200,
              color: const Color(0xFF3B2A8A).withOpacity(0.22),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: _Orb(size: 180, color: _kGold.withOpacity(0.08)),
          ),

          // ── Main scroll ───────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    _buildBrandHeader(),
                    const SizedBox(height: 28),
                    _buildFormCard(),
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Brand header (compact version) ───────────────────────────────────────
  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5B4DCC).withOpacity(0.45),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'lib/assets/SciLearnLogo.jpg', // ← your owl logo
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E1A4A),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: Color(0xFF7B6EF6),
                      size: 36,
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFFFFBF3C), Color(0xFFFF9500)],
              ).createShader(bounds),
          child: const Text(
            'SciLearn',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Create your student account',
          style: TextStyle(
            color: _kMuted,
            fontSize: 13,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Form card ─────────────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card heading ──────────────────────────────────────────────
          const Text(
            'Join SciLearn 🚀',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fill in your details to start learning',
            style: TextStyle(color: _kMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),

          // ── Section divider: Profile ──────────────────────────────────
          _sectionDivider(
            'Profile Info',
            Icons.person_outline_rounded,
            _kAccentGlow,
          ),
          const SizedBox(height: 16),

          _fieldLabel('Full Name *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nameController,
            hint: 'Enter your full name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),

          _fieldLabel('Section *'),
          const SizedBox(height: 6),
          _buildDropdown(),
          const SizedBox(height: 16),

          _fieldLabel('Student ID  (optional)'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _studentIdController,
            hint: 'e.g. 20240001',
            icon: Icons.badge_outlined,
            type: TextInputType.number,
            formatter: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          _fieldLabel('Parent / Guardian Contact  (optional)'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _parentContactController,
            hint: 'e.g. +63 912 345 6789',
            icon: Icons.phone_outlined,
            type: TextInputType.phone,
          ),

          const SizedBox(height: 26),

          // ── Section divider: Account ──────────────────────────────────
          _sectionDivider(
            'Account Credentials',
            Icons.lock_outline_rounded,
            _kTeal,
          ),
          const SizedBox(height: 16),

          _fieldLabel('Username *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _usernameController,
            hint: 'Choose a username',
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 16),

          _fieldLabel('Password *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hint: 'At least 6 characters',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _kMuted,
                size: 20,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 16),

          _fieldLabel('Confirm Password *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _kMuted,
                size: 20,
              ),
              onPressed:
                  () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
            ),
            // Tint border red when fields don't match (and both non-empty)
            hasError:
                _confirmPasswordController.text.isNotEmpty &&
                _confirmPasswordController.text != _passwordController.text,
          ),

          const SizedBox(height: 30),

          // ── Submit button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                disabledBackgroundColor: _kAccent.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Already have an account?  ',
              style: TextStyle(color: _kMuted, fontSize: 14),
            ),
            GestureDetector(
              onTap:
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
              child: const Text(
                'Log In',
                style: TextStyle(
                  color: _kAccentGlow,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: _kBorder, thickness: 1)),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorder, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF4CAF50),
                    size: 13,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Safe for Students',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: Divider(color: _kBorder, thickness: 1)),
          ],
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Thin row that labels a group of fields inside the card
  Widget _sectionDivider(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: _kBorder, thickness: 1)),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD0D2E8),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatter,
    Widget? suffixIcon,
    bool hasError = false,
  }) {
    final borderColor = hasError ? _kCoral : _kBorder;
    final focusColor = hasError ? _kCoral : _kAccent;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: type,
      inputFormatters: formatter,
      onChanged: (_) => setState(() {}), // live rebuild for mismatch tint
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
        filled: true,
        fillColor: hasError ? _kCoral.withOpacity(0.05) : _kInputFill,
        prefixIcon: Icon(
          icon,
          color: hasError ? _kCoral : _kAccentGlow,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: focusColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSection,
      dropdownColor: const Color(0xFF1A1E3A),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _kAccentGlow,
        size: 20,
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      onChanged: (v) => setState(() => _selectedSection = v),
      items:
          _sections
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(color: Colors.white)),
                ),
              )
              .toList(),
      decoration: InputDecoration(
        hintText: 'Select your section',
        hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
        filled: true,
        fillColor: _kInputFill,
        prefixIcon: const Icon(
          Icons.group_outlined,
          color: _kAccentGlow,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}

// ── Background orb ────────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
