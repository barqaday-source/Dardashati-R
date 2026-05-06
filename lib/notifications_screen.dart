import 'package:flutter/material.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';

// هذا هو الكلاس الذي يطلبه ملف الـ Home ويبحث عنه النظام
class NotificationsScreen extends StatefulWidget {
  final AppThemeData theme;
  const NotificationsScreen({super.key, required this.theme});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        title: const Text("التنبيهات", style: TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: t.card,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: DatabaseService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // هنا يمكنك إضافة منطق عرض قائمة التنبيهات لاحقاً
          return Center(
            child: Text("لا توجد تنبيهات جديدة حالياً", 
              style: TextStyle(color: t.text.withOpacity(0.5))),
          );
        },
      ),
    );
  }
}
