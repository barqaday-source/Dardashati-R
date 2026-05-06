import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// استيراد كافة الشاشات والخدمات لضمان عدم وجود Missing Imports
import 'package:dardashati_r/login_screen.dart';
import 'package:dardashati_r/home_screen.dart';
import 'package:dardashati_r/notifications_screen.dart';
import 'package:dardashati_r/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة السيرفر قبل تشغيل أي واجهة لضمان عدم حدوث تعليق (Loading Loop)
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
  ThemeMode _themeMode = ThemeMode.dark; // النمط الداكن الافتراضي لتصميمك الزجاجي

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authClient = Supabase.instance.client.auth;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      // تعريف الثيمات هنا يحل مشكلة الـ (theme is required) في كل الشاشات
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      
      // المنطق العميق: فحص الجلسة الحقيقية وتمرير البيانات المطلوبة
      home: StreamBuilder<AuthState>(
        stream: authClient.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session == null) {
            // حقن البيانات المطلوبة لشاشة الدخول لتعمل واجهتك
            return LoginScreen(
              isLogin: true, 
              theme: Theme.of(context), 
              onThemeChanged: _toggleTheme
            );
          } else {
            // حقن بيانات المستخدم في الشاشة الرئيسية
            return HomeScreen(
              currentUser: session.user,
              theme: Theme.of(context),
              onThemeChanged: _toggleTheme,
            );
          }
        },
      ),
    );
  }
}
