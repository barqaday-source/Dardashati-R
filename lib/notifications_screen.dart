import 'package:flutter/material.dart';
import 'package:dardashati/models.dart';
import 'package:dardashati/app_theme.dart';
import 'package:dardashati/services/database_service.dart';

class PrivateChatScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppUser otherUser;
  final AppThemeData theme;

  const PrivateChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
    required this.theme,
  });

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  // تحديث حالة الرسائل كمقروءة عند الدخول
  void _markRead() {
    DatabaseService.markPrivateMessagesRead(widget.otherUser.id);
  }

  void _onSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await DatabaseService.sendMessage(widget.otherUser.id, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("فشل إرسال الرسالة")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        title: Text(widget.otherUser.fullName, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: t.card,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AppMessage>>(
              // استدعاء دالة البث الجديدة
              stream: DatabaseService.getMessagesStream(widget.otherUser.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == widget.currentUser.id;
                    return _buildBubble(msg, isMe, t);
                  },
                );
              },
            ),
          ),
          _buildInput(t),
        ],
      ),
    );
  }

  Widget _buildBubble(AppMessage msg, bool isMe, AppThemeData t) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? t.button : t.card,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(msg.content, style: TextStyle(color: isMe ? t.buttonText : t.text)),
      ),
    );
  }

  Widget _buildInput(AppThemeData t) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: t.card,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: t.text),
              decoration: const InputDecoration(hintText: "اكتب رسالة...", border: InputBorder.none),
            ),
          ),
          IconButton(onPressed: _onSend, icon: Icon(Icons.send, color: t.button)),
        ],
      ),
    );
  }
}
