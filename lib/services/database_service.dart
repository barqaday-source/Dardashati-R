import 'dart:typed_data'; // تم إضافة هذا للتعامل مع Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatabaseService {
  static final _client = Supabase.instance.client;
  static String? get uid => _client.auth.currentUser?.id;

  // ═══════════════════════════════════════════
  // 1. المصادقة - Authentication
  // ═══════════════════════════════════════════

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

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static Future<AppUser?> getCurrentUser() async {
    if (uid == null) return null;
    final res =
        await _client.from('users').select().eq('id', uid!).maybeSingle();
    return res != null ? AppUser.fromMap(res) : null;
  }

  // ═══════════════════════════════════════════
  // 2. إدارة المستخدمين - Users
  // ═══════════════════════════════════════════

  static Future<AppUser?> getUserById(String userId) async {
    final res = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return res != null ? AppUser.fromMap(res) : null;
  }

  static Future<void> updateAvatar(String avatarUrl) async {
    await _client
        .from('users')
        .update({'avatar_url': avatarUrl}).eq('id', uid!);
  }

  /// رفع صورة البروفايل
  /// تم تغيير النوع من List<int> إلى Uint8List لحل خطأ argument_type_not_assignable
  static Future<String?> uploadAvatar(Uint8List fileBytes,
      {String extension = 'jpg'}) async {
    final path = 'avatars/$uid.$extension';
    
    // استخدام uploadBinary مباشرة مع Uint8List
    await _client.storage.from('avatars').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
    
    final url = _client.storage.from('avatars').getPublicUrl(path);
    await updateAvatar(url);
    return url;
  }

  // ═══════════════════════════════════════════
  // 3. البروفايل والإعدادات - Profile & Settings
  // ═══════════════════════════════════════════

  static Future<void> updateProfile({
    required String fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    await _client.from('users').update({
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid!);
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _client
        .from('users')
        .update({'theme_preference': themeName}).eq('id', uid!);
  }

  static Future<String?> getUserTheme() async {
    final res = await _client
        .from('users')
        .select('theme_preference')
        .eq('id', uid!)
        .maybeSingle();
    return res?['theme_preference'] as String?;
  }

  // ═══════════════════════════════════════════
  // 4. الرسائل الخاصة - Private Messages
  // ═══════════════════════════════════════════

  static Future<void> sendMessage(
    String content,
    String receiverId, {
    String? replyToId,
  }) async {
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  static Stream<List<AppMessage>> getMessagesStream(String otherId) {
    return _client
        .from('private_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((data) => data
            .where((m) =>
                (m['sender_id'] == uid && m['receiver_id'] == otherId) ||
                (m['sender_id'] == otherId && m['receiver_id'] == uid))
            .map((m) => AppMessage.fromMap(m))
            .toList());
  }

  static Future<void> markPrivateMessagesRead(String senderId) async {
    await _client
        .from('private_messages')
        .update({'is_read': true})
        .eq('receiver_id', uid!)
        .eq('sender_id', senderId);
  }

  static Future<int> getUnreadCount(String senderId) async {
    final res = await _client
        .from('private_messages')
        .select()
        .eq('receiver_id', uid!)
        .eq('sender_id', senderId)
        .eq('is_read', false);
    return (res as List).length;
  }

  // ═══════════════════════════════════════════
  // 5. نظام الغرف - Room Chat
  // ═══════════════════════════════════════════

  static Future<void> sendRoomMessage({
    required String roomId,
    required String content,
    String? replyToId,
  }) async {
    await _client.from('messages').insert({
      'room_id': roomId,
      'user_id': uid,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  static Stream<List<AppMessage>> getRoomMessagesStream(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => data.map((m) => AppMessage.fromMap(m)).toList());
  }

  /// Subscribe لرسائل الغرفة (Realtime)
  /// حل خطأ FilterType.eq و PostgresChangeFilter
  static RealtimeChannel subscribeToRoomMessages(
    String roomId,
    void Function(List<AppMessage> messages) onData,
  ) {
    final channel = _client
        .channel('room_messages_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq, // تم التصحيح من FilterType.eq
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) async {
            final res = await _client
                .from('messages')
                .select()
                .eq('room_id', roomId)
                .order('created_at', ascending: true);
            onData((res as List).map((m) => AppMessage.fromMap(m)).toList());
          },
        )
        .subscribe();
    return channel;
  }

  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _client
        .from('room_members')
        .select('users(*)')
        .eq('room_id', roomId);
    return (res as List)
        .where((u) => u['users'] != null)
        .map((u) => AppUser.fromMap(u['users'] as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AppRoom>> getRooms() async {
    final res = await _client.from('rooms').select();
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').upsert({
      'room_id': roomId,
      'user_id': uid,
    });
  }

  static Future<void> leaveRoom(String roomId) async {
    await _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', uid!);
  }

  // ═══════════════════════════════════════════
  // 6. الإشعارات - Notifications
  // ═══════════════════════════════════════════

  static Future<List<AppNotification>> getNotifications() async {
    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid!)
        .order('created_at', ascending: false);
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }

  static Stream<List<AppNotification>> getNotificationsStream() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid!)
        .order('created_at', ascending: false)
        .map((data) => data.map((n) => AppNotification.fromMap(n)).toList());
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  static Future<void> markAllNotificationsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid!)
        .eq('is_read', false);
  }

  static Future<int> getUnreadNotificationsCount() async {
    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid!)
        .eq('is_read', false);
    return (res as List).length;
  }

  // ═══════════════════════════════════════════
  // 7. البحث - Search
  // ═══════════════════════════════════════════

  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client
        .from('users')
        .select()
        .ilike('full_name', '%$query%')
        .neq('id', uid!)
        .limit(20);
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client
        .from('rooms')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }
}
