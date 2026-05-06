import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. إدارة الحساب والصور ---
  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }

  static Future<void> updateAvatar(File imageFile) async {
    if (uid == null) return;
    final filePath = 'avatars/$uid.jpg';
    await _client.storage.from('avatars').upload(filePath, imageFile, 
        fileOptions: const FileOptions(upsert: true));
    final url = _client.storage.from('avatars').getPublicUrl(filePath);
    await _client.from('users').update({'avatar_url': url}).eq('id', uid!);
  }

  // --- 2. المراسلة (حل أخطاء sendMessage & getMessagesStream) ---
  static Future<void> sendMessage({required String receiverId, required String content}) async {
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherId) {
    return _client.from('private_messages').stream(primaryKey: ['id'])
        .order('created_at').map((data) => data.where((m) => 
            (m['sender_id'] == uid && m['receiver_id'] == otherId) || 
            (m['sender_id'] == otherId && m['receiver_id'] == uid)).toList());
  }

  static Future<void> markPrivateMessagesRead(String senderId) async {
    await _client.from('private_messages').update({'is_read': true})
        .eq('receiver_id', uid!).eq('sender_id', senderId);
  }

  // --- 3. الغرف والبحث (حل أخطاء joinRoom & searchRooms) ---
  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').upsert({'room_id': roomId, 'user_id': uid});
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // --- 4. التنبيهات (حل أخطاء getNotifications) ---
  static Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _client.from('notifications').stream(primaryKey: ['id'])
        .eq('user_id', uid!).order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    return await _client.from('notifications').select().eq('user_id', uid!);
  }

  // --- 5. الإدارة والبلاغات ---
  static Stream<List<AppUser>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).map((d) => d.map((u) => AppUser.fromMap(u)).toList());
  }

  static Future<void> toggleUserBan(String id, bool val) async => 
      await _client.from('users').update({'is_banned': val}).eq('id', id);

  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _client.from('reports').insert({'reporter_id': uid, 'reported_id': targetId, 'reason': reason});
  }

  // --- 6. المصادقة ---
  static Future<void> signOut() async => await _client.auth.signOut();
}
