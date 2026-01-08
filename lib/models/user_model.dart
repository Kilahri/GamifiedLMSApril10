// lib/models/user_model.dart
class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'role': role.toString(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    uid: json['uid'],
    email: json['email'],
    name: json['name'],
    role: UserRole.values.firstWhere((e) => e.toString() == json['role']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

enum UserRole { student, teacher, admin }
