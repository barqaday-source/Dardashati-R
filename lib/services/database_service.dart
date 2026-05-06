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

  // --- 2. الإشعارات (حل خطأ getter 'getNotifications') ---
  static Future<List<AppNotification>> getNotifications() async {
    final res = await _client.from('notifications').select().eq('user_id', uid!);
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }

  // --- 3. الدردشة الخاصة (حل أخطاء الوسائط 17، 18، 19، 21، 22، 23) ---
  // جعلنا المعاملات اختيارية ليدعم الكود القديم والجديد في شاشاتك
  static Future<void> sendMessage({String? content, String? receiverId, String? replyToId}) async {
    if (content == null || receiverId == null) return; 
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  // --- 4. نظام الغرف (حل خطأ النوع Type Mismatch - Error 27) ---
  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').upsert({'room_id': roomId, 'user_id': uid});
  }

  static Stream<List<AppMessage>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId)
        .map((data) => data.map((m) => AppMessage.fromMap(m)).toList());
  }

  // --- 5. البروفايل والصور (حل خطأ File type - Error 24) ---
  static Future<AppUser?> getUserById(String userId) async {
    final data = await _client.from('users').select().eq('id', userId).single();
    return AppUser.fromMap(data);
  }

  static Future<void> updateAvatar(dynamic avatarSource) async {
    // حل مشكلة إرسال File بدلاً من String
    String url = avatarSource is String ? avatarSource : avatarSource.toString();
    await _client.from('users').update({'avatar_url': url}).eq('id', uid!);
  }

  // --- 6. البحث والإدارة ---
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client.from('users').select().ilike('full_name', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }
}
