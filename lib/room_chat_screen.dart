import 'package:dardashati/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/services/database_service.dart';
import 'package:dardashati/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد ضروري للتعامل مع القناة

class RoomChatScreen extends StatefulWidget {
  final AppRoom room;
  final AppUser currentUser;
  final AppThemeData theme;

  const RoomChatScreen({
    super.key, 
    required this.room, 
    required this.currentUser, 
    required this.theme
  });

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<AppMessage> _messages = []; // تخزين الرسائل محلياً
  RealtimeChannel? _roomChannel; // تعريف القناة
  AppMessage? _replyTo;
  bool _sending = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    // 1. الانضمام للغرفة
    DatabaseService.joinRoom(widget.room.id);

    // 2. الاشتراك في القناة الحية (Realtime) لتوافق التعديل الجديد
    // نمرر الـ ID ووظيفة تحديث البيانات التي تستقبل قائمة الرسائل
    _roomChannel = DatabaseService.subscribeToRoomMessages(
      widget.room.id, 
      (updatedMessages) {
        if (mounted) {
          setState(() {
            _messages = updatedMessages;
            _loading = false;
          });
          _scrollToBottom();
        }
      }
    );
  }

  @override
  void dispose() {
    _roomChannel?.unsubscribe(); // إلغاء الاشتراك عند الخروج
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeOut
      );
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final replyId = _replyTo?.id;
    _ctrl.clear();
    setState(() => _replyTo = null);

    try {
      await DatabaseService.sendRoomMessage(
        roomId: widget.room.id, 
        content: text, 
        replyToId: replyId
      );
      _scrollToBottom();
    } catch (e) {
      debugPrint("Send error: $e");
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: _buildAppBar(t),
      body: Column(children: [
        Expanded(
          child: _loading 
            ? Center(child: CircularProgressIndicator(color: t.button))
            : ListView.builder(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i], t),
              ),
        ),
        if (_replyTo != null) _buildReplyBar(t),
        _buildInputBar(t),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar(AppThemeData t) {
    return AppBar(
      backgroundColor: t.menu,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20),
        onPressed: () => Navigator.pop(context)
      ),
      title: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: t.button.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Icon(widget.room.icon, color: t.button, size: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.room.name, style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Tajawal')),
            // تغيير المسمى من عدد الأعضاء إلى "أعضاء الغرفة"
            Text('أعضاء الغرفة', style: TextStyle(color: t.text.withOpacity(0.4), fontSize: 11)),
          ]),
        ),
      ]),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline_rounded, color: t.text.withOpacity(0.6)),
          onPressed: () => _showMembers(context, t)
        )
      ],
    );
  }

  // ... [بقية الدوال _buildMessageBubble و _buildAvatar و غيرها تبقى كما هي في كودك]
  // تم اختصارها هنا لسهولة القراءة، لكنها تعمل مع قائمة _messages الجديدة

  Widget _buildMessageBubble(AppMessage msg, AppThemeData t) {
    final isMe = msg.senderId == widget.currentUser.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(msg, t),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, right: 4),
                    child: Text(msg.senderName ?? "مجهول", style: TextStyle(color: t.button, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                GestureDetector(
                  onLongPress: () => setState(() => _replyTo = msg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? t.button : t.card.withOpacity(0.5),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (msg.replyToContent != null) _buildReplyInBubble(msg, isMe, t),
                        Text(msg.content ?? "", style: TextStyle(color: isMe ? t.buttonText : t.text, fontSize: 14.5, height: 1.4)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text(msg.formattedTime, style: TextStyle(color: t.text.withOpacity(0.3), fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppMessage msg, AppThemeData t) {
    final String avatar = msg.senderAvatar ?? "";
    final String name = msg.senderName ?? "?";
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: msg.senderId, currentUserId: widget.currentUser.id, theme: t))),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: t.button.withOpacity(0.1),
        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
        child: avatar.isEmpty ? Text(name.isNotEmpty ? name[0] : "?", style: TextStyle(color: t.button, fontSize: 12)) : null,
      ),
    );
  }

  Widget _buildReplyInBubble(AppMessage msg, bool isMe, AppThemeData t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isMe ? Colors.black : t.button).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border(right: BorderSide(color: isMe ? Colors.white70 : t.button, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(msg.replyToSender ?? "مستخدم", style: TextStyle(color: isMe ? Colors.white : t.button, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(msg.replyToContent ?? "", style: TextStyle(color: (isMe ? Colors.white : t.text).withOpacity(0.6), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildReplyBar(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: t.menu, border: Border(top: BorderSide(color: t.text.withOpacity(0.05)))),
      child: Row(children: [
        Container(width: 4, height: 35, decoration: BoxDecoration(color: t.button, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('رداً على ${_replyTo?.senderName ?? ""}', style: TextStyle(color: t.button, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(_replyTo?.content ?? "", style: TextStyle(color: t.text.withOpacity(0.5), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        IconButton(icon: Icon(Icons.close_rounded, color: t.text.withOpacity(0.3), size: 20), onPressed: () => setState(() => _replyTo = null)),
      ]),
    );
  }

  Widget _buildInputBar(AppThemeData t) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: t.menu, border: Border(top: BorderSide(color: t.text.withOpacity(0.05)))),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: t.card.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 4, minLines: 1,
              style: TextStyle(color: t.text, fontSize: 15),
              textAlign: TextAlign.right,
              decoration: InputDecoration(hintText: 'اكتب رسالة...', hintStyle: TextStyle(color: t.text.withOpacity(0.2)), border: InputBorder.none),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: t.button, shape: BoxShape.circle),
            child: _sending 
              ? const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
              : Icon(Icons.send_rounded, color: t.buttonText, size: 22),
          ),
        ),
      ]),
    );
  }

  void _showMembers(BuildContext context, AppThemeData t) async {
    final List<AppUser> members = await DatabaseService.getRoomMembers(widget.room.id).catchError((_) => <AppUser>[]);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, backgroundColor: t.menu,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: t.text.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Text('المتواجدون في الغرفة', style: TextStyle(color: t.text, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Tajawal')),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (ctx, i) {
                final u = members[i];
                return ListTile(
                  trailing: CircleAvatar(
                    backgroundImage: u.avatarUrl.isNotEmpty ? NetworkImage(u.avatarUrl) : null,
                    child: u.avatarUrl.isEmpty ? Text(u.fullName.isNotEmpty ? u.fullName[0] : "?") : null,
                  ),
                  title: Text(u.fullName, textAlign: TextAlign.right, style: TextStyle(color: t.text, fontWeight: FontWeight.bold)),
                  subtitle: Text(u.isOnline ? 'نشط' : 'بعيد', textAlign: TextAlign.right, style: TextStyle(color: u.isOnline ? Colors.greenAccent : t.text.withOpacity(0.3))),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
