import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Removed grade variables
  String? selectedSection;
  final List<String> sections = ["Section A", "Section B", "Section C"];

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
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _nameController.text = prefs.getString("name") ?? "";
      _usernameController.text = widget.currentUsername;
      _passwordController.text = prefs.getString("password") ?? "";
      userRole = prefs.getString("role") ?? "student";

      String? displayName = prefs.getString(
        "display_name_${widget.currentUsername}",
      );
      _displayNameController.text = displayName ?? widget.currentUsername;

      if (userRole == "student") {
        // Grade loading removed
        selectedSection = prefs.getString("section");
        _studentIdController.text = prefs.getString("studentId") ?? "";
        _parentContactController.text = prefs.getString("parentContact") ?? "";
      }

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

    // Validation updated: removed selectedGrade check
    if (userRole == "student" && selectedSection == null) {
      _showErrorDialog("Please select your Section.");
      return;
    }

    String newUsername = _usernameController.text.trim();
    bool usernameChanged = newUsername != widget.currentUsername;

    final prefs = await SharedPreferences.getInstance();

    if (usernameChanged) {
      await prefs.remove("display_name_${widget.currentUsername}");
      await prefs.setString(
        "display_name_$newUsername",
        _displayNameController.text.trim(),
      );
    } else {
      await prefs.setString(
        "display_name_${widget.currentUsername}",
        _displayNameController.text.trim(),
      );
    }

    await prefs.setString("name", _nameController.text.trim());
    await prefs.setString("username", newUsername);
    await prefs.setString("password", _passwordController.text);
    await prefs.setString("role", userRole);

    if (userRole == "student") {
      // Grade saving removed
      await prefs.setString("section", selectedSection!);
      await prefs.setString("studentId", _studentIdController.text.trim());
      await prefs.setString(
        "parentContact",
        _parentContactController.text.trim(),
      );
    }

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

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
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
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: kCardColor,
          style: const TextStyle(color: Colors.white, fontSize: kLargeFontSize),
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: kAccentColor),
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

            if (userRole == "student") ...[
              _buildSectionHeader("Academic Information", Icons.school),

              // Grade Dropdown removed from here
              _buildDropdown(
                label: "Section",
                icon: Icons.group,
                value: selectedSection,
                items: sections,
                onChanged: (v) => setState(() => selectedSection = v),
                required: true,
              ),
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
