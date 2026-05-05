import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dardashati/models.dart';

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  // 1. إدارة المستخدم الحالي والجلسة
  static User? get currentUser => _supabase.auth.currentUser;
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 2. جلب بيانات المستخدم
  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _supabase
          .from('users') 
          .select()
          .eq('id', id)
          .single();
      
      return AppUser.fromMap(data);
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
      return null;
    }
  }

  // 3. تسجيل دخول جوجل
  static Future<AuthResponse?> signInWithGoogle() async {
    try {
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
    } catch (e) {
      print('خطأ في تسجيل دخول جوجل: $e');
      rethrow;
    }
  }

  // 4. نظام الرسائل والدردشة (تمت إضافة دوال الغرف المفقودة هنا)
  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    if (currentUser == null) return;
    await _supabase.from('messages').insert({
      'user_id': currentUser!.id,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
      'user_name': currentUser!.userMetadata?['full_name'] ?? 'مستخدم',
      'avatar_url': currentUser!.userMetadata?['avatar_url'],
    });
  }

  // دالة البحث عن المستخدمين (المطلوبة في search_screen)
  static Future<List<AppUser>> searchUsers(String query) async {
    final response = await _supabase
        .from('users')
        .select()
        .ilike('username', '%$query%');
    return (response as List).map((u) => AppUser.fromMap(u)).toList();
  }

  // دوال غرف الدردشة (المطلوبة في room_chat_screen)
  static Future<void> joinRoom(String roomId) async {
    await _supabase.from('room_members').insert({
      'room_id': roomId,
      'user_id': currentUser!.id,
    });
  }

  static Stream<List<Map<String, dynamic>>> getRoomMessages(String roomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
  }

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .or('user_id.eq.${currentUser!.id},receiver_id.eq.${currentUser!.id}')
        .order('created_at', ascending: true);
  }

  // 5. نظام الإشعارات
  static Future<List<AppNotification>> getNotifications() async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', currentUser!.id)
        .order('created_at', ascending: false);
    
    return (response as List).map((n) => AppNotification.fromMap(n)).toList();
  }

  static Future<void> markNotificationRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<void> markAllNotificationsRead() async {
    await _supabase.from('notifications').update({'is_read': true}).eq('user_id', currentUser!.id);
  }

  // 6. حماية المستخدم والتقارير
  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _supabase.from('reports').insert({
      'reporter_id': currentUser!.id,
      'reported_id': targetId,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // 7. إعدادات المستخدم
  static Future<void> saveUserTheme(String themeName) async {
    if (currentUser == null) return;
    await _supabase.from('users').update({
      'theme_preference': themeName,
    }).eq('id', currentUser!.id);
  }

  // 8. الخروج
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }
}
