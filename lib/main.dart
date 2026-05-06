import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// استيراد الموديلات الخاصة بك لحل مشكلة (Type Mismatch)
import 'package:dardashati_r/models.dart'; 
import 'package:dardashati_r/app_theme.dart';
// استيراد الشاشات
import 'package:dardashati_r/login_screen.dart';
import 'package:dardashati_r/home_screen.dart';
import 'package:dardashati_r/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تأكد من وضع بيانات Supabase الصحيحة هنا
  await Supabase.initialize(url: 'https://jmsmrojtlstppnpwmkkk.supabase.co', anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imptc21yb2p0bHN0cHBucHdta2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTg2NDAsImV4cCI6MjA4ODM5NDY0MH0.j7gxr5CvrfvbJJzK_pMwVHiCE2AqpXUTThpeLEBmsos');
  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});
  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  // استخدام AppThemeData الحقيقي لحل خطأ السجلات (cite: 1000005960.png)
  late AppThemeData _currentTheme = AppThemeData.dark(); 

  void _updateTheme(AppThemeData newTheme) {
    setState(() => _currentTheme = newTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // الربط مع نظام الثيم الخاص بك
      theme: _currentTheme.toThemeData(), 
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final user = snapshot.data?.session?.user;
          
          if (user == null) {
            return LoginScreen(
              isLogin: true,
              theme: _currentTheme, // تمرير النوع الصحيح AppThemeData
              onThemeChanged: _updateTheme, // تمرير الدالة الصحيحة
            );
          } else {
            return HomeScreen(
              // تحويل User إلى AppUser الحقيقي المطلوب في سجلاتك (cite: 1000005960.png)
              currentUser: AppUser.fromSupabase(user), 
              theme: _currentTheme,
              onThemeChanged: _updateTheme,
            );
          }
        },
      ),
    );
  }
}
