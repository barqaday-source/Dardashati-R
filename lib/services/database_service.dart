import 'dart:io'; // ضروري للتعامل مع الملفات
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. إدارة الملف الشخصي وصور البروفايل ---

  // الدالة الاحترافية لرفع الصورة من ملف (File) إلى Storage
  static Future<void> updateAvatar(File imageFile) async {
    if (uid == null) return;

    try {
      final String filePath = 'avatars/$uid.jpg';

      // 1. رفع الصورة إلى الـ Bucket (يجب أن يكون اسمه avatars في Supabase)
      await _client.storage.from('avatars').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // 2. الحصول على رابط الصورة المباشر
      final String publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);

      // 3. تحديث الرابط في جدول المستخدمين (استخدمنا 'users' كما في كودك)
      await _client.from('users').update({
        'avatar_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid!);
      
    } catch (e) {
      debugPrint("Error uploading avatar: $e");
      rethrow;
    }
  }

  static Future<void> updateProfile({
    required String fullName, 
    String? bio, 
  }) async {
    if (uid == null) return;
    
    final updates = {
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('users').update(updates).eq('id', uid!);
  }

  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { 
      debugPrint("Error fetching user: $e");
      return null; 
    }
  }

  // --- 2. إدارة البلاغات ---
  static Future<void> submitReport({required String targetId, required String reason}) async {
    if (uid == null) return;
    await _client.from('reports').insert({
      'reporter_id': uid,
      'reported_id': targetId,
      'reason': reason,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- 3. المراسلة والغرف ---
  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    if (uid == null) return;
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    try {
      final res = await _client.from('room_members').select('users(*)').eq('room_id', roomId);
      return (res as List).map((item) => AppUser.fromMap(item['users'])).toList();
    } catch (e) {
      debugPrint("Error fetching room members: $e");
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId).order('created_at');
  }

  // --- 4. التنبيهات ---
  static Future<void> markAllNotificationsRead() async {
    if (uid == null) return;
    await _client.from('notifications').update({'is_read': true}).eq('user_id', uid!);
  }

  static Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  // --- 5. المصادقة (Auth) ---
  static Future<AuthResponse?> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', 
        defaultValue: '62134907551-ofam7s8j4m4id3qtdqac6vrk7ui2d2o3.apps.googleusercontent.com');
    
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    
    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
  }

  static Future<void> signOut() async {
    try { await GoogleSignIn().signOut(); } catch (_) {}
    await _client.auth.signOut();
  }

  // --- 6. وظائف الأدمن (Admin) - تمت إضافتها بناءً على الملفات السابقة ---
  static Stream<List<AppUser>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).order('full_name').map(
      (data) => data.map((u) => AppUser.fromMap(u)).toList(),
    );
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  // --- 7. البحث والأدوات ---
  static Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final res = await _client.from('users').select().ilike('full_name', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<void> saveUserTheme(String themeName) async {
    if (uid == null) return;
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }
}
