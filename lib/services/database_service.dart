import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get uid => _client.auth.currentUser?.id;

  // --- 1. تحديث بيانات الملف الشخصي (الاسم، البايو، الصورة) ---
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

  // --- 2. تحديث صورة البروفايل فقط ---
  static Future<void> updateAvatar(String url) async {
    if (uid == null) return;
    await _client.from('users').update({'avatar_url': url}).eq('id', uid!);
  }

  static Stream<List<Map<String, dynamic>>> getAdminUsersStream() {
    return _client.from('users').stream(primaryKey: ['id']).order('full_name');
  }

  static Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _client.from('users').update({'is_banned': isBanned}).eq('id', userId);
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }

  static Future<AuthResponse?> signInWithGoogle() async {
    // ملاحظة: يفضل وضع webClientId في GitHub Secrets أيضاً
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

  // --- المراسلة الخاصة ---
  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    final res = await _client.from('messages')
        .select()
        .or('and(user_id.eq.$uid,receiver_id.eq.$otherUserId),and(user_id.eq.$otherUserId,receiver_id.eq.$uid)')
        .order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    // هذا الاستعلام يجلب الرسائل الخاصة بين الطرفين
    return _client.from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    await _client.from('messages').insert({
      'user_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  static Future<void> markPrivateMessagesRead(String otherUserId) async {
    if (uid == null) return;
    await _client.from('messages').update({'is_read': true})
        .eq('receiver_id', uid!).eq('user_id', otherUserId);
  }

  // --- الغرف والمجموعات ---
  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').insert({'room_id': roomId, 'user_id': uid!});
  }

  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    final res = await _client.from('messages').select().eq('room_id', roomId).order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId);
  }

  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  // --- التنبيهات والثيم ---
  static Future<List<AppNotification>> getNotifications() async {
    if (uid == null) return [];
    final res = await _client.from('notifications').select().eq('user_id', uid!).order('created_at');
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }

  static Future<void> markNotificationRead(String id) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', id);
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }

  // --- البحث (محدث) ---
  static Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    // البحث في الاسم الكامل لتوافق الـ Schema الجديد
    final res = await _client.from('users').select().ilike('full_name', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    if (query.isEmpty) return [];
    final res = await _client.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _client.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }
}
