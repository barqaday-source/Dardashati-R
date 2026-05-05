import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dardashati/models.dart';

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // جلب بيانات المستخدم
  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _supabase.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }

  // تسجيل دخول جوجل (مطلوبة في login_screen)
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

  // نظام الرسائل (حل أخطاء private_chat_screen)
  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    if (currentUser == null) return;
    await _supabase.from('messages').insert({
      'user_id': currentUser!.id,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _supabase.from('messages').stream(primaryKey: ['id'])
        .or('user_id.eq.${currentUser!.id},receiver_id.eq.${currentUser!.id}')
        .order('created_at', ascending: true);
  }

  // دالة تم طلبها في السطر 41 من السجل
  static Future<void> markPrivateMessagesRead(String otherUserId) async {
    await _supabase.from('messages').update({'is_read': true})
        .eq('receiver_id', currentUser!.id).eq('user_id', otherUserId);
  }

  // نظام الغرف (حل أخطاء room_chat_screen)
  static Future<void> joinRoom(String roomId) async => await _supabase.from('room_members').insert({'room_id': roomId, 'user_id': currentUser!.id});
  
  static Future<List<Map<String, dynamic>>> getRoomMessages(String roomId) async {
     final res = await _supabase.from('messages').select().eq('room_id', roomId).order('created_at');
     return List<Map<String, dynamic>>.from(res);
  }

  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _supabase.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId);
  }

  static Future<void> sendRoomMessage(String roomId, String content) async {
    await _supabase.from('messages').insert({'room_id': roomId, 'user_id': currentUser!.id, 'content': content});
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _supabase.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  // البحث (حل أخطاء search_screen)
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _supabase.from('users').select().ilike('username', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _supabase.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // الإشعارات والتقارير
  static Future<void> markAllNotificationsRead() async => await _supabase.from('notifications').update({'is_read': true}).eq('user_id', currentUser!.id);
  static Future<void> markNotificationRead(String id) async => await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _supabase.from('reports').insert({'reporter_id': currentUser!.id, 'reported_id': targetId, 'reason': reason});
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _supabase.from('users').update({'theme_preference': themeName}).eq('id', currentUser!.id);
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }
}
