import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // تأكد من إضافة هذه المكتبة في pubspec.yaml

import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart'; 
import 'package:dardashati/home_screen.dart';
import 'package:dardashati/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // محاولة تحميل المتغيرات السرية من GitHub Actions
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Info: .env file not found locally.");
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // الربط الآمن باستخدام المتغيرات التي وضعتها في GitHub
  // إذا لم يجدها (أثناء التشغيل المحلي مثلاً) سيستخدم القيم التي أرسلتها أنت كاحتياط
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? 'https://jmsmrojtlstppnpwmkkk.supabase.co', 
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imptc21yb2p0bHN0cHBucHdta2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTg2NDAsImV4cCI6MjA4ODM5NDY0MH0.j7gxr5CvrfvbJJzK_pMwVHiCE2AqpXUTThpeLEBmsos',
  );

  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});

  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  // استخدام الثيم الأول كافتراضي لضمان عدم وجود أخطاء في التعريف
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
        // منطق جلب الثيم مستقبلاً
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
        primaryColor: _currentTheme.button,
        scaffoldBackgroundColor: _currentTheme.background,
      ),
      home: !_initialized 
          ? _buildLoadingScreen() 
          : _AuthGate(theme: _currentTheme, onThemeChanged: _changeTheme),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _currentTheme.background,
      body: Center(child: CircularProgressIndicator(color: _currentTheme.button)),
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
          final user = AppUser(
            id: session.user.id,
            fullName: session.user.userMetadata?['full_name'] ?? 'مستخدم',
            email: session.user.email ?? '', 
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
      appBar: AppBar(
        title: const Text('كلمة مرور جديدة', style: TextStyle(fontFamily: 'Tajawal')), 
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'أدخل كلمة المرور الجديدة',
                labelStyle: TextStyle(color: theme.button, fontFamily: 'Tajawal'),
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
              child: Text('تحديث الآن', style: TextStyle(color: theme.buttonText, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            )
          ],
        ),
      ),
    );
  }
}
