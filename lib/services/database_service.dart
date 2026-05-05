import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/models.dart';
import 'package:google_sign_in/google_sign_in.dart';

class DatabaseService {
  static final _supabase = Supabase.instance.client;

  // الوصول السريع للمستخدم الحالي (لحل خطأ السطر 59 في السجل)
  static User? get currentUser => _supabase.auth.currentUser;
  static String? get uid => _supabase.auth.currentUser?.id;

  // ==================== 1. نظام الدخول (Auth) ====================

  // حل خطأ السطر 33 في السجل
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

  // ==================== 2. إدارة المستخدمين ====================

  // حل خطأ السطر 37 في السجل
  static Future<AppUser?> getUserById(String id) async {
    try {
      final data = await _supabase.from('users').select().eq('id', id).single();
      return AppUser.fromMap(data);
    } catch (e) { return null; }
  }

  // حل خطأ السطر 54 في السجل
  static Future<List<AppUser>> searchUsers(String query) async {
    final res = await _supabase.from('users').select().ilike('username', '%$query%');
    return (res as List).map((u) => AppUser.fromMap(u)).toList();
  }

  // ==================== 3. الرسائل الخاصة (Private Chat) ====================

  // حل خطأ السطر 32 في السجل (Stream مطلوب في private_chat_screen)
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return _supabase.from('messages').stream(primaryKey: ['id'])
        .or('user_id.eq.$uid,receiver_id.eq.$uid')
        .order('created_at', ascending: true);
  }

  // حل خطأ السطر 35 في السجل
  static Future<void> sendMessage(String receiverId, String content, {String? replyToId}) async {
    if (uid == null) return;
    await _supabase.from('messages').insert({
      'user_id': uid,
      'receiver_id': receiverId,
      'content': content,
      'reply_to_id': replyToId,
    });
  }

  // حل خطأ السطر 31 في السجل
  static Future<void> markPrivateMessagesRead(String otherUserId) async {
    await _supabase.from('messages').update({'is_read': true})
        .eq('receiver_id', uid!).eq('user_id', otherUserId);
  }

  // ==================== 4. غرف الدردشة (Rooms) ====================

  // حل خطأ السطر 41 في السجل
  static Future<void> joinRoom(String roomId) async {
    await _supabase.from('room_members').insert({'room_id': roomId, 'user_id': uid!});
  }

  // حل خطأ السطر 42 في السجل
  static Future<List<Map<String, dynamic>>> getRoomMessages(String roomId) async {
    final res = await _supabase.from('messages').select().eq('room_id', roomId).order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  // حل خطأ السطر 43 في السجل
  static Stream<List<Map<String, dynamic>>> subscribeToRoomMessages(String roomId) {
    return _supabase.from('messages').stream(primaryKey: ['id']).eq('room_id', roomId);
  }

  // حل خطأ السطر 44 في السجل
  static Future<void> sendRoomMessage(String roomId, String content) async {
    await _supabase.from('messages').insert({'room_id': roomId, 'user_id': uid!, 'content': content});
  }

  // حل خطأ السطر 52 في السجل
  static Future<List<AppUser>> getRoomMembers(String roomId) async {
    final res = await _supabase.from('room_members').select('users(*)').eq('room_id', roomId);
    return (res as List).map((u) => AppUser.fromMap(u['users'])).toList();
  }

  // حل خطأ السطر 55 في السجل
  static Future<List<AppRoom>> searchRooms(String query) async {
    final res = await _supabase.from('rooms').select().ilike('name', '%$query%');
    return (res as List).map((r) => AppRoom.fromMap(r)).toList();
  }

  // ==================== 5. الإشعارات والتقارير ====================

  // حل خطأ السطر 61 في السجل
  static Future<void> saveUserTheme(String themeName) async {
    await _supabase.from('users').update({'theme_preference': themeName}).eq('id', uid!);
  }

  // حل خطأ السطر 38 في السجل
  static Future<void> submitReport({required String targetId, required String reason}) async {
    await _supabase.from('reports').insert({'reporter_id': uid!, 'reported_id': targetId, 'reason': reason});
  }

  static Future<void> markAllNotificationsRead() async {
    await _supabase.from('notifications').update({'is_read': true}).eq('user_id', uid!);
  }
}
