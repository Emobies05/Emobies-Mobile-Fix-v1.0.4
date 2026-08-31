import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/cloudflare_ai_service.dart';
import '../../core/services/emokey_service.dart';
import '../../core/services/auth_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ai = CloudflareAIService();
  final _emoKey = EmoKeyService();
  final _auth = AuthService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _typing = false;
  String? _emoKeyValue;

  @override
  void initState() {
    super.initState();
    _loadEmoKey();
    _addSystemMsg('Hello! I\'m Emowall AI 🤖\nHow can I help with your mobile repair today?');
  }

  Future<void> _loadEmoKey() async {
    final stored = _auth.currentUser?.emoKey;
    if (stored != null) {
      setState(() => _emoKeyValue = stored);
    } else {
      final key = await _emoKey.generateKey(userId: _auth.currentUser?.id);
      if (key != null) setState(() => _emoKeyValue = key);
    }
  }

  void _addSystemMsg(String text) {
    setState(() {
      _messages.add({'sender': 'ai', 'text': text, 'time': DateTime.now()});
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text, 'time': DateTime.now()});
      _typing = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final reply = await _ai.chat(text, emoKey: _emoKeyValue);
      setState(() {
        _typing = false;
        _messages.add({'sender': 'ai', 'text': reply, 'time': DateTime.now()});
      });
    } catch (e) {
      setState(() {
        _typing = false;
        _messages.add({'sender': 'ai', 'text': 'Sorry, connection error. Please try again.', 'time': DateTime.now()});
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EmobiesTheme.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: EmobiesTheme.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emowall AI', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14)),
                Text('Cloudflare + Gemini', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: EmobiesTheme.muted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined, color: EmobiesTheme.text2),
            onPressed: () => setState(() {
              _messages.clear();
              _addSystemMsg('Chat cleared. How can I help?');
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessage(_messages[i]),
            ),
          ),
          if (_typing)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: EmobiesTheme.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dot(0),
                        _dot(1),
                        _dot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _dot(int i) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: EmobiesTheme.purple.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? EmobiesTheme.orange.withOpacity(0.15) : EmobiesTheme.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: Border.all(
            color: isUser ? EmobiesTheme.orange.withOpacity(0.2) : EmobiesTheme.border,
          ),
        ),
        child: Text(
          msg['text'] ?? '',
          style: TextStyle(
            color: isUser ? EmobiesTheme.text : EmobiesTheme.text2,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: EmobiesTheme.surface,
        border: const Border(top: BorderSide(color: EmobiesTheme.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: EmobiesTheme.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask Emowall AI...',
                  filled: true,
                  fillColor: EmobiesTheme.bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: EmobiesTheme.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}