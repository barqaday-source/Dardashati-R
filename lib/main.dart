import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dardashati_r/login_screen.dart'; // المسار المصحح لبيئة البناء
import 'package:dardashati_r/home_screen.dart';
import 'package:dardashati_r/notifications_screen.dart';
import 'package:dardashati_r/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تأكد من وضع بياناتك هنا ليعمل الربط الحقيقي
  await Supabase.initialize(
    url: 'https://jmsmrojtlstppnpwmkkk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imptc21yb2p0bHN0cHBucHdta2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4MTg2NDAsImV4cCI6MjA4ODM5NDY0MH0.j7gxr5CvrfvbJJzK_pMwVHiCE2AqpXUTThpeLEBmsos',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dardashati',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // الخلفية الداكنة العميقة لتناسب التصميم الزجاجي
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      // الانتقال المباشر للشاشة الحقيقية بدلاً من شاشة التحميل الغبية
      home: Supabase.instance.client.auth.currentUser == null 
          ? const LoginScreen() 
          : const HomeScreen(),
      
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
