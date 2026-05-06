import 'package:flutter/material.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/models.dart'; // استيراد النماذج مهم جداً

class AdminDashboard extends StatefulWidget {
  final AppThemeData theme;
  const AdminDashboard({super.key, required this.theme});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    // الحصول على ID الأدمن الحالي لمنع حظر نفسه (إدارة ذكية)
    final String? currentAdminId = DatabaseService.uid;
    
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.card,
        elevation: 0,
        title: Text('إدارة المجتمع الذكية', 
          style: TextStyle(fontFamily: 'Tajawal', color: t.text, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<AppUser>>(
        // استخدام StreamBuilder مع الموديل AppUser مباشرة بدلاً من Map
        stream: DatabaseService.getAdminUsersStream(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: t.button));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في جلب البيانات', style: TextStyle(color: t.text, fontFamily: 'Tajawal')));
          }
          
          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(child: Text('لا يوجد أعضاء حالياً', style: TextStyle(color: t.text, fontFamily: 'Tajawal')));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isSelf = user.id == currentAdminId; // هل هذا هو الأدمن الحالي؟

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: user.isBanned ? Colors.red.withOpacity(0.05) : t.card.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: user.isBanned ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05)
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: t.button.withOpacity(0.1),
                    backgroundImage: (user.avatarUrl.isNotEmpty) ? NetworkImage(user.avatarUrl) : null,
                    child: (user.avatarUrl.isEmpty) 
                        ? Text(user.fullName[0], style: TextStyle(color: t.button, fontWeight: FontWeight.bold)) 
                        : null,
                  ),
                  title: Row(
                    children: [
                      if (isSelf) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: t.button, borderRadius: BorderRadius.circular(5)),
                          child: const Text('أنت', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(user.fullName, 
                          style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                      ),
                    ],
                  ),
                  subtitle: Text(user.email, style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 12)),
                  trailing: isSelf 
                      ? const Icon(Icons.admin_panel_settings, color: Colors.blueAccent)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(user.isBanned ? 'محظور' : 'نشط', 
                                style: TextStyle(
                                  color: user.isBanned ? Colors.red : Colors.greenAccent, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal'
                                )),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 25,
                              width: 40,
                              child: Switch(
                                value: user.isBanned,
                                activeColor: Colors.redAccent,
                                onChanged: (value) async {
                                  // تحديث ذكي: لا يسمح بتغيير حالة الأدمن لنفسه
                                  await DatabaseService.toggleUserBan(user.id, value);
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
