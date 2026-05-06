import 'package:flutter/material.dart';
import 'package:dardashati/models.dart'; 
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:image_picker/image_picker.dart'; // تأكد من إضافة هذه المكتبة
import 'dart:io';

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
  bool _isUploading = false; // لمتابعة حالة رفع الصورة
  
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

  // --- ميزة رفع الصور الجديدة ---
  Future<void> _pickAndUploadImage() async {
    if (!_isMe) return; // حماية إضافية

    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() => _isUploading = true);

        // استخدام المحرك الذي جهزناه في DatabaseService
        await DatabaseService.updateAvatar(File(image.path));

        // إعادة تحميل البيانات لتظهر الصورة الجديدة فوراً
        await _loadProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث صورتك الشخصية بنجاح ✅')),
          );
        }
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل رفع الصورة، حاول مجدداً')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    
    if (_loading) {
      return Scaffold(
        backgroundColor: t.background, 
        body: Center(child: CircularProgressIndicator(color: t.button))
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: t.background, 
        body: Center(child: Text('المستخدم غير موجود', style: TextStyle(color: t.text)))) ;
    }

    final u = _user!;

    return Scaffold(
      backgroundColor: t.background,
      appBar: _buildAppBar(t),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          const SizedBox(height: 20),
          _buildAvatarSection(t, u), // القسم المعدل
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

  Widget _buildAvatarSection(AppThemeData t, AppUser u) {
    final String imageUrl = u.avatarUrl ?? "";
    final String firstLetter = u.fullName.isNotEmpty ? u.fullName[0] : "?";

    return GestureDetector(
      onTap: _isMe ? _pickAndUploadImage : null, // الضغط لتغيير الصورة فقط إذا كان حسابي
      child: Stack(alignment: Alignment.center, children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle, 
            border: Border.all(color: _isMe ? t.button.withOpacity(0.5) : t.button.withOpacity(0.2), width: 2)
          ),
          child: CircleAvatar(
            radius: 65, // حجم أكبر قليلاً ليبرز البروفايل
            backgroundColor: t.card,
            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: _isUploading 
              ? CircularProgressIndicator(color: t.button)
              : (imageUrl.isEmpty 
                  ? Text(firstLetter, style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: t.button)) 
                  : null),
          ),
        ),
        // أيقونة الكاميرا تظهر فقط في بروفايل المستخدم الحالي
        if (_isMe)
          Positioned(
            bottom: 5, right: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: t.button, 
                shape: BoxShape.circle, 
                border: Border.all(color: t.background, width: 3)
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ),
        // نقطة الاتصال تظهر للآخرين فقط (اختياري)
        if (!u.isOnline && !_isMe)
          Positioned(
            bottom: 8, right: 8,
            child: Container(
              width: 18, height: 18, 
              decoration: BoxDecoration(
                color: Colors.greenAccent, 
                shape: BoxShape.circle, 
                border: Border.all(color: t.background, width: 3)
              )
            ),
          ),
      ]),
    );
  }

  // ... باقي الدوال (Appbar, InfoCard, الخ) تبقى كما هي في كودك الأصلي ...
  // [أبقي على بقية الدوال التي أرسلتها لي دون تغيير]
  
  PreferredSizeWidget _buildAppBar(AppThemeData t) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
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

  Widget _buildNameAndRole(AppThemeData t, AppUser u) {
    final bool isAdmin = u.role == 'admin';
    return Column(children: [
      Text(u.fullName, style: TextStyle(color: t.text, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Tajawal')),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isAdmin ? Colors.amber.withOpacity(0.1) : t.button.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(isAdmin ? 'مشرف النظام' : 'عضو مجتمع دردشاتي', 
          style: TextStyle(color: isAdmin ? Colors.amber : t.button, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Tajawal')),
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
      ),
      child: Column(children: [
        _detailRow(Icons.alternate_email_rounded, 'البريد الإلكتروني', u.email ?? "غير متوفر", t),
        const Divider(height: 30, thickness: 0.5, color: Colors.white10),
        _detailRow(Icons.history_toggle_off_rounded, 'الحالة الحالية', u.isOnline ? 'متصل الآن' : 'غير متصل', t, 
            valueColor: u.isOnline ? Colors.greenAccent : t.text.withOpacity(0.4)),
      ]),
    );
  }

  Widget _buildActionButtons(AppThemeData t) {
    if (_isMe) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.chat_bubble_rounded, size: 18),
        label: const Text('إرسال رسالة خاصة', style: TextStyle(fontFamily: 'Tajawal')),
        style: ElevatedButton.styleFrom(
          backgroundColor: t.button,
          foregroundColor: t.buttonText,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, AppThemeData t, {Color? valueColor}) {
    return Row(children: [
      Icon(icon, size: 22, color: t.button.withOpacity(0.6)),
      const SizedBox(width: 15),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(label, style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
          Text(value, style: TextStyle(color: valueColor ?? t.text, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    ]);
  }

  void _showReportSheet() {
    // [كود نافذة الإبلاغ كما هو في رسالتك السابقة]
  }
}

