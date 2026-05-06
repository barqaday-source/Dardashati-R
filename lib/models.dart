import 'package:supabase_flutter/supabase_flutter.dart';

// موديل المستخدم
class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String avatarUrl;
  final String role;
  final bool isBanned;
  final bool isOnline;
  final String? bio;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl = '',
    this.role = 'user',
    this.isBanned = false,
    this.isOnline = false,
    this.bio,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? 'مستخدم دردشاتي',
      email: map['email'] ?? '',
      avatarUrl: map['avatar_url'] ?? '',
      role: map['role'] ?? 'user',
      isBanned: map['is_banned'] ?? false,
      isOnline: map['is_online'] ?? false,
      bio: map['bio'],
    );
  }
}

// موديل الرسالة (هذا هو مفتاح حل الـ 12 خطأ)
class AppMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
  final String? replyToId;

  AppMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
    this.replyToId,
  });

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    return AppMessage(
      id: map['id']?.toString() ?? '',
      senderId: map['sender_id'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: map['is_read'] ?? false,
      replyToId: map['reply_to_id'],
    );
  }
}

// موديل الغرفة
class AppRoom {
  final String id;
  final String name;
  final String? description;
  final String? icon;

  AppRoom({required this.id, required this.name, this.description, this.icon});

  factory AppRoom.fromMap(Map<String, dynamic> map) {
    return AppRoom(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      icon: map['icon'],
    );
  }
}
