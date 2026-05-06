import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. المصادقة والبروفايل ---
  static Future<AppUser?> getUserById(String userId) async {
    final data = await _client.from('users').select().eq('id', userId).single();
    return AppUser.fromMap(data);
  }

  // حل خطأ Error 25 (تحويل الملف لرابط قبل التحديث)
  static Future<void> updateAvatar(String imageUrl) async {
    await _client.from('users').update({'avatar_url': imageUrl}).eq('id', uid!);
  }

  // --- 2. الدردشة الخاصة (حل Error 18, 19, 22, 23) ---
  static Future<void> sendMessage({required String content, required String receiverId, String? replyToId}) async {
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  // --- 3. نظام الغرف (حل Error 28, 29) ---
  static Future<void> sendRoomMessage({required String roomId, required String content}) async {
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid, 
      'content': content
    });
  }

  static Stream<List<AppMessage>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId)
        .map((data) => data.map((m) => AppMessage.fromMap(m)).toList());
  }

  // --- 4. الرقابة والبحث ---
  static Stream<List<AppUser>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).map(
      (data) => data.map((u) => AppUser.fromMap(u)).toList());
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }
}
