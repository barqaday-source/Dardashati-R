import os
import re

def smart_sync_main():
    lib_path = 'lib'
    main_file = os.path.join(lib_path, 'main.dart')
    
    # 1. استخراج اسم المشروع
    project_name = ""
    if os.path.exists('pubspec.yaml'):
        with open('pubspec.yaml', 'r') as f:
            match = re.search(r'^name:\s*(\w+)', f.read(), re.MULTILINE)
            if match: project_name = match.group(1)

    def analyze_file(file_name):
        path = os.path.join(lib_path, file_name)
        if not os.path.exists(path): return {"params": [], "has_method": lambda x: False}
        
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            # استخراج اسم الكلاس (مثلاً LoginScreen)
            class_name = file_name.replace('.dart', '').replace('_', ' ').title().replace(' ', '')
            # البحث عن الـ Constructor والمعاملات
            constructor_pattern = rf'{class_name}\s*\({{([^}]+)}}\)'
            match = re.search(constructor_pattern, content)
            params = []
            if match:
                params = re.findall(r'required this\.(\w+)', match.group(1))
            
            return {
                "params": list(set(params)),
                "content": content,
                "has_method": lambda m: m in content
            }

    # 2. تحليل الشاشات
    login_info = analyze_file('login_screen.dart')
    home_info = analyze_file('home_screen.dart')
    theme_info = analyze_file('app_theme.dart')

    # 3. بناء منطق القيم بناءً على المودل المرفق
    def get_val(p, is_home=False):
        # تحويل مستخدم سوبابيس إلى AppUser يدوياً لضمان التوافق
        app_user_logic = """AppUser(
                  id: user.id,
                  fullName: user.userMetadata?['full_name'] ?? 'مستخدم',
                  email: user.email ?? '',
                  avatarUrl: user.userMetadata?['avatar_url'] ?? '',
                )"""
        
        # التأكد من وجود ThemeData
        theme_val = "ThemeData.dark()"
        if theme_info['has_method']('toThemeData'):
            theme_val = "AppTheme.toThemeData()" # أو حسب مسمى الكلاس لديك

        mapping = {
            'isLogin': 'true',
            'theme': theme_val,
            'currentUser': app_user_logic if is_home else 'null',
            'onThemeChanged': '(v) {}',
            'client': 'Supabase.instance.client',
        }
        return mapping.get(p, 'null')

    # 4. بناء كود main.dart النهائي
    main_code = f"""import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:{project_name}/login_screen.dart';
import 'package:{project_name}/home_screen.dart';
import 'package:{project_name}/models.dart';
import 'package:{project_name}/app_theme.dart';

void main() async {{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imptc21yb2p0bHN0cHBucHdta2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTg2NDAsImV4cCI6MjA4ODM5NDY0MH0.j7gxr5CvrfvbJJzK_pMwVHiCE2AqpXUTThpeLEBmsos'
  );
  runApp(const DardashatiApp());
}}

class DardashatiApp extends StatelessWidget {{
  const DardashatiApp({{super.key}});

  @override
  Widget build(BuildContext context) {{
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {{
          final user = snapshot.data?.session?.user;
          
          if (user == null) {{
            return LoginScreen(
              {", ".join([f"{p}: {get_val(p)}" for p in login_info['params']])}
            );
          }}

          return HomeScreen(
            {", ".join([f"{p}: {get_val(p, True)}" for p in home_info['params']])}
          );
        }},
      ),
    );
  }}
}}
"""

    with open(main_file, 'w', encoding='utf-8') as f:
        f.write(main_code)
    print("✅ تم الربط بنجاح: تم استخدام نموذج AppUser المخصص وتجنب تضارب الأنواع.")

if __name__ == "__main__":
    smart_sync_main()
