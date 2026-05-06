import 'package:flutter/material.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';

class AdminDashboard extends StatefulWidget {
  final AppThemeData theme; // أضفنا الثيم لتوحيد المظهر
  const AdminDashboard({super.key, required this.theme});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.card,
        elevation: 0,
        title: Text('إدارة المستخدمين', 
          style: TextStyle(fontFamily: 'Tajawal', color: t.text, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: t.text),
            onPressed: () async {
              await DatabaseService.signOut();
              if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService.getAdminUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: t.button));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في جلب البيانات', style: TextStyle(color: t.text, fontFamily: 'Tajawal')));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('لا يوجد مستخدمين حالياً', style: TextStyle(color: t.text, fontFamily: 'Tajawal')));
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final String userId = user['id']?.toString() ?? '';
              final bool isBanned = user['is_banned'] ?? false;
              final String name = user['full_name'] ?? 'مستخدم غير معروف';
              final String email = user['email'] ?? 'بدون بريد';
              final String? avatar = user['avatar_url'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: t.card.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isBanned ? Colors.red.withOpacity(0.2) : Colors.transparent),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: t.button.withOpacity(0.1),
                    backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                    child: (avatar == null || avatar.isEmpty) 
                        ? Text(name.isNotEmpty ? name[0] : "?", style: TextStyle(color: t.button, fontWeight: FontWeight.bold)) 
                        : null,
                  ),
                  title: Text(name, 
                      textAlign: TextAlign.right,
                      style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  subtitle: Text(email, 
                      textAlign: TextAlign.right,
                      style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isBanned ? 'محظور' : 'نشط', 
                          style: TextStyle(
                            color: isBanned ? Colors.red : Colors.greenAccent, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal'
                          )),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 25,
                        width: 40,
                        child: Switch(
                          value: isBanned,
                          activeColor: Colors.redAccent,
                          inactiveTrackColor: t.text.withOpacity(0.1),
                          onChanged: (value) async {
                            if (userId.isNotEmpty) {
                              await DatabaseService.toggleUserBan(userId, value);
                            }
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
