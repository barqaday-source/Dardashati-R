import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. الملف الشخصي (Profile & Settings) ---
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
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true));
    final url = _client.storage.from('avatars').getPublicUrl(filePath);
    await _client.from('users').update({'avatar_url': url}).eq('id', uid!);
  }

  static Future<void> updateProfile({required String fullName, String? bio}) async {
    await _client.from('users').update({
      'full_name': fullName,
      if (bio != null) 'bio': bio,
    }).eq('id', uid!);
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }

  // --- 2. المراسلة الخاصة (Private Chat) ---
  // تم تعديل الأسماء لتطابق نداء الشاشات (content, receiverId)
  static Future<void> sendMessage(String content, String receiverId, {String? replyToId}) async {
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
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

  // --- 3. غرف الدردشة (Room Chat) ---
  static Future<void> sendRoomMessage({required String roomId, required String content}) async {
    await _client.from('messages').insert({'room_id': roomId, 'user_id': uid, 'content': content});
  }

  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId).order('created_at');
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _client.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((item) => AppUser.fromMap(item['users'])).toList();
  }

  // --- 4. التنبيهات (Notifications) ---
  static Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return _client.from('notifications').stream(primaryKey: ['id'])
        .eq('user_id', uid!).order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await _client.from('notifications').select().eq('user_id', uid!);
    return List<Map<String, dynamic>>.from(res);
  }

  // --- 5. البحث والإدارة ---
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client.from('users').select().ilike('full_name', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  static Stream<List<AppUser>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).map((d) => d.map((u) => AppUser.fromMap(u)).toList());
  }

  static Future<void> toggleUserBan(String id, bool val) async => 
      await _client.from('users').update({'is_banned': val}).eq('id', id);

  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _client.from('reports').insert({'reporter_id': uid, 'reported_id': targetId, 'reason': reason});
  }

  // --- 6. المصادقة (Auth) ---
  static Future<AuthResponse?> signInWithGoogle() async {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
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
}
