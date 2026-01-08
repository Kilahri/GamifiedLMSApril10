import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'analytics_screen.dart';
import 'package:elearningapp_flutter/settings/edit_profile_screen.dart';
import 'package:elearningapp_flutter/settings/saved_notes_screen.dart';
import 'package:elearningapp_flutter/settings/avatar.dart';
import 'package:elearningapp_flutter/settings/contact_support_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentUsername;

  const SettingsScreen({super.key, required this.currentUsername});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationEnabled = true;
  String _displayName = "";
  String _currentUsername = "";
  String _selectedAvatar = "assets/avatars/avatar_1.png"; // Default avatar

  final Color _primaryAccentColor = const Color(0xFF415A77);
  final Color _sectionTitleColor = const Color(0xFF98C1D9);
  final Color _logoutColor = const Color(0xFFE63946);

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.currentUsername;
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName =
          prefs.getString("display_name_$_currentUsername") ?? _currentUsername;
      _selectedAvatar =
          prefs.getString("avatar_$_currentUsername") ??
          "assets/avatars/avatar_1.png";
    });
  }

  void _showFunctionalityDialog(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature functionality will be implemented soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _sectionTitleColor,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1B263B),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: _primaryAccentColor, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                )
                : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white54,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Card(
      color: const Color(0xFF1B263B),
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        tileColor: Colors.transparent,
        secondary: Icon(icon, color: _primaryAccentColor, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle:
            subtitle != null
                ? Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                )
                : null,
        value: value,
        onChanged: onChanged,
        activeColor: _primaryAccentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Profile Card with Avatar
          Card(
            color: const Color(0xFF1B263B),
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AvatarSelectionScreen(
                                currentUsername: _currentUsername,
                                currentAvatar: _selectedAvatar,
                              ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _selectedAvatar = result;
                        });
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [_primaryAccentColor, _sectionTitleColor],
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          _selectedAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName.isNotEmpty ? _displayName : "User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "@$_currentUsername",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.verified_user,
                    color: _sectionTitleColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Student Tools Section
          _buildSectionTitle("Student Tools & Data"),
          _buildSettingsTile(
            icon: Icons.bar_chart,
            title: "View Progress & Badges",
            subtitle: "See your mastery levels and unlocked achievements",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => IntegratedAnalyticsScreen(
                        username: _currentUsername, // ✅ Add username parameter
                      ),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.bookmark_border,
            title: 'Saved Items & Notes',
            subtitle: 'Review your saved lessons and notes',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SavedNotesScreen(),
                ),
              );
            },
          ),

          // Account Section
          _buildSectionTitle("Account"),
          _buildSettingsTile(
            icon: Icons.person,
            title: "Edit Profile",
            subtitle: "Update your name, username, password, and other details",
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          EditProfileScreen(currentUsername: _currentUsername),
                ),
              );
              if (result != null && result is String) {
                setState(() {
                  _currentUsername = result;
                });
                _loadUserInfo();
              } else {
                _loadUserInfo();
              }
            },
          ),
          _buildSettingsTile(
            icon: Icons.photo_camera,
            title: "Change Avatar",
            subtitle: "Select a new profile picture",
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AvatarSelectionScreen(
                        currentUsername: _currentUsername,
                        currentAvatar: _selectedAvatar,
                      ),
                ),
              );
              if (result != null) {
                setState(() {
                  _selectedAvatar = result;
                });
              }
            },
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: "Change Password",
            subtitle: "Update your account password",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          EditProfileScreen(currentUsername: _currentUsername),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Display & Preferences Section
          _buildSectionTitle("Display & Preferences"),
          _buildSettingsSwitchTile(
            icon: Icons.notifications,
            title: "Notifications",
            subtitle: "Receive alerts for new lessons and quizzes",
            value: _isNotificationEnabled,
            onChanged: (bool newValue) {
              setState(() {
                _isNotificationEnabled = newValue;
              });
              _showFunctionalityDialog("Notifications");
            },
          ),

          const SizedBox(height: 20),

          // Help & Support Section
          _buildSectionTitle("Help & Support"),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: "Help Center & FAQ",
            subtitle: "Find answers to common questions",
            onTap: () => _showFunctionalityDialog("Help Center"),
          ),
          _buildSettingsTile(
            icon: Icons.email_outlined,
            title: "Contact Support",
            subtitle: "Get assistance from admin or teachers",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ContactSupportScreen(
                        currentUsername: _currentUsername,
                      ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1B263B),
                      title: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Are you sure you want to logout?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _logoutColor,
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _logoutColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              "Logout",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
