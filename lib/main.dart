import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// استدعاء المكونات المعتمدة لمشروع دردشاتي
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart'; 
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/home_screen.dart';
import 'package:dardashati/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // تأكد من وضع قيم Supabase الحقيقية هنا
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL', 
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});

  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  AppThemeData _currentTheme = AppThemes.allThemes[0];
  bool _initialized = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
    _listenToAuthChanges();
  }

  Future<void> _loadInitialSettings() async {
    try {
      if (Supabase.instance.client.auth.currentUser != null) {
        // يمكن تفعيل جلب الثيم هنا لاحقاً
      }
    } catch (e) {
      debugPrint("Theme Error: $e");
    } finally {
      if (mounted) setState(() => _initialized = true);
    }
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => UpdatePasswordScreen(theme: _currentTheme)),
        );
      }
    });
  }

  void _changeTheme(AppThemeData newTheme) {
    setState(() => _currentTheme = newTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'دردشاتي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: 'Tajawal', 
        useMaterial3: true,
        brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
        // إضافة اللون الأساسي للثيم ليتوافق مع أجزاء النظام
        primaryColor: _currentTheme.primaryColor,
      ),
      home: !_initialized 
          ? _buildLoadingScreen() 
          : _AuthGate(theme: _currentTheme, onThemeChanged: _changeTheme),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _currentTheme.background,
      body: Center(child: CircularProgressIndicator(color: _currentTheme.primaryColor)),
    );
  }
}

class _AuthGate extends StatelessWidget {
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;

  const _AuthGate({required this.theme, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session != null) {
          // تم إصلاح الخطأ هنا: تمرير جميع الحقول المطلوبة لـ AppUser (حل خطأ السطر 135)
          final user = AppUser(
            id: session.user.id,
            fullName: session.user.userMetadata?['full_name'] ?? 'مستخدم',
            email: session.user.email ?? '', // حقل مطلوب
            avatarUrl: session.user.userMetadata?['avatar_url'] ?? '',
            isOnline: true,
            themePreference: theme.name,
          );
          return HomeScreen(currentUser: user, theme: theme, onThemeChanged: onThemeChanged);
        }

        return LoginScreen(theme: theme, onThemeChanged: onThemeChanged, isLogin: true);
      },
    );
  }
}

class UpdatePasswordScreen extends StatelessWidget {
  final AppThemeData theme;
  const UpdatePasswordScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final passController = TextEditingController();
    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(title: const Text('كلمة مرور جديدة'), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'أدخل كلمة المرور الجديدة',
                labelStyle: TextStyle(color: theme.primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.button,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: passController.text.trim())
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('تحديث الآن', style: TextStyle(color: theme.buttonText)),
            )
          ],
        ),
      ),
    );
  }
}

