import 'package:flutter/material.dart';
import 'package:blur/blur.dart'; 
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
        // إصلاح منطق الـ Blur ليعمل مع المكتبة دون أخطاء
        flexibleSpace: ClipRect(
          child: Container(color: t.menu.withOpacity(0.7)).frozen(blur: 10),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildAppBarTitle(t),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService.getMessagesStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  final newMessages = snapshot.data!
                      .map((m) => AppMessage.fromMap(m))
                      .toList();
                  
                  // التمرير للأسفل تلقائياً عند وصول رسالة جديدة
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(15),
                    itemCount: newMessages.length,
                    itemBuilder: (ctx, i) => _buildMessageBubble(newMessages[i], t),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          if (_replyTo != null) _buildReplyPreview(t), // استدعاء دالة المعاينة التي كانت مفقودة
          _buildInputArea(t),
        ],
      ),
    );
  }

  // دالة معاينة الرد (إصلاح الخطأ undefined_method)
  Widget _buildReplyPreview(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: t.card.withOpacity(0.5),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_replyTo!.content, maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _replyTo = null)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AppMessage msg, AppThemeData t) {
    final isMe = msg.senderId == widget.currentUser.id;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => setState(() => _replyTo = msg), // ميزة الرد عند الضغط المطول
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? t.button : t.card.withOpacity(0.8),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 5),
              bottomRight: Radius.circular(isMe ? 5 : 20),
            ),
          ),
          child: Text(
            msg.content,
            style: TextStyle(color: isMe ? t.buttonText : t.text, fontSize: 15, fontFamily: 'Tajawal'),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(AppThemeData t) {
    return ClipRect(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: t.menu.withOpacity(0.8)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: t.text),
                decoration: InputDecoration(
                  hintText: "اكتب رسالة...",
                  hintStyle: TextStyle(color: t.text.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            CircleAvatar(
              backgroundColor: t.button,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () async {
                  if (_ctrl.text.isNotEmpty) {
                    final content = _ctrl.text;
                    _ctrl.clear();
                    final rId = _replyTo?.id;
                    setState(() => _replyTo = null);
                    await DatabaseService.sendMessage(widget.otherUserId, content, replyToId: rId);
                  }
                },
              ),
            ),
          ],
        ),
      ).frozen(blur: 15),
    );
  }

  Widget _buildAppBarTitle(AppThemeData t) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: widget.otherUserAvatar.isNotEmpty ? NetworkImage(widget.otherUserAvatar) : null,
          radius: 18,
          child: widget.otherUserAvatar.isEmpty ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserName, style: TextStyle(color: t.text, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("متصل الآن", style: TextStyle(color: Colors.green, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
