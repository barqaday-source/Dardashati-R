import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. المصادقة (Authentication) ---
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

  // --- 2. إدارة المستخدمين والبروفايل (حل أخطاء الصورة الأخيرة) ---
  // تم إضافة هذه الدوال لأن الشاشات تطلبها (Error 24, 25, 32)
  static Future<AppUser?> getUserById(String userId) async {
    final data = await _client.from('users').select().eq('id', userId).single();
    return AppUser.fromMap(data);
  }

  static Future<void> updateAvatar(String url) async {
    await _client.from('users').update({'avatar_url': url}).eq('id', uid!);
  }

  static Future<void> updateProfile({required String fullName, String? bio}) async {
    await _client.from('users').update({
      'full_name': fullName,
      if (bio != null) 'bio': bio,
    }).eq('id', uid!);
  }

  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client.from('users').select().ilike('full_name', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  // --- 3. نظام الدردشة الخاص (Private Chat) ---
  static Future<void> sendMessage({required String content, required String receiverId, String? replyToId}) async {
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

  // --- 4. نظام الغرف (Rooms) ---
  // تم إضافة subscribeToRoomMessages و getRoomMembers (Error 29, 31)
  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').upsert({'room_id': roomId, 'user_id': uid});
  }

  static Future<void> sendRoomMessage({required String roomId, required String content}) async {
    await _client.from('messages').insert({'room_id': roomId, 'user_id': uid, 'content': content});
  }

  static Stream<List<AppMessage>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId)
        .map((data) => data.map((m) => AppMessage.fromMap(m)).toList());
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _client.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // --- 5. الرقابة والإدارة (Admin) ---
  static Stream<List<AppUser>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).map(
      (data) => data.map((u) => AppUser.fromMap(u)).toList());
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  // --- 6. الإعدادات والإشعارات ---
  static Future<void> saveUserTheme(String themeName) async {
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    return await _client.from('notifications').select().eq('user_id', uid!);
  }
}
