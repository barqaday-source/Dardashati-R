import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dardashati/models.dart';

// هذا الكلاس هو المحرك الأساسي للتطبيق، قمنا بإضافة كل الدوال الناقصة هنا
class DatabaseService {
  static final _supabase = Supabase.instance.client;

  // معرفات المستخدم الحالية (تستخدم في كل الشاشات)
  static User? get currentUser => _supabase.auth.currentUser;
  static String? get uid => _supabase.auth.currentUser?.id;
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ==================== 1. البحث والمستخدمين (حل أخطاء search_screen و profile_screen) ====================

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

  // ==================== 2. الرسائل والغرف (حل أخطاء room_chat_screen) ====================

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    // تم إصلاح الـ Stream بإزالة .or() لتجنب أخطاء التشغيل
    return _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: true);
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _supabase.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _supabase.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  // ==================== 3. الإشعارات (حل أخطاء notifications_screen) ====================

  static Future<void> markNotificationRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  // ==================== 4. لوحة الإدارة (Admin Dashboard) ====================

  static Stream<List<Map<String, dynamic>>> getAdminUsersStream() {
    return _supabase.from('users').stream(primaryKey: ['id']).order('username');
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _supabase.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  // ==================== 5. نظام الدخول والخروج ====================

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }
}

// --- هنا يبدأ كود الواجهة (UI) للوحة الإدارة ---
// تأكد من تحديث دالة بناء الواجهة لتتوافق مع الدوال الجديدة أعلاه
