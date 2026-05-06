import 'package:flutter/material.dart';

// ==================== Models ====================

class AppMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime time; // تم استخدام time ليتوافق مع شاشاتك
  final String? senderName;
  final String? senderAvatar;
  final String? replyToId;
  final String? replyToSender; 
  final String? replyToContent;
  final bool isRead; // حل خطأ الـ getter المفقود

  AppMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.time,
    this.senderName,
    this.senderAvatar,
    this.replyToId,
    this.replyToSender,
    this.replyToContent,
    this.isRead = false,
  });

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    return AppMessage(
      id: map['id']?.toString() ?? '',
      senderId: (map['sender_id'] ?? map['user_id'])?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      time: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      senderName: map['user_name']?.toString() ?? 'مستخدم',
      senderAvatar: map['avatar_url']?.toString(),
      replyToId: map['reply_to_id']?.toString(),
      replyToSender: map['reply_to_sender_name']?.toString(),
      replyToContent: map['reply_to_content']?.toString(),
      isRead: map['is_read'] ?? false,
    );
  }
}

class AppUser {
  final String id;
  final String fullName;
  final String email; 
  final String avatarUrl;
  final bool isOnline;
  final String? bio;
  final String role; 
  final bool isBanned;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.isOnline = false,
    this.bio,
    this.role = 'user',
    this.isBanned = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'مستخدم جديد',
      email: map['email']?.toString() ?? '', 
      avatarUrl: map['avatar_url']?.toString() ?? '',
      isOnline: map['is_online'] ?? false,
      bio: map['bio']?.toString() ?? '',
      role: map['role']?.toString() ?? 'user',
      isBanned: map['is_banned'] ?? false,
    );
  }
}

class AppRoom {
  final String id;
  final String name;
  final String? description;
  final int memberCount;

  AppRoom({required this.id, required this.name, this.description, this.memberCount = 0});

  // حل خطأ المسمى في شاشة الغرف
  String get membersLabel => "$memberCount عضو";

  factory AppRoom.fromMap(Map<String, dynamic> map) {
    return AppRoom(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'غرفة',
      description: map['description']?.toString(),
      memberCount: map['member_count'] ?? 0,
    );
  }
}
