import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String currentUsername;
  final String currentAvatar;

  const AvatarSelectionScreen({
    super.key,
    required this.currentUsername,
    required this.currentAvatar,
  });

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  late String _selectedAvatar;

  final Color _primaryAccentColor = const Color(0xFF415A77);
  final Color _sectionTitleColor = const Color(0xFF98C1D9);

  // List of 10 avatars
  final List<String> _avatars = [
    "lib/assets/avatars/b1.jpg", // Owl with glasses
    "lib/assets/avatars/b2.jpg", // Owl with graduation cap
    "lib/assets/avatars/b3.jpg", // Owl reading book
    "lib/assets/avatars/b4.jpg", // Owl with laptop
    "lib/assets/avatars/b5.jpg", // Owl with pencil
    "lib/assets/avatars/g1.jpg", // Owl with stars
    "lib/assets/avatars/g2.jpg", // Owl with coffee
    "lib/assets/avatars/g3.jpg", // Owl with headphones
    "lib/assets/avatars/g4.jpg", // Owl with telescope
    "lib/assets/avatars/g5.jpg", // Owl with medal
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
          "Choose Avatar",
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
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _avatars.length,
              itemBuilder: (context, index) {
                final avatar = _avatars[index];
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
                                  color: _sectionTitleColor.withOpacity(0.5),
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
                            Icons.person,
                            size: 40,
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
