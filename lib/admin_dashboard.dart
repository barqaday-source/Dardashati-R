import 'package:flutter/material.dart';
import 'package:dardashati/services/database_service.dart'; // استيراد الخدمة التي أصلحناها
import 'package:dardashati/models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم النظام'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => DatabaseService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // استخدام الدالة التي عرفناها في ملف الـ Service
        stream: DatabaseService.getAdminUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمين حالياً'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isBanned = user['is_banned'] ?? false;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user['avatar_url'] ?? ''),
                  child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user['username'] ?? 'مستخدم غير معروف'),
                subtitle: Text(user['email'] ?? ''),
                trailing: Switch(
                  value: isBanned,
                  activeColor: Colors.red,
                  onChanged: (value) async {
                    // استدعاء دالة الحظر من ملف الخدمة
                    await DatabaseService.toggleUserBan(user['id'], value);
                    setState(() {}); // تحديث الواجهة
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
