import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. الإشعارات (Notifications) ---
  static Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _client.from('notifications').stream(primaryKey: ['id'])
        .eq('user_id', uid!).order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    return await _client.from('notifications').select().eq('user_id', uid!);
  }

  // --- 2. المحادثات (Chat) ---
  static Future<void> sendMessage(String content, String receiverId, {String? replyToId}) async {
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Stream<List<AppMessage>> getMessagesStream(String otherId) {
    return _client.from('private_messages').stream(primaryKey: ['id'])
        .map((data) => data.where((m) => 
            (m['sender_id'] == uid && m['receiver_id'] == otherId) || 
            (m['sender_id'] == otherId && m['receiver_id'] == uid))
        .map((m) => AppMessage.fromMap(m)).toList());
  }

  static Future<void> markPrivateMessagesRead(String senderId) async {
    await _client.from('private_messages').update({'is_read': true})
        .eq('receiver_id', uid!).eq('sender_id', senderId);
  }

  // --- 3. الغرف والإدارة (Rooms & Admin) ---
  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').upsert({'room_id': roomId, 'user_id': uid});
  }

  static Stream<List<AppUser>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).map(
      (data) => data.map((u) => AppUser.fromMap(u)).toList());
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  // --- 4. تحديث البروفايل ---
  static Future<void> updateProfile({required String fullName, String? bio}) async {
    await _client.from('users').update({
      'full_name': fullName,
      if (bio != null) 'bio': bio,
    }).eq('id', uid!);
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }
}
