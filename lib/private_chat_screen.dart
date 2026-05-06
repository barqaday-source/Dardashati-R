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
    // تأخير بسيط للتأكد من أن الـ ListView جاهز قبل السكرول
    Future.delayed(Duration.zero, _markAsRead);
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
        // استخدام Blur خلف الـ AppBar
        flexibleSpace: ClipRect(
          child: Container(color: t.card.withOpacity(0.7)).frozen(blur: 10),
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
              stream: DatabaseService.getMessagesStream(widget.otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: t.button));
                }
                
                final messages = (snapshot.data ?? []).reversed.toList(); // عكس القائمة إذا كانت الخدمة ترسلها مرتبة قديماً
                
                // سكرول تلقائي عند وصول رسالة جديدة
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

  // ... باقي الـ Widgets (ReplyPreview, MessageBubble, InputArea) التي أرسلتها أنت سليمة جداً
  
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
      color: t.card.withOpacity(0.5),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                hintText: "اكتب رسالة...",
                hintStyle: TextStyle(color: t.text.withOpacity(0.3)),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: t.button),
            onPressed: () async {
              if (_ctrl.text.trim().isNotEmpty) {
                final text = _ctrl.text.trim();
                _ctrl.clear();
                await DatabaseService.sendMessage(widget.otherUserId, text, replyToId: _replyTo?.id);
                setState(() => _replyTo = null);
              }
            },
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
          child: widget.otherUserAvatar.isEmpty ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Text(widget.otherUserName, style: TextStyle(color: t.text, fontSize: 16, fontFamily: 'Tajawal')),
      ],
    );
  }
}
