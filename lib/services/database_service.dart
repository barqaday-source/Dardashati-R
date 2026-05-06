import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. إدارة الملف الشخصي ---
  static Future<void> updateProfile({
    required String fullName, 
    String? bio, 
    String? avatarUrl
  }) async {
    if (uid == null) return;
    
    final updates = {
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('users').update(updates).eq('id', uid!);
  }

  static Future<void> updateAvatar(String url) async {
    if (uid == null) return;
    await _client.from('users').update({'avatar_url': url}).eq('id', uid!);
  }

  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { 
      debugPrint("Error fetching user: $e");
      return null; 
    }
  }

  // --- 2. إدارة البلاغات (تمت الإضافة لإصلاح أخطاء CI/CD) ---
  static Future<void> submitReport({required String targetId, required String reason}) async {
    if (uid == null) return;
    await _client.from('reports').insert({
      'reporter_id': uid,
      'reported_id': targetId,
      'reason': reason,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- 3. المراسلة والغرف ---
  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    if (uid == null) return;
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    try {
      // جلب معرفات المستخدمين المنضمين للغرفة ثم جلب بياناتهم
      final res = await _client.from('room_members').select('users(*)').eq('room_id', roomId);
      return (res as List).map((item) => AppUser.fromMap(item['users'])).toList();
    } catch (e) {
      debugPrint("Error fetching room members: $e");
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId).order('created_at');
  }

  // --- 4. التنبيهات (إصلاح دالة markAllNotificationsRead) ---
  static Future<void> markAllNotificationsRead() async {
    if (uid == null) return;
    await _client.from('notifications').update({'is_read': true}).eq('user_id', uid!);
  }

  static Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  // --- 5. المصادقة (Auth) ---
  static Future<AuthResponse?> signInWithGoogle() async {
    // تم استخدام قيمة البيئة للتوافق مع GitHub Secrets لاحقاً
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', 
        defaultValue: '62134907551-ofam7s8j4m4id3qtdqac6vrk7ui2d2o3.apps.googleusercontent.com');
    
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

  // --- 6. البحث والأدوات ---
  static Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final res = await _client.from('users').select().ilike('full_name', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    if (query.isEmpty) return [];
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  static Future<void> saveUserTheme(String themeName) async {
    if (uid == null) return;
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }
}
