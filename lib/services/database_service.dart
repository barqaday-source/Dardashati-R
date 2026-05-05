import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatabaseService {
  // استخدام عميل سوبابيز بشكل مباشر وصحيح
  static final _client = Supabase.instance.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get uid => _client.auth.currentUser?.id;

  // ==================== 1. نظام الدخول والتحقق ====================

  static Future<AuthResponse?> signInWithGoogle() async {
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

  // ==================== 2. الرسائل الخاصة (حل أخطاء السطور 31-54) ====================

  // تم حل خطأ السطر 49 و 54: جلب الرسائل كـ Future للتحميل الأولي
  static Future<List<AppMessage>> getPrivateMessages(String otherUserId) async {
    final res = await _client.from('messages')
        .select()
        .or('and(user_id.eq.$uid,receiver_id.eq.$otherUserId),and(user_id.eq.$otherUserId,receiver_id.eq.$uid)')
        .order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  // تم حل خطأ السطر 32 و 49: الـ stream لا يقبل .or()، لذا نستخدم stream عام والفلترة تتم عبر RLS
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _client.from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true);
  }

  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    if (uid == null) return;
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

  // ==================== 3. نظام الغرف (حل أخطاء السطور 41-44) ====================

  static Future<void> joinRoom(String roomId) async {
    await _client.from('room_members').insert({'room_id': roomId, 'user_id': uid!});
  }

  // تعديل لتطابق التوقعات في السجل سطر 42
  static Future<List<AppMessage>> getRoomMessages(String roomId) async {
    final res = await _client.from('messages').select().eq('room_id', roomId).order('created_at');
    return (res as List).map((m) => AppMessage.fromMap(m)).toList();
  }

  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _client.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId);
  }

  // حل خطأ السطر 100-102: استخدام Named Parameters
  static Future<void> sendRoomMessage({required String roomId, required String content, String? replyToId}) async {
    await _client.from('messages').insert({
      'room_id': roomId, 
      'user_id': uid!, 
      'content': content,
      'reply_to_id': replyToId
    });
  }

  // ==================== 4. الإشعارات والتقارير (حل خطأ السطر 41 و 61) ====================

  // إضافة الدالة المفقودة التي طلبتها صفحة home_screen سطر 41
  static Future<List<AppNotification>> getNotifications() async {
    if (uid == null) return [];
    final res = await _client.from('notifications').select().eq('user_id', uid!).order('created_at');
    return (res as List).map((n) => AppNotification.fromMap(n)).toList();
  }

  static Future<void> markAllNotificationsRead() async {
    await _client.from('notifications').update({'is_read': true}).eq('user_id', uid!);
  }

  static Future<void> saveUserTheme(String themeName) async {
    await _client.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }

  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _client.from('reports').insert({'reporter_id': uid!, 'reported_id': targetId, 'reason': reason});
  }
}
