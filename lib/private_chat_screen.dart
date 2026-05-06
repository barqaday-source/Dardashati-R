import 'package:flutter/material.dart';
import 'package:blur/blur.dart'; 
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/models.dart'; 
import 'package:dardashati/services/database_service.dart';

class PrivateChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final AppUser currentUser;
  final AppThemeData theme;

  const PrivateChatScreen({
    super.key, 
    required this.otherUserId, 
    required this.otherUserName, 
    required this.otherUserAvatar, 
    required this.currentUser, 
    required this.theme
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  AppMessage? _replyTo;

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  // استخدام الخدمة المحدثة لتمييز الرسائل كمقروءة
  void _markAsRead() {
    DatabaseService.markPrivateMessagesRead(widget.otherUserId);
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: Container(color: t.menu.withOpacity(0.7)).frozen(blur: 10),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildAppBarTitle(t),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AppMessage>>(
              // تحديث البث ليستخدم الموديل AppMessage مباشرة
              stream: DatabaseService.getMessagesStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: t.button));
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) => _buildMessageBubble(messages[i], t),
                );
              },
            ),
          ),
          if (_replyTo != null) _buildReplyPreview(t),
          _buildInputArea(t),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.9),
        border: Border(top: BorderSide(color: t.button.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, size: 20, color: t.button),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _replyTo!.content, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: t.text.withOpacity(0.7), fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: t.text), 
            onPressed: () => setState(() => _replyTo = null)
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AppMessage msg, AppThemeData t) {
    final isMe = msg.senderId == widget.currentUser.id;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => setState(() => _replyTo = msg),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? t.button : t.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
            ],
          ),
          child: Text(
            msg.content,
            style: TextStyle(color: isMe ? t.buttonText : t.text, fontSize: 14, fontFamily: 'Tajawal'),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 25),
      decoration: BoxDecoration(
        color: t.card.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: t.background.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: t.text),
                decoration: InputDecoration(
                  hintText: "اكتب رسالة...",
                  hintStyle: TextStyle(color: t.text.withOpacity(0.3), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              if (_ctrl.text.trim().isNotEmpty) {
                final content = _ctrl.text.trim();
                _ctrl.clear();
                final rId = _replyTo?.id;
                setState(() => _replyTo = null);
                // استخدام دالة الإرسال المحدثة في DatabaseService
                await DatabaseService.sendMessage(widget.otherUserId, content, replyToId: rId);
              }
            },
            child: CircleAvatar(
              backgroundColor: t.button,
              radius: 22,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    ).frozen(blur: 15);
  }

  Widget _buildAppBarTitle(AppThemeData t) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: widget.otherUserAvatar.isNotEmpty ? NetworkImage(widget.otherUserAvatar) : null,
          radius: 18,
          backgroundColor: t.button.withOpacity(0.1),
          child: widget.otherUserAvatar.isEmpty ? Icon(Icons.person, color: t.button) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, 
              style: TextStyle(color: t.text, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            const Text("نشط الآن", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
