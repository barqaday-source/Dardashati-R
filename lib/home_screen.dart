// 1. Dart & Flutter Imports
import 'package:dardashati/notifications_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

// 2. Project Internal Imports
import 'package:dardashati/models.dart'; 
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/notifications_screen.dart';
import 'package:dardashati/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppThemeData theme;
  final Function(AppThemeData) onThemeChanged;
  
  const HomeScreen({
    super.key, 
    required this.currentUser, 
    required this.theme, 
    required this.onThemeChanged
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  // تحديث عداد التنبيهات غير المقروءة
  Future<void> _refreshUnreadCount() async {
    try {
      final notifications = await DatabaseService.getNotifications();
      if (mounted) {
        setState(() {
          // استخدام .isRead من الموديل الجديد
          _unreadNotifications = notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    
    final List<Widget> pages = [
      _RoomsTab(theme: t, currentUser: widget.currentUser),
      _MessagesTab(theme: t, currentUser: widget.currentUser),
      const Center(child: Text("قريباً: شاشة البحث", style: TextStyle(fontFamily: 'Tajawal', color: Colors.white))), 
      ProfileScreen(
        userId: widget.currentUser.id, 
        currentUserId: widget.currentUser.id, 
        theme: t
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: t.gradientColors,
              ),
            ),
          ),
          Positioned(top: -50, left: -50, child: _BlurOrb(color: t.button.withOpacity(0.2), size: 250)),
          Positioned(bottom: 100, right: -50, child: _BlurOrb(color: t.button.withOpacity(0.1), size: 200)),
          SafeArea(
            bottom: false,
            child: IndexedStack(index: _tab, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(t),
    );
  }

  Widget _buildGlassBottomNav(AppThemeData t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 70,
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.grid_view_rounded, index: 0, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
              _NavItem(icon: Icons.chat_bubble_outline_rounded, index: 1, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
              _buildNotificationBtn(t),
              _NavItem(icon: Icons.person_outline_rounded, index: 3, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBtn(AppThemeData t) {
    return IconButton(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(theme: t)))
            .then((_) => _refreshUnreadCount());
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_none_rounded, color: t.text.withOpacity(0.5), size: 28),
          if (_unreadNotifications > 0)
            Positioned(
              right: -2, top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Text('$_unreadNotifications', 
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

// الـ Widgets المساعدة بقيت كما هي مع تحسين استقرار الألوان
class _BlurOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index, current;
  final AppThemeData theme;
  final Function(int) onTap;
  const _NavItem({required this.icon, required this.index, required this.current, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: active ? theme.button.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: active ? theme.button : theme.text.withOpacity(0.4), size: 26),
      ),
    );
  }
}

class _MessagesTab extends StatelessWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _MessagesTab({required this.theme, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("قائمة المحادثات الخاصة", style: TextStyle(color: theme.text.withOpacity(0.7), fontFamily: 'Tajawal')),
    );
  }
}

class _RoomsTab extends StatelessWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _RoomsTab({required this.theme, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("غرف الدردشة العامة", style: TextStyle(color: theme.text.withOpacity(0.7), fontFamily: 'Tajawal')),
    );
  }
}
