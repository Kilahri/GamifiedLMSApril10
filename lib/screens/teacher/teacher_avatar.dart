import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherAvatarSelectionScreen extends StatefulWidget {
  final String currentUsername;
  final String currentAvatar;

  const TeacherAvatarSelectionScreen({
    super.key,
    required this.currentUsername,
    required this.currentAvatar,
  });

  @override
  State<TeacherAvatarSelectionScreen> createState() =>
      _TeacherAvatarSelectionScreenState();
}

class _TeacherAvatarSelectionScreenState
    extends State<TeacherAvatarSelectionScreen> {
  late String _selectedAvatar;

  final Color _primaryAccentColor = const Color(0xFF415A77);
  final Color _sectionTitleColor = const Color(0xFF98C1D9);

  // List of 4 teacher avatars
  final List<String> _teacherAvatars = [
    "lib/assets/avatars/teacher1.jpg", // Professional teacher avatar 1
    "lib/assets/avatars/teacher2.jpg", // Professional teacher avatar 2
    "lib/assets/avatars/teacher3.jpg", // Professional teacher avatar 3
    "lib/assets/avatars/teacher4.jpg", // Professional teacher avatar 4
  ];

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.currentAvatar;
  }

  Future<void> _saveAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("avatar_${widget.currentUsername}", _selectedAvatar);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, _selectedAvatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        elevation: 0,
        title: const Text(
          "Choose Teacher Avatar",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Preview Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "Preview",
                  style: TextStyle(
                    color: _sectionTitleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_primaryAccentColor, _sectionTitleColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryAccentColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _selectedAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.school,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _sectionTitleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "TEACHER",
                    style: TextStyle(
                      color: _sectionTitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar Grid - 2x2 for 4 avatars
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: _teacherAvatars.length,
                  itemBuilder: (context, index) {
                    final avatar = _teacherAvatars[index];
                    final isSelected = avatar == _selectedAvatar;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = avatar;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected
                                    ? _sectionTitleColor
                                    : Colors.transparent,
                            width: 4,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              _primaryAccentColor.withOpacity(0.3),
                              _sectionTitleColor.withOpacity(0.3),
                            ],
                          ),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: _sectionTitleColor.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                  : [],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.school,
                                size: 50,
                                color: Colors.white.withOpacity(0.5),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAvatar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Avatar",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
