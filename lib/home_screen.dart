import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dardashati/models.dart'; 
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/profile_screen.dart';
import 'package:dardashati/notifications_screen.dart'; 

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

  Future<void> _refreshUnreadCount() async {
    try {
      final notifications = await DatabaseService.getNotifications();
      if (mounted) {
        setState(() {
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
      const Center(child: Text("البحث", style: TextStyle(color: Colors.white))), 
      ProfileScreen(userId: widget.currentUser.id, currentUserId: widget.currentUser.id, theme: t),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: LinearGradient(colors: t.gradientColors))),
          SafeArea(child: IndexedStack(index: _tab, children: pages)),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(t),
    );
  }

  Widget _buildGlassBottomNav(AppThemeData t) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(color: t.card.withOpacity(0.3), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.grid_view_rounded, index: 0, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
          _NavItem(icon: Icons.chat_bubble_outline_rounded, index: 1, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
          _buildNotificationBtn(t),
          _NavItem(icon: Icons.person_outline_rounded, index: 3, current: _tab, theme: t, onTap: (i) => setState(() => _tab = i)),
        ],
      ),
    );
  }

  Widget _buildNotificationBtn(AppThemeData t) {
    return IconButton(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(theme: t))).then((_) => _refreshUnreadCount()),
      icon: Icon(Icons.notifications_none_rounded, color: t.text.withOpacity(0.5)),
    );
  }
}

// هذه هي الأجزاء التي كانت ناقصة وتسببت في الأخطاء:
class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index, current;
  final AppThemeData theme;
  final Function(int) onTap;
  const _NavItem({required this.icon, required this.index, required this.current, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon, color: index == current ? theme.button : theme.text.withOpacity(0.4)), onPressed: () => onTap(index));
  }
}

class _RoomsTab extends StatelessWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _RoomsTab({required this.theme, required this.currentUser});
  @override
  Widget build(BuildContext context) => const Center(child: Text("الغرف"));
}

class _MessagesTab extends StatelessWidget {
  final AppThemeData theme;
  final AppUser currentUser;
  const _MessagesTab({required this.theme, required this.currentUser});
  @override
  Widget build(BuildContext context) => const Center(child: Text("المحادثات"));
}
