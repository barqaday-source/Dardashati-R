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

  // --- 2. المحادثات (Private & Room Chat) ---
  // تم تعريف sendMessage و replyToId لحل أخطاء GitHub (Error 21, 24)
  static Future<void> sendMessage({required String content, required String receiverId, String? replyToId}) async {
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Future<void> sendRoomMessage({required String roomId, required String content}) async {
    await _client.from('messages').insert({'room_id': roomId, 'user_id': uid, 'content': content});
  }

  // تحويل البيانات لـ AppMessage لحل خطأ توافق الأنواع (Error 15, 17)
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

  // --- 3. الغرف والبحث (Rooms & Search) ---
  // إضافة joinRoom المفقودة (Error 20, 23)
  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').upsert({'room_id': roomId, 'user_id': uid});
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // --- 4. الإدارة والبروفايل (Admin & Settings) ---
  static Stream<List<AppUser>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).map(
      (data) => data.map((u) => AppUser.fromMap(u)).toList());
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
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

  // --- 5. الإشعارات (Notifications) ---
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    return await _client.from('notifications').select().eq('user_id', uid!);
  }
}
