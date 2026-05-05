import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dardashati/models.dart';

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  static User? get currentUser => _supabase.auth.currentUser;
  static String? get uid => _supabase.auth.currentUser?.id; // إضافة uid لحل أخطاء المعرفات
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==================== 1. نظام الدخول ====================
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

  // ==================== 2. الرسائل (تصحيح أخطاء السطور 32 و 49) ====================

  // تصحيح: الـ Stream لا يدعم .or() برمجياً ويسبب فشل البناء
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _supabase.from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  // إضافة الدالة المفقودة المطلوبة في السطر 54 من السجل
  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    final res = await _supabase.from('messages')
        .select()
        .or('and(user_id.eq.$uid,receiver_id.eq.$otherUserId),and(user_id.eq.$otherUserId,receiver_id.eq.$uid)')
        .order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
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

  // ==================== 3. نظام الغرف (تصحيح أخطاء السطور 42-44) ====================

  // تعديل لتطابق استدعاء UI: استخدام Named Parameters
  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _supabase.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  // تصحيح السطر 42 و 57: إرجاع AppMessage بدلاً من Map
  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
     final res = await _supabase.from('messages').select().eq('room_id', roomId).order('created_at');
     return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  // ==================== 4. الإدارة والبحث (حل خطأ السطر 37 و 41) ====================

  // إضافة دالة جلب الإشعارات المفقودة
  static Future<List<AppNotification>> getNotifications() async {
    if (uid == null) return [];
    final res = await _supabase.from('notifications').select().eq('user_id', uid!).order('created_at');
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }

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

  // ==================== 5. التحكم والمغادرة ====================

  static Future<void> saveUserTheme(String themeName) async {
    await _supabase.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }
}
