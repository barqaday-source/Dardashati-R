import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dardashati/models.dart';

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  // 1. المعرفات الأساسية (لحل أخطاء uid و currentUser)
  static User? get currentUser => _supabase.auth.currentUser;
  static String? get uid => _supabase.auth.currentUser?.id;
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 2. نظام الدخول (Auth)
  static Future<AuthResponse?> signInWithGoogle() async {
    const webClientId = '62134907551-ofam7s8j4m4id3qtdqac6vrk7ui2d2o3.apps.googleusercontent.com';
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: googleAuth.idToken!,
      accessToken: googleAuth.accessToken,
    );
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }

  // 3. إدارة المستخدمين والبحث (حل أخطاء profile_screen و search_screen)
  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _supabase.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }

  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _supabase.from('users').select().ilike('username', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _supabase.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // 4. نظام الرسائل والغرف (حل أخطاء private_chat و room_chat)
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    // تم إلغاء .or() هنا لأنها تسبب خطأ برمجياً في الـ Stream
    return _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: true);
  }

  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    if (uid == null) return;
    await _supabase.from('messages').insert({
      'user_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _supabase.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _supabase.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  // 5. الإشعارات والتقارير (حل أخطاء notifications_screen)
  static Future<void> markNotificationRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _supabase.from('reports').insert({'reporter_id': uid!, 'reported_id': targetId, 'reason': reason});
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _supabase.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }
}
