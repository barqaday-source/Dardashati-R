import os
import re

def build_perfect_main():
    # 1. فحص الشاشات لاستخراج الاحتياجات الحقيقية
    screens = {'LoginScreen': 'lib/login_screen.dart', 'HomeScreen': 'lib/home_screen.dart'}
    needs = {}
    for name, path in screens.items():
        if os.path.exists(path):
            with open(path, 'r') as f:
                content = f.read()
                needs[name] = re.findall(r'required this\.(\w+)', content)

    # 2. بناء كود main.dart بناءً على الاحتياجات المستخرجة
    main_code = """
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati_r/models.dart'; 
import 'package:dardashati_r/app_theme.dart';
import 'package:dardashati_r/login_screen.dart';
import 'package:dardashati_r/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');
  runApp(const DardashatiApp());
}

class DardashatiApp extends StatefulWidget {
  const DardashatiApp({super.key});
  @override
  State<DardashatiApp> createState() => _DardashatiAppState();
}

class _DardashatiAppState extends State<DardashatiApp> {
  late AppThemeData _theme = AppThemeData.dark();
  void _updateTheme(AppThemeData t) => setState(() => _theme = t);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _theme.toThemeData(),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final user = snapshot.data?.session?.user;
          if (user == null) {
            return LoginScreen(""" + \
            ", ".join([f"{p}: {'true' if p=='isLogin' else '_theme' if p=='theme' else '_updateTheme'}" for p in needs.get('LoginScreen', [])]) + \
            """);
          }
          return HomeScreen(""" + \
            ", ".join([f"{p}: {'AppUser.fromSupabase(user)' if p=='currentUser' else '_theme' if p=='theme' else '_updateTheme'}" for p in needs.get('HomeScreen', [])]) + \
            """);
        },
      ),
    );
  }
}
"""
    # 3. حقن الملف في مكانه الصحيح
    with open('lib/main.dart', 'w') as f:
        f.write(main_code)
    print("✅ تم فحص الشاشات، وصناعة ملف main.dart متكامل، وحقنه في lib/main.dart بنجاح!")

if __name__ == "__main__":
    build_perfect_main()
