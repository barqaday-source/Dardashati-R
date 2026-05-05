import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get uid => _client.auth.currentUser?.id;

  // ==================== 1. وظائف الإدارة والتحقق ====================
  
  static Stream<List<Map<String, dynamic>>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).order('username');
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _client.auth.signOut();
  }

  // ==================== 2. الرسائل الخاصة (إصلاح أخطاء الشات الخاص) ====================

  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    final res = await _client.from('messages')
        .select()
        .or('and(user_id.eq.$uid,receiver_id.eq.$otherUserId),and(user_id.eq.$otherUserId,receiver_id.eq.$uid)')
        .order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    await _client.from('messages').insert({
      'user_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Future<void> markPrivateMessagesRead(String otherUserId) async {
    await _client.from('messages').update({'is_read': true})
        .eq('receiver_id', uid!).eq('user_id', otherUserId);
  }

  // ==================== 3. نظام الغرف (إصلاح أخطاء Room Chat) ====================

  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').insert({'room_id': roomId, 'user_id': uid!});
  }

  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    final res = await _client.from('messages').select().eq('room_id', roomId).order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId);
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  // ==================== 4. الإشعارات والتقارير والمظهر ====================

  static Future<List<AppNotification>> getNotifications() async {
    if (uid == null) return [];
    final res = await _client.from('notifications').select().eq('user_id', uid!).order('created_at');
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }

  static Future<void> markAllNotificationsRead() async {
    await _client.from('notifications').update({'is_read': true}).eq('user_id', uid!);
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }

  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _client.from('reports').insert({'reporter_id': uid!, 'reported_id': targetId, 'reason': reason});
  }

  // ==================== 5. البحث والملف الشخصي ====================

  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }

  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client.from('users').select().ilike('username', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }
}
