import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:elearningapp_flutter/screens/login_screen.dart';
import 'package:elearningapp_flutter/screens/role_navigation.dart';
import 'package:elearningapp_flutter/admin/admin_panel_screen.dart';
import 'package:elearningapp_flutter/screens/splash_screen.dart';
import 'package:elearningapp_flutter/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // AudioService.initLifecycleObserver();
  runApp(const SciLearnApp());
}

class SciLearnApp extends StatelessWidget {
  const SciLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SciLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D102C),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF0D102C),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF7B4DFF)),
                ),
              );
            }

            if (!profileSnapshot.hasData ||
                !profileSnapshot.data!.exists ||
                profileSnapshot.data!.get('isActive') == false) {
              return const LoginScreen();
            }

            final data = profileSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] as String? ?? 'student';
            final username = data['username'] as String? ?? '';

            if (role == 'admin') return const AdminPanelScreen();

            return RoleNavigation(role: role, username: username);
          },
        );
      },
    );
  }
}
