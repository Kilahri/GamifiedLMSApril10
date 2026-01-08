import 'package:flutter/material.dart';
import 'package:elearningapp_flutter/game/biologyForest.dart';
import 'package:elearningapp_flutter/game/skyRealm.dart';
import 'package:elearningapp_flutter/game/adventureGame.dart';

class AdventureScreen extends StatelessWidget {
  final String role;
  const AdventureScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B4DFF),
        title: const Text(
          "Adventure Game",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Choose Your Adventure, $role!",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Selection list
            Expanded(
              child: ListView(
                children: [
                  _AdventureTile(
                    title: "🌱 Biology Forest",
                    subtitle: "Restore the photosynthesis cycle",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BiologyForestLevel(),
                        ),
                      );
                    },
                  ),

                  _AdventureTile(
                    title: "🌿 Biome Builder",
                    subtitle: "Restore life across diverse biomes",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => PhotosynthesisFactory(
                                role: role,
                              ), // Pass the role!
                        ),
                      );
                    },
                  ),

                  _AdventureTile(
                    title: "🔭 Astronomy Sky Realm",
                    subtitle: "Map constellations and dodge meteors",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => AstronomySkyRealm(role: role), // ✅ Fixed!
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF0D102C), // dark theme background
    );
  }
}

class _AdventureTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdventureTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF1C1F3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
