import 'package:flutter/material.dart';

// ==================== Enums ====================
enum IconStyle { minimal, bold, soft }
enum FilterType { all, online, banned, pending }

// ==================== Models ====================

// --- نموذج الرسائل ---
class AppMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime time;
  final String? senderName;
  final String? senderAvatar;
  final String? replyToId;
  final String? replyToSender; 
  final String? replyToContent; 

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
  });

  factory AppMessage.fromMap(Map<String, dynamic> map) {
    return AppMessage(
      id: map['id']?.toString() ?? '',
      senderId: map['user_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      time: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      senderName: map['user_name']?.toString(),
      senderAvatar: map['avatar_url']?.toString(),
      replyToId: map['reply_to_id']?.toString(),
      replyToSender: map['reply_to_sender_name']?.toString(),
      replyToContent: map['reply_to_content']?.toString(),
    );
  }

  String get formattedTime => "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
}

// --- نموذج المستخدم ---
class AppUser {
  final String id;
  final String fullName;
  final String email; 
  final String avatarUrl;
  final bool isOnline;
  final String? bio;
  final String role; 
  final bool isBanned;
  final String themePreference;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    this.isOnline = false,
    this.bio,
    this.role = 'user',
    this.isBanned = false,
    this.themePreference = 'dark',
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? 'مستخدم جديد',
      email: map['email']?.toString() ?? '', 
      avatarUrl: map['avatar_url']?.toString() ?? '',
      isOnline: map['is_online'] ?? false,
      bio: map['bio']?.toString(),
      role: map['role']?.toString() ?? 'user',
      isBanned: map['is_banned'] ?? false,
      themePreference: map['theme_preference']?.toString() ?? 'dark',
    );
  }

  bool get isAdmin => role == 'admin';
}

// --- نموذج غرف الدردشة (إعادة هيكلة) ---
class AppRoom {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String ownerId; // أضفنا معرف المالك
  final int memberCount;
  final bool isPrivate; // أضفنا خاصية الخصوصية
  final DateTime createdAt;

  AppRoom({
    required this.id,
    required this.name,
    required this.ownerId,
    this.description,
    this.imageUrl,
    this.memberCount = 0,
    this.isPrivate = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // نص مخصص لعدد الأعضاء
  String get membersLabel => memberCount == 1 ? "عضو واحد" : "$memberCount عضو";

  factory AppRoom.fromMap(Map<String, dynamic> map) {
    return AppRoom(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'غرفة عامة',
      ownerId: map['owner_id']?.toString() ?? '',
      description: map['description']?.toString(),
      imageUrl: map['image_url']?.toString(),
      memberCount: map['member_count'] ?? 0,
      isPrivate: map['is_private'] ?? false,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// --- نموذج الإشعارات ---
class AppNotification {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'إشعار جديد',
      body: map['body']?.toString() ?? '',
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      icon: _getIconForType(map['type']?.toString()),
    );
  }

  static IconData _getIconForType(String? type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline;
      case 'system': return Icons.info_outline;
      case 'alert': return Icons.warning_amber_rounded;
      default: return Icons.notifications_none;
    }
  }
}

// --- نموذج البلاغات (تم الإضافة والتنظيم) ---
class AppReport {
  final String id;
  final String reporterId;    // الشخص الذي أبلغ
  final String reportedId;    // الشخص المُبلغ عنه
  final String reason;        // سبب البلاغ
  final String? status;       // حالة البلاغ (pending, resolved)
  final DateTime createdAt;

  AppReport({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    this.status = 'pending',
    required this.createdAt,
  });

  factory AppReport.fromMap(Map<String, dynamic> map) {
    return AppReport(
      id: map['id']?.toString() ?? '',
      reporterId: map['reporter_id']?.toString() ?? '',
      reportedId: map['reported_id']?.toString() ?? '',
      reason: map['reason']?.toString() ?? 'بدون سبب محدد',
      status: map['status']?.toString() ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // دالة لتحويل الكائن إلى Map لإرساله إلى Supabase
  Map<String, dynamic> toMap() {
    return {
      'reporter_id': reporterId,
      'reported_id': reportedId,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
