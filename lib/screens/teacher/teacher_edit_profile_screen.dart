import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _usernameController.text = widget.currentUsername;
      _passwordController.text = prefs.getString("password") ?? "";

      // Load teacher-specific full name
      _nameController.text =
          prefs.getString("teacher_name_${widget.currentUsername}") ??
          prefs.getString("name") ??
          "";

      // Load additional teacher info
      _emailController.text =
          prefs.getString("teacher_email_${widget.currentUsername}") ?? "";
      _phoneController.text =
          prefs.getString("teacher_phone_${widget.currentUsername}") ?? "";
      _departmentController.text =
          prefs.getString("teacher_department_${widget.currentUsername}") ?? "";

      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorDialog(
        "Please fill in all required fields (Name, Username, Password).",
      );
      return;
    }

    String newUsername = _usernameController.text.trim();
    bool usernameChanged = newUsername != widget.currentUsername;

    final prefs = await SharedPreferences.getInstance();

    // Save teacher-specific full name
    if (usernameChanged) {
      await prefs.remove("teacher_name_${widget.currentUsername}");
      await prefs.setString(
        "teacher_name_$newUsername",
        _nameController.text.trim(),
      );

      // Migrate additional info
      await prefs.remove("teacher_email_${widget.currentUsername}");
      await prefs.remove("teacher_phone_${widget.currentUsername}");
      await prefs.remove("teacher_department_${widget.currentUsername}");

      await prefs.setString(
        "teacher_email_$newUsername",
        _emailController.text.trim(),
      );
      await prefs.setString(
        "teacher_phone_$newUsername",
        _phoneController.text.trim(),
      );
      await prefs.setString(
        "teacher_department_$newUsername",
        _departmentController.text.trim(),
      );
    } else {
      await prefs.setString(
        "teacher_name_${widget.currentUsername}",
        _nameController.text.trim(),
      );
      await prefs.setString(
        "teacher_email_${widget.currentUsername}",
        _emailController.text.trim(),
      );
      await prefs.setString(
        "teacher_phone_${widget.currentUsername}",
        _phoneController.text.trim(),
      );
      await prefs.setString(
        "teacher_department_${widget.currentUsername}",
        _departmentController.text.trim(),
      );
    }

    // Save common data
    await prefs.setString("name", _nameController.text.trim());
    await prefs.setString("username", newUsername);
    await prefs.setString("password", _passwordController.text);
    await prefs.setString("role", "teacher");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Profile updated successfully!"),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, usernameChanged ? newUsername : null);
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
                "Teacher Account",
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
              controller: _emailController,
              label: "Email Address",
              icon: Icons.email,
              hint: "teacher@example.com",
              type: TextInputType.emailAddress,
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _phoneController,
              label: "Phone Number",
              icon: Icons.phone,
              hint: "Optional",
              type: TextInputType.phone,
            ),
            const SizedBox(height: kSpacing),

            _buildTextField(
              controller: _departmentController,
              label: "Department/Subject",
              icon: Icons.subject,
              hint: "e.g., Science, Mathematics",
            ),

            _buildSectionHeader("Account Credentials", Icons.vpn_key),

            _buildTextField(
              controller: _usernameController,
              label: "Username",
              icon: Icons.account_circle,
              hint: "Choose a unique username",
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
                      "Changing username will update your login credentials",
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
              label: "Password",
              icon: Icons.lock,
              hint: "Enter your password",
              obscure: _obscurePassword,
              required: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: kAccentColor,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),

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
