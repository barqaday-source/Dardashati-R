import 'package:flutter/material.dart';
import 'package:blur/blur.dart'; 
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/models.dart'; 
import 'package:dardashati/services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  final AppThemeData theme;
  const NotificationsScreen({super.key, required this.theme});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // جلب التنبيهات باستخدام الخدمة المحدثة
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await DatabaseService.getNotifications();
      if (mounted) {
        setState(() { 
          _notifications = data; 
          _loading = false; 
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          _notifications = []; 
          _loading = false; 
        });
      }
    }
  }

  // تعديل اسم الدالة لتطابق ما هو موجود في DatabaseService
  Future<void> _markAllRead() async {
    try {
      // تم تغيير المسمى هنا ليطابق المحرك الجديد DatabaseService
      await DatabaseService.markAllNotificationsRead();
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: Container(color: t.card.withOpacity(0.5)).frozen(blur: 15),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text('الإشعارات', 
              style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Tajawal')),
            if (unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: t.button,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$unreadCount جديد', 
                  style: TextStyle(color: t.buttonText, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('تحديد الكل', 
                style: TextStyle(color: t.button, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.button))
          : _notifications.isEmpty
              ? _buildEmptyState(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: t.button,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) => _buildNotificationItem(_notifications[i], t),
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(AppNotification n, AppThemeData t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: n.isRead ? t.card.withOpacity(0.4) : t.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: n.isRead ? Colors.transparent : t.button.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          if (!n.isRead) {
            await DatabaseService.markNotificationRead(n.id);
            _load(); 
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 45, height: 45,
                decoration: BoxDecoration(
                  color: t.button.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(n.icon, color: t.button, size: 22),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, 
                      style: TextStyle(
                        color: t.text, 
                        fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, 
                        fontSize: 14,
                        fontFamily: 'Tajawal'
                      )),
                    const SizedBox(height: 2),
                    Text(n.body, 
                      style: TextStyle(color: t.text.withOpacity(0.6), fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: t.button, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppThemeData t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 60, color: t.text.withOpacity(0.1)),
          const SizedBox(height: 15),
          Text('لا توجد إشعارات حالياً', 
            style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 14, fontFamily: 'Tajawal')),
        ],
      ),
    );
  }
}
