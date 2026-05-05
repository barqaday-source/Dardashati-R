import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart'; // ضرورية لـ debugPrint

class DatabaseService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get uid => _client.auth.currentUser?.id;

  // ==================== 1. وظائف الإدارة (مطابقة للوحة المدير) ====================

  // جلب المستخدمين للبث المباشر في لوحة الإدارة
  static Stream<List<Map<String, dynamic>>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).order('username');
  }

  // التحكم في الحظر (Ban) - أساسي للمدير
  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    try {
      await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // تحديث رتبة المستخدم
  static Future<void> updateUserRole(String userId, String role) async {
    await _client.from('users').update({'role': role}).eq('id', userId);
  }

  // ==================== 2. نظام الدخول والتحقق ====================

  static Future<AuthResponse?> signInWithGoogle() async {
    const webClientId = '62134907551-ofam7s8j4m4id3qtdqac6vrk7ui2d2o3.apps.googleusercontent.com';
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
    await GoogleSignIn().signOut();
    await _client.auth.signOut();
  }

  // ==================== 3. الرسائل الخاصة (حل أخطاء السطور 31-54) ====================

  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    final res = await _client.from('messages')
        .select()
        .or('and(user_id.eq.$uid,receiver_id.eq.$otherUserId),and(user_id.eq.$otherUserId,receiver_id.eq.$uid)')
        .order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _client.from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    if (uid == null) return;
    await _client.from('messages').insert({
      'user_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  // ==================== 4. نظام الغرف والبحث (حل أخطاء السطور 42-321) ====================

  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    final res = await _client.from('messages').select().eq('room_id', roomId).order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _client.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  // حل أخطاء البحث (سطر 53 و 54)
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client.from('users').select().ilike('username', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  // ==================== 5. الإشعارات والملف الشخصي (حل أخطاء سطر 36 و 133) ====================

  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }

  static Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<List<AppNotification>> getNotifications() async {
    if (uid == null) return [];
    final res = await _client.from('notifications').select().eq('user_id', uid!).order('created_at');
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }
}
  }
}
