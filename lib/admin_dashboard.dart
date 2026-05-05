import 'package:flutter/material.dart';
import 'package:dardashati/services/database_service.dart';
// تم حذف استيراد models.dart لأنه غير مستخدم هنا ويسبب فشل البناء في GitHub

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
        title: const Text('لوحة تحكم النظام', style: TextStyle(fontFamily: 'Tajawal')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => DatabaseService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DatabaseService.getAdminUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يوجد مستخدمين حالياً', style: TextStyle(fontFamily: 'Tajawal')));
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isBanned = user['is_banned'] ?? false;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (user['avatar_url'] != null && user['avatar_url'].toString().isNotEmpty) 
                      ? NetworkImage(user['avatar_url']) 
                      : null,
                  child: (user['avatar_url'] == null || user['avatar_url'].toString().isEmpty) 
                      ? const Icon(Icons.person, color: Colors.grey) 
                      : null,
                ),
                title: Text(user['username'] ?? user['full_name'] ?? 'مستخدم غير معروف', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user['email'] ?? ''),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isBanned ? 'محظور' : 'نشط', 
                        style: TextStyle(color: isBanned ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 30,
                      child: Switch(
                        value: isBanned,
                        activeColor: Colors.red,
                        onChanged: (value) async {
                          await DatabaseService.toggleUserBan(user['id'], value);
                          // ملاحظة: الـ StreamBuilder سيقوم بالتحديث تلقائياً عند تغيير البيانات في قاعدة البيانات
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
