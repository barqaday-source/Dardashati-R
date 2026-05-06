import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/login_screen.dart';
import 'package:dardashati/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // قم بوضع روابط Supabase الخاصة بك هنا
  await Supabase.initialize(
    url: 'https://your-project.supabase.co', 
    anonKey: 'your-anon-key',
  );

  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});

  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  // استخدام الثيم الافتراضي من كلاس AppThemes الموجود عندك
  AppThemeData _currentTheme = AppThemes.defaultTheme;

  void _updateTheme(AppThemeData newTheme) {
    setState(() => _currentTheme = newTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دردشاتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
      ),
      home: AuthWrapper(
        theme: _currentTheme,
        onThemeChanged: _updateTheme,
      ),
      // تعريف المسارات لضمان عمل التنقل المذكور في LoginScreen
      routes: {
        '/home': (context) => AuthWrapper(theme: _currentTheme, onThemeChanged: _updateTheme),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;

  const AuthWrapper({super.key, required this.theme, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // حالة التحميل أثناء التأكد من الجلسة
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        if (session == null) {
          // لم يسجل دخول: إظهار شاشة الدخول مع الثيم المطلوب
          return LoginScreen(
            theme: theme,
            onThemeChanged: onThemeChanged,
            isLogin: true,
          );
        } else {
          // مسجل دخول: تحويل المستخدم الخام إلى AppUser وتوجيهه للرئيسية
          final user = AppUser.fromSupabase(session.user);
          return HomeScreen(
            currentUser: user,
            theme: theme,
            onThemeChanged: onThemeChanged,
          );
        }
      },
    );
  }
}
