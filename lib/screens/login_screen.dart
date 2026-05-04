import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elearningapp_flutter/services/firebase_services.dart';
import 'package:elearningapp_flutter/screens/role_navigation.dart';
import 'package:elearningapp_flutter/screens/student_signup_screen.dart';
import 'package:elearningapp_flutter/screens/forgot_password_screen.dart';
import 'package:elearningapp_flutter/admin/admin_panel_screen.dart';
import 'package:elearningapp_flutter/helpers/student_cache.dart';
import 'package:elearningapp_flutter/screens/read_screen.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF080B1E);
const Color _kSurface = Color(0xFF111430);
const Color _kCard = Color(0xFF181C3A);
const Color _kAccent = Color(0xFF7B4DFF);
const Color _kAccentGlow = Color(0xFF9D77FF);
const Color _kGold = Color(0xFFFFBF3C);
const Color _kBorder = Color(0xFF2A2D52);
const Color _kMuted = Color(0xFF6B6D8A);
const Color _kInputFill = Color(0xFF0E1128);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Error dialog ──────────────────────────────────────────────────────────
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: _kCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Login Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB0B3CC),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    color: _kAccentGlow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Login logic ───────────────────────────────────────────────────────────
  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both username and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseService.signIn(username: username, password: password);
      final uid = FirebaseService.currentUser!.uid;

      await StudentCache.clear();
      resetReadingState();

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
          'Your account has been deactivated. Please contact the administrator.',
        );
        await FirebaseService.signOut();
        return;
      }

      final role = profile['role'] as String;
      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => RoleNavigation(role: role, username: username),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Invalid username or password.';
      if (e.code == 'user-not-found') {
        msg = 'No account found with that username.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Incorrect password.';
      } else if (e.code == 'too-many-requests') {
        msg = 'Too many failed attempts. Try again later.';
      } else if (e.code == 'network-request-failed') {
        msg = 'No internet connection. Please check your network.';
      }
      _showErrorDialog(msg);
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
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
          // ── Decorative background orbs ────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _Orb(size: 260, color: _kAccent.withOpacity(0.18)),
          ),
          Positioned(
            top: 160,
            right: -80,
            child: _Orb(
              size: 200,
              color: const Color(0xFF3B2A8A).withOpacity(0.22),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _Orb(size: 180, color: _kGold.withOpacity(0.08)),
          ),

          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    const SizedBox(height: 36),

                    // ── Brand header ──────────────────────────────────
                    _buildBrandHeader(),
                    const SizedBox(height: 32),

                    // ── Login card ────────────────────────────────────
                    _buildLoginCard(),
                    const SizedBox(height: 24),

                    // ── Footer links ──────────────────────────────────
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

  // ── Brand header ──────────────────────────────────────────────────────────
  Widget _buildBrandHeader() {
    return Column(
      children: [
        // ── Logo: SciLearn owl image clipped to circle ────────────────
        Container(
          width: 90,
          height: 90,
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
              'lib/assets/SciLearnLogo.jpg',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E1A4A),
                    ),
                    child: const Icon(
                      Icons.science_rounded,
                      color: Color(0xFF7B6EF6),
                      size: 42,
                    ),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // App name with gold glow effect
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFFFFBF3C), Color(0xFFFF9500)],
              ).createShader(bounds),
          child: const Text(
            'SciLearn',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Science Learning Platform for Don Francisco Dinglasan Memorial School ',
          style: TextStyle(
            color: _kMuted,
            fontSize: 13,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 22),

        // Subject pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            _SubjectPill(emoji: '🌱', label: 'Biology'),
            _SubjectPill(emoji: '🪐', label: 'Space'),
            _SubjectPill(emoji: '⚗️', label: 'Chemistry'),
            _SubjectPill(emoji: '💧', label: 'Earth Sci'),
          ],
        ),
      ],
    );
  }

  // ── Login card ────────────────────────────────────────────────────────────
  Widget _buildLoginCard() {
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
          // Card heading
          const Text(
            'Welcome back 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Log in to continue your learning adventure',
            style: TextStyle(color: _kMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 28),

          // Username field
          _fieldLabel('Username'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _usernameController,
            hint: 'Enter your username',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 18),

          // Password field
          _fieldLabel('Password'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hint: 'Enter your password',
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
          const SizedBox(height: 10),

          // Forgot password — right aligned
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  ),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: _kAccentGlow,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
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
                            'Log In',
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
              "Don't have an account?  ",
              style: TextStyle(color: _kMuted, fontSize: 14),
            ),
            GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentSignupScreen(),
                    ),
                  ),
              child: Text(
                'Sign Up',
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

        // Decorative divider with "safe learning" badge
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

  // ── Helper builders ───────────────────────────────────────────────────────
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
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      textCapitalization:
          obscure ? TextCapitalization.none : TextCapitalization.none,
      onSubmitted: obscure ? (_) => _login() : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kMuted, fontSize: 14),
        filled: true,
        fillColor: _kInputFill,
        prefixIcon: Icon(icon, color: _kAccentGlow, size: 20),
        suffixIcon: suffixIcon,
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
          borderSide: BorderSide(color: _kAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUPPORTING WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Blurred background orb for depth
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Small subject pill badge
class _SubjectPill extends StatelessWidget {
  final String emoji;
  final String label;
  const _SubjectPill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF181C3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2D52), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9B9EC0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
