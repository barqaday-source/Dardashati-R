import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;
  final String? themePreference;

  AppUser({
    required this.id,
    required this.fullName,
    this.email,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
    this.themePreference,
  });

  // تحويل البيانات من قاعدة البيانات (Map) إلى كائن AppUser
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? 'مستخدم',
      email: map['email'],
      avatarUrl: map['avatar_url'],
      bio: map['bio'],
      isOnline: map['is_online'] ?? false,
      themePreference: map['theme_preference'],
    );
  }

  // تحويل بيانات مستخدم Supabase الخام إلى AppUser
  factory AppUser.fromSupabase(User user) {
    return AppUser(
      id: user.id,
      fullName: user.userMetadata?['full_name'] ?? 'مستخدم جديد',
      email: user.email,
    );
  }
}

class AppMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;

  AppMessage({required this.id, required this.senderId, required this.content, required this.createdAt});

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    return AppMessage(
      id: map['id'].toString(),
      senderId: map['sender_id'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

