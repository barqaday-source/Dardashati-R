import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dardashati/services/supabase_service.dart'; // الخدمة التي عدلناها
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart'; 
import 'package:dardashati/home_screen.dart';
import 'package:dardashati/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ضبط اتجاه الشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // تهيئة سوبابيس باستخدام الخدمة الجديدة التي تسحب القيم من البيئة آلياً
  // لاحظ حذفنا dotenv.load لأننا لم نعد نحتاجها
  await SupabaseService.initialize();

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
      // هنا يمكنك مستقبلاً جلب الثيم المفضل للمستخدم من Supabase
      if (SupabaseService.currentAuthUser != null) {
         // منطق استعادة الثيم من قاعدة البيانات
      }
    } catch (e) {
      debugPrint("Theme Loading Error: $e");
    } finally {
      if (mounted) setState(() => _initialized = true);
    }
  }

  void _listenToAuthChanges() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
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
      // دعم اللغة العربية والخطوط
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
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;

        if (session != null) {
          // تحويل مستخدم سوبابيس إلى AppUser الخاص بمشروعك
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
                await SupabaseService.client.auth.updateUser(
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
