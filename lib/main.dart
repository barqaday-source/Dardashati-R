import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// استيراد ملفاتك الخاصة - تأكد من صحة المسارات
import 'package:dardashati_r/models.dart'; 
import 'package:dardashati_r/app_theme.dart';
import 'package:dardashati_r/login_screen.dart';
import 'package:dardashati_r/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تأكد من وضع بيانات Supabase الحقيقية هنا لكي لا يعلق التطبيق
  await Supabase.initialize(
    url: 'https://jmsmrojtlstppnpwmkkk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imptc21yb2p0bHN0cHBucHdta2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTg2NDAsImV4cCI6MjA4ODM5NDY0MH0.j7gxr5CvrfvbJJzK_pMwVHiCE2AqpXUTThpeLEBmsos',
  );
  
  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});

  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  // تعريف الثيم بناءً على ملف app_theme.dart الخاص بك
  // إذا كان هناك خطأ في AppThemeData، تأكد من إصلاحه في ملفه
  late AppThemeData _appTheme = AppThemeData.dark(); 

  void _onThemeChanged(AppThemeData newTheme) {
    setState(() {
      _appTheme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // نستخدم طريقة تحويل الثيم الخاصة بك (تأكد من وجود الدالة في ملفك)
      theme: _appTheme.toThemeData(), 
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          final user = session?.user;

          if (user == null) {
            // شاشة الدخول مع تمرير المتغيرات المطلوبة يدوياً
            return LoginScreen(
              isLogin: true,
              theme: _appTheme,
              onThemeChanged: _onThemeChanged,
            );
          } else {
            // الشاشة الرئيسية مع تحويل المستخدم لـ AppUser (تأكد من وجود الدالة في models.dart)
            return HomeScreen(
              currentUser: AppUser.fromSupabase(user),
              theme: _appTheme,
              onThemeChanged: _onThemeChanged,
            );
          }
        },
      ),
    );
  }
}
