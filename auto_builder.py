import os
import re

def smart_sync_main():
    lib_path = 'lib'
    main_file = os.path.join(lib_path, 'main.dart')
    
    # 1. الحصول على اسم المشروع تلقائياً من pubspec.yaml
    project_name = ""
    if os.path.exists('pubspec.yaml'):
        with open('pubspec.yaml', 'r') as f:
            match = re.search(r'^name:\s*(\w+)', f.read(), re.MULTILINE)
            if match: project_name = match.group(1)

    def get_file_info(file_name):
        path = os.path.join(lib_path, file_name)
        if not os.path.exists(path): return {"params": [], "imports": []}
        
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
            # استخراج المعاملات المطلوبة
            params = re.findall(r'required this\.(\w+)', content)
            # استخراج المكتبات المستوردة لضمان نقل الاعتمادات لـ main
            imports = re.findall(r"import 'package:([^']+)';", content)
            return {"params": params, "imports": imports, "content": content}

    # 2. تحليل الشاشات الأساسية
    login_info = get_file_info('login_screen.dart')
    home_info = get_file_info('home_screen.dart')

    # 3. وظيفة ذكية لتوليد قيم المعاملات بناءً على النوع المتوقع (تقريبي)
    def map_param_to_value(param, is_home=False):
        mapping = {
            'isLogin': 'true',
            'theme': 'ThemeData.dark()',
            'onThemeChanged': '(val) {}',
            'currentUser': 'user' if is_home else 'null',
            'client': 'Supabase.instance.client',
        }
        return mapping.get(param, 'null')

    # 4. بناء الـ Imports بشكل ديناميكي
    needed_imports = {
        f"package:{project_name}/login_screen.dart",
        f"package:{project_name}/home_screen.dart",
        "package:flutter/material.dart",
        "package:supabase_flutter/supabase_flutter.dart"
    }
    # إضافة أي موديلات أو ثيمات مكتشفة
    for info in [login_info, home_info]:
        for imp in info['imports']:
            if project_name in imp: needed_imports.add(f"package:{imp}")

    import_string = "\n".join([f"import '{imp}';" for imp in needed_imports])

    # 5. القالب المطور مع معالجة الأخطاء
    main_template = f"""{import_string}

void main() async {{
  WidgetsFlutterBinding.ensureInitialized();
  // ملاحظة: يفضل وضع المفاتيح في ملف .env مستقبلاً
  await Supabase.initialize(
    url: 'https://jmsmrojtlstppnpwmkkk.supabase.co', 
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
          if (snapshot.connectionState == ConnectionState.waiting) {{
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }}
          
          final session = snapshot.data?.session;
          final user = session?.user;

          if (session == null || user == null) {{
            return LoginScreen(
              {", ".join([f"{p}: {map_param_to_value(p)}" for p in login_info['params']])}
            );
          }}
          
          return HomeScreen(
            {", ".join([f"{p}: {map_param_to_value(p, True)}" for p in home_info['params']])}
          );
        }},
      ),
    );
  }}
}}
"""

    # 6. الكتابة والتنفيذ
    with open(main_file, 'w', encoding='utf-8') as f:
        f.write(main_template)
    
    print(f"✅ [تحديث ذكي]: تم فحص مشروع '{project_name}'")
    print(f"📂 تم تحديث الاستدعاءات بناءً على {len(login_info['params'])} معامل في شاشة الدخول و {len(home_info['params'])} في الرئيسية.")

if __name__ == "__main__":
    smart_sync_main()
