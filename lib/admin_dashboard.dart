import 'package:flutter/material.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/models.dart';

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
    final String? currentAdminId = DatabaseService.uid;
    
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.card,
        elevation: 0,
        title: Text('رقابة المجتمع', 
          style: TextStyle(fontFamily: 'Tajawal', color: t.text, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: DatabaseService.getAdminUsersStream(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: t.button));
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في الاتصال بالسيرفر', 
              style: TextStyle(color: Colors.red, fontFamily: 'Tajawal')));
          }
          
          final users = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isSelf = user.id == currentAdminId;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: user.isBanned ? Colors.red.withOpacity(0.05) : t.card.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: user.isBanned ? Colors.red.withOpacity(0.2) : Colors.transparent
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
                  title: Text(user.fullName, 
                    style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  subtitle: Text(user.isBanned ? 'حساب مقيد' : 'عضو نشط', 
                    style: TextStyle(color: user.isBanned ? Colors.red : Colors.green, fontSize: 11)),
                  trailing: isSelf 
                      ? Icon(Icons.shield_rounded, color: t.button)
                      : Switch(
                          value: user.isBanned,
                          activeColor: Colors.redAccent,
                          onChanged: (value) async {
                            await DatabaseService.toggleUserBan(user.id, value);
                          },
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
