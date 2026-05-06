import 'package:flutter/material.dart';
import 'package:dardashati/models.dart'; 
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String currentUserId;
  final AppThemeData theme;
  
  const ProfileScreen({
    super.key, 
    required this.userId, 
    required this.currentUserId, 
    required this.theme
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;
  
  // استخدام getter آمن للتحقق من ملكية الحساب
  bool get _isMe => widget.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await DatabaseService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    
    // 1. حالة التحميل
    if (_loading) {
      return Scaffold(
        backgroundColor: t.background, 
        body: Center(child: CircularProgressIndicator(color: t.button))
      );
    }

    // 2. حالة عدم وجود بيانات (Null Check)
    if (_user == null) {
      return Scaffold(
        backgroundColor: t.background, 
        body: Center(
          child: Text('المستخدم غير موجود أو تم حذفه', 
            style: TextStyle(color: t.text, fontFamily: 'Tajawal'))
        )
      );
    }

    // تعيين متغير محلي غير قابل لكونه null للاستخدام في الواجهة
    final u = _user!;

    return Scaffold(
      backgroundColor: t.background,
      appBar: _buildAppBar(t),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 20),
          _buildAvatarSection(t, u),
          const SizedBox(height: 20),
          _buildNameAndRole(t, u),
          const SizedBox(height: 40),
          _buildInfoCard(t, u),
          const SizedBox(height: 30),
          _buildActionButtons(t),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // --- دوال بناء الواجهة المقسمة لشفرة أنظف ---

  PreferredSizeWidget _buildAppBar(AppThemeData t) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20), 
        onPressed: () => Navigator.pop(context)
      ),
      actions: [
        if (!_isMe) 
          IconButton(
            icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent), 
            onPressed: _showReportSheet
          ),
      ],
    );
  }

  Widget _buildAvatarSection(AppThemeData t, AppUser u) {
    // معالجة آمنة للصورة الشخصية
    final String imageUrl = u.avatarUrl ?? "";
    final String firstLetter = u.fullName.isNotEmpty ? u.fullName[0] : "?";

    return Stack(alignment: Alignment.center, children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle, 
          border: Border.all(color: t.button.withOpacity(0.2), width: 2)
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: t.card,
          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: imageUrl.isEmpty 
            ? Text(firstLetter, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: t.button)) 
            : null,
        ),
      ),
      if (u.isOnline)
        Positioned(
          bottom: 8, right: 8,
          child: Container(
            width: 20, height: 20, 
            decoration: BoxDecoration(
              color: Colors.greenAccent, 
              shape: BoxShape.circle, 
              border: Border.all(color: t.background, width: 3)
            )
          ),
        ),
    ]);
  }

  Widget _buildNameAndRole(AppThemeData t, AppUser u) {
    final bool isAdmin = u.role == 'admin';
    return Column(children: [
      Text(u.fullName, 
        style: TextStyle(color: t.text, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Tajawal')),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.amber.withOpacity(0.1) : t.button.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isAdmin ? Colors.amber.withOpacity(0.3) : t.button.withOpacity(0.3))
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isAdmin ? Icons.verified_rounded : Icons.person_rounded, 
            size: 14, color: isAdmin ? Colors.amber : t.button),
          const SizedBox(width: 6),
          Text(isAdmin ? 'مشرف النظام' : 'عضو مجتمع دردشاتي', 
            style: TextStyle(color: isAdmin ? Colors.amber : t.button, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Tajawal')),
        ]),
      ),
    ]);
  }

  Widget _buildInfoCard(AppThemeData t, AppUser u) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: Column(children: [
        _detailRow(Icons.alternate_email_rounded, 'البريد الإلكتروني', u.email ?? "البريد مخفي أو غير متوفر", t),
        const Divider(height: 30, thickness: 0.5, color: Colors.white10),
        _detailRow(Icons.description_outlined, 'النبذة التعريفية', u.bio ?? 'لا توجد نبذة تعريفية لهذا المستخدم بعد.', t),
        const Divider(height: 30, thickness: 0.5, color: Colors.white10),
        _detailRow(Icons.history_toggle_off_rounded, 'الحالة الحالية', u.isOnline ? 'متصل الآن' : 'غير متصل', t, 
            valueColor: u.isOnline ? Colors.greenAccent : t.text.withOpacity(0.4)),
      ]),
    );
  }

  Widget _buildActionButtons(AppThemeData t) {
    if (_isMe) return const SizedBox.shrink(); // لا يظهر زر الرسالة في ملفي الشخصي

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () {
          // هنا يتم الربط مع شاشة الدردشة الخاصة
        },
        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
        label: const Text('إرسال رسالة خاصة', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        style: ElevatedButton.styleFrom(
          backgroundColor: t.button,
          foregroundColor: t.buttonText,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, AppThemeData t, {Color? valueColor}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 22, color: t.button.withOpacity(0.6)),
      const SizedBox(width: 15),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(label, style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 12, fontFamily: 'Tajawal')),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.right, 
            style: TextStyle(color: valueColor ?? t.text, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Tajawal')),
        ]),
      ),
    ]);
  }

  // --- نافذة الإبلاغ (Sheet) ---
  void _showReportSheet() {
    final t = widget.theme;
    final ctrl = TextEditingController();
    
    showModalBottomSheet(
      context: context, 
      backgroundColor: t.menu,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: t.text.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 25),
          Text('الإبلاغ عن مخالفة', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Tajawal')),
          const SizedBox(height: 10),
          Text('يرجى ذكر السبب لمساعدة فريق الإدارة', style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 13, fontFamily: 'Tajawal')),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: t.card.withOpacity(0.5), borderRadius: BorderRadius.circular(18)),
            child: TextField(
              controller: ctrl, 
              textAlign: TextAlign.right, 
              maxLines: 3, 
              style: TextStyle(color: t.text, fontFamily: 'Tajawal'),
              decoration: InputDecoration(
                hintText: 'اكتب سبب الإبلاغ هنا...', 
                hintStyle: TextStyle(color: t.text.withOpacity(0.2)),
                border: InputBorder.none
              )
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () async {
              final reason = ctrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              try {
                await DatabaseService.submitReport(targetId: widget.userId, reason: reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('تم إرسال البلاغ بنجاح'), backgroundColor: t.button)
                  );
                }
              } catch (e) {
                debugPrint("Report Error: $e");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, 
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 0
            ),
            child: const Text('تأكيد الإبلاغ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
          ),
        ]),
      ),
    );
  }
}
