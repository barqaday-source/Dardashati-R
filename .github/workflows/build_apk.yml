import 'package:flutter/material.dart';

// ==================== 1. Models ====================

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
  final bool isRead; 

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

// ==================== 2. Main Entry Point ====================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DardashatiApp());
}

// ==================== 3. App Core ====================

class DardashatiApp extends StatelessWidget {
  const DardashatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دردشاتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      home: const MainSplashScreen(),
    );
  }
}

class MainSplashScreen extends StatelessWidget {
  const MainSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // تم حذف const من هنا لحل مشكلة الـ Container
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'دردشاتي',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري تهيئة النظام...'),
          ],
        ),
      ),
    );
  }
}
