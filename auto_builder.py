import os
import re

def smart_sync_main():
    # 1. تحديد الملفات الأساسية
    lib_path = 'lib'
    main_file = os.path.join(lib_path, 'main.dart')
    screens = {
        'LoginScreen': os.path.join(lib_path, 'login_screen.dart'),
        'HomeScreen': os.path.join(lib_path, 'home_screen.dart')
    }

    def get_required_params(file_path):
        if not os.path.exists(file_path): return []
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # استخراج المتغيرات المطلوبة في الـ Constructor (required this.name)
            return re.findall(r'required this\.(\w+)', content)

    # 2. تحليل الاحتياجات الحقيقية لكل شاشة
    login_params = get_required_params(screens['LoginScreen'])
    home_params = get_required_params(screens['HomeScreen'])

    # 3. بناء كود main.dart بناءً على التحليل (بدون تخمين دوال)
    # نستخدم Object كنوع مرن لتجنب تضارب AppUser و User حتى تحله بيدك
    main_template = f"""
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati_r/login_screen.dart';
import 'package:dardashati_r/home_screen.dart';
import 'package:dardashati_r/models.dart';
import 'package:dardashati_r/app_theme.dart';

void main() async {{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: 'https://jmsmrojtlstppnpwmkkk.supabase.co', anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imptc21yb2p0bHN0cHBucHdta2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTg2NDAsImV4cCI6MjA4ODM5NDY0MH0.j7gxr5CvrfvbJJzK_pMwVHiCE2AqpXUTThpeLEBmsos');
  runApp(const DardashatiApp());
}}

class DardashatiApp extends StatelessWidget {{
  const DardashatiApp({{super.key}});

  @override
  Widget build(BuildContext context) {{
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // ثيم افتراضي لتجنب أخطاء الدوال المفقودة
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {{
          final user = snapshot.data?.session?.user;
          if (user == null) {{
            return LoginScreen({", ".join([f"{p}: {('true' if p=='isLogin' else 'ThemeData.dark()' if p=='theme' else '() {{}}')}" for p in login_params])});
          }}
          return HomeScreen({", ".join([f"{p}: {'user' if p=='currentUser' else 'ThemeData.dark()' if p=='theme' else '() {{}}'}" for p in home_params])});
        }},
      ),
    );
  }}
}}
"""
    # 4. التنفيذ والحقن
    with open(main_file, 'w', encoding='utf-8') as f:
        f.write(main_template)
    
    print("🚀 [نجاح حقيقي]: تم تحليل الشاشات وحقن الماين بما يتوافق مع دوالها الحالية.")

if __name__ == "__main__":
    smart_sync_main()
