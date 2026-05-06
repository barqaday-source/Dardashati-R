import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/utils/logger.dart';

class SupabaseService {
  // الوصول السريع للعميل (Client)
  static SupabaseClient get client => Supabase.instance.client;
  
  // بيانات المستخدم المسجل حالياً
  static User? get currentAuthUser => client.auth.currentUser;
  
  // معرف المستخدم (UUID)
  static String? get currentUserId => currentAuthUser?.id;

  // جلب المفاتيح من بيئة العمل (Environment Variables)
  // هذه الطريقة تسمح لـ GitHub ببناء التطبيق دون الحاجة لملف env.dart
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    try {
      // التحقق من وجود المفاتيح قبل البدء (لتجنب أخطاء وقت التشغيل)
      if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) {
        AppLogger.error("SUPABASE", "مفاتيح الاتصال مفقودة! تأكد من إعداد الـ Environment Variables");
      }

      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseKey,
      );
      
      AppLogger.success("SUPABASE", "تم الاتصال بخوادم سوبابيس بنجاح 🚀");
    } catch (e) {
      AppLogger.error("SUPABASE", "فشل الاتصال الأولي بالخادم", e);
      rethrow;
    }
  }

  static bool get hasActiveSession => client.auth.currentSession != null;
}
