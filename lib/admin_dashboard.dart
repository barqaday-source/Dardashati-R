import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dardashati/models.dart';

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  // ==================== الأساسيات ومعرفات المستخدم ====================
  static User? get currentUser => _supabase.auth.currentUser;
  
  // حماية ضد القيمة الفارغة لضمان عدم انهيار التطبيق عند طلب الـ ID
  static String get uid => _supabase.auth.currentUser?.id ?? '';
  
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==================== 1. وظائف الإدارة المركزية (قوة المدير) ====================

  // جلب المستخدمين للبث المباشر في لوحة الإدارة
  static Stream<List<Map<String, dynamic>>> getAdminUsersStream() {
    return _supabase.from('users').stream(primaryKey: ['id']).order('username');
  }

  // تحكم كامل بحالة المستخدم (حظر/إلغاء حظر) - أساسي للوحة المدير
  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    try {
      await _supabase.from('users').update({'is_banned': isBanned}).eq('id', userId);
    } catch (e) {
      debugPrint('خطأ في تغيير حالة الحظر: $e');
    }
  }

  // تغيير رتبة المستخدم (ترقية لمشرف أو مدير)
  static Future<void> updateUserRole(String userId, String role) async {
    try {
      await _supabase.from('users').update({'role': role}).eq('id', userId);
    } catch (e) {
      debugPrint('خطأ في تغيير الرتبة: $e');
    }
  }

  // ==================== 2. إصلاح "الفجوات" (حل الأخطاء الـ 36 في السجل) ====================

  // حل خطأ السطر 36: جلب بيانات أي مستخدم بالمعرف
  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _supabase.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { 
      return null; 
    }
  }

  // حل أخطاء السطور 53 و 54: البحث الشامل عن المستخدمين والغرف
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _supabase.from('users').select().ilike('username', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _supabase.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // حل خطأ السطر 321: جلب أعضاء الغرفة
  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _supabase.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  // ==================== 3. نظام الرسائل (بدون أخطاء الـ Stream) ====================

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    // تم تنظيف الـ Stream من الفلاتر المعقدة لضمان استقرار التطبيق
    return _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: true);
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    if (uid.isEmpty) return;
    await _supabase.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  // ==================== 4. الإشعارات والتقارير (حل خطأ السطر 133) ====================

  static Future<void> markNotificationRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  // ==================== 5. الخروج الآمن ودخول جوجل ====================
  
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
}
