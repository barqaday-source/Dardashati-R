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
    final res = await _client.from('users').select().eq('id', uid!).single();
    return AppUser.fromMap(res);
  }

  // ═══════════════════════════════════════════
  // 2. الرسائل الخاصة - Private Messages
  // حل أخطاء: 17، 19، 21، 22، 23
  // ═══════════════════════════════════════════

  /// إرسال رسالة خاصة — Named Parameters لحل خطأ extra_positional_arguments
  static Future<void> sendMessage({
    required String content,
    required String receiverId,
    String? replyToId,
  }) async {
    await _client.from('private_messages').insert({
      'sender_id': uid,
      'receiver_id': receiverId,
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  /// Stream للرسائل بين المستخدم الحالي ومستخدم آخر — حل خطأ 19 و 22
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

  /// تحديد الرسائل كمقروءة — حل خطأ 17 و 21
  static Future<void> markPrivateMessagesRead(String senderId) async {
    await _client
        .from('private_messages')
        .update({'is_read': true})
        .eq('receiver_id', uid!)
        .eq('sender_id', senderId);
  }

  /// جلب آخر رسالة خاصة مع مستخدم معين
  static Future<AppMessage?> getLastMessage(String otherId) async {
    final res = await _client
        .from('private_messages')
        .select()
        .or('and(sender_id.eq.$uid,receiver_id.eq.$otherId),and(sender_id.eq.$otherId,receiver_id.eq.$uid)')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res != null ? AppMessage.fromMap(res) : null;
  }

  /// عدد الرسائل غير المقروءة
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
  // 3. نظام الغرف - Room Chat
  // حل أخطاء: 26، 27، 29
  // ═══════════════════════════════════════════

  /// إرسال رسالة في غرفة — حل خطأ 26
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

  /// Stream لرسائل الغرفة — حل خطأ 27 (Stream<List<AppMessage>>)
  static Stream<List<AppMessage>> getRoomMessagesStream(String roomId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => data.map((m) => AppMessage.fromMap(m)).toList());
  }

  /// جلب أعضاء الغرفة — حل خطأ 29
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

  /// جلب جميع الغرف
  static Future<List<AppRoom>> getRooms() async {
    final res = await _client.from('rooms').select();
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  /// الانضمام لغرفة
  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').upsert({
      'room_id': roomId,
      'user_id': uid,
    });
  }

  /// مغادرة غرفة
  static Future<void> leaveRoom(String roomId) async {
    await _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', uid!);
  }

  // ═══════════════════════════════════════════
  // 4. البروفايل والإعدادات - Profile & Settings
  // حل أخطاء: 31، 32
  // ═══════════════════════════════════════════

  /// تحديث بيانات البروفايل — حل خطأ 31
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

  /// حفظ ثيم المستخدم — حل خطأ 32
  static Future<void> saveUserTheme(String themeName) async {
    await _client
        .from('users')
        .update({'theme_preference': themeName}).eq('id', uid!);
  }

  /// جلب تفضيل الثيم الحالي
  static Future<String?> getUserTheme() async {
    final res = await _client
        .from('users')
        .select('theme_preference')
        .eq('id', uid!)
        .single();
    return res['theme_preference'] as String?;
  }

  // ═══════════════════════════════════════════
  // 5. الإشعارات - Notifications
  // حل خطأ: 15 (NotificationsScreen methods)
  // ═══════════════════════════════════════════

  /// جلب إشعارات المستخدم
  static Future<List<AppNotification>> getNotifications() async {
    final res = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid!)
        .order('created_at', ascending: false);
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }

  /// Stream للإشعارات الجديدة
  static Stream<List<AppNotification>> getNotificationsStream() {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid!)
        .order('created_at', ascending: false)
        .map((data) => data.map((n) => AppNotification.fromMap(n)).toList());
  }

  /// تحديد إشعار كمقروء
  static Future<void> markNotificationRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true}).eq('id', notificationId);
  }

  /// تحديد جميع الإشعارات كمقروءة
  static Future<void> markAllNotificationsRead() async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid!)
        .eq('is_read', false);
  }

  // ═══════════════════════════════════════════
  // 6. البحث - Search
  // ═══════════════════════════════════════════

  /// البحث عن مستخدمين
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _client
        .from('users')
        .select()
        .ilike('full_name', '%$query%')
        .neq('id', uid!)
        .limit(20);
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  /// البحث عن غرف
  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _client
        .from('rooms')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }
}
