import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get uid => _client.auth.currentUser?.id;

  // ==================== وظائف المدير (Admin) ====================
  static Stream<List<Map<String, dynamic>>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).order('username');
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  // ==================== حل أخطاء الشاشات (Undefined Methods) ====================
  
  // حل خطأ البحث (سطر 53، 54)
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client.from('users').select().ilike('username', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // حل خطأ الإشعارات (سطر 133)
  static Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  // حل خطأ الملف الشخصي (سطر 36)
  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }

  // حل خطأ الغرف (سطر 321)
  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _client.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  // ==================== نظام الرسائل والدخول ====================
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _client.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: true);
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

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
}
