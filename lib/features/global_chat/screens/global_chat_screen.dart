import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_message_model.dart';
import 'chat_login_screen.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatEntry extends StatelessWidget {
  const ChatEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            ),
          );
        }
        if (snapshot.data == null) return const ChatLoginScreen();
        return const GlobalChatScreen();
      },
    );
  }
}

class GlobalChatScreen extends StatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  State<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends State<GlobalChatScreen> {
  final _controller = ChatController();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _sending = false;
  int _prevMsgCount = 0;
  int _wordCount = 0;
  static const int _maxWords = 200;

  // Cached once so typing (setState via _onTextChanged) doesn't create a
  // brand-new Firestore stream subscription on every keystroke, which was
  // causing the message list to flicker/reload while typing.
  late final Stream<List<ChatMessageModel>> _messagesStream =
      _controller.messagesStream();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    final error = await _controller.sendMessage(text);

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      _textCtrl.clear();
      setState(() => _wordCount = 0);
      _scrollToBottom();
    }

    setState(() => _sending = false);
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Logout?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.purple),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await _controller.signOut();
  }

  void _onTextChanged(String value) {
    final words = value.trim().isEmpty
        ? 0
        : value.trim().split(RegExp(r'\s+')).length;
    setState(() => _wordCount = words);
  }

  Future<void> _showMessageOptions(
    BuildContext context,
    ChatMessageModel msg,
  ) async {
    final myUid = _controller.currentUser?.uid;
    final isMe = msg.uid == myUid;
    final alreadyReported = myUid != null && msg.reportedBy.contains(myUid);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.copy_rounded,
                color: AppColors.blue,
                size: 22,
              ),
              title: const Text(
                'Copy',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied!'),
                    backgroundColor: AppColors.purple.withOpacity(0.9),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent, fontSize: 15),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _confirmDelete(msg);
                },
              )
            else
              ListTile(
                leading: Icon(
                  Icons.flag_outlined,
                  color: alreadyReported ? Colors.white24 : Colors.orangeAccent,
                  size: 22,
                ),
                title: Text(
                  alreadyReported ? 'Reported' : 'Report',
                  style: TextStyle(
                    color: alreadyReported
                        ? Colors.white24
                        : Colors.orangeAccent,
                    fontSize: 15,
                  ),
                ),
                onTap: alreadyReported
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _confirmReport(msg);
                      },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReport(ChatMessageModel msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Report this message?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Reporting a message will notify the moderators. It may be automatically deleted.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Report',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final myUid = _controller.currentUser?.uid;
      if (myUid == null) return;
      final error = await _controller.reportMessage(msg.id, myUid);
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reported successfully.'),
            backgroundColor: AppColors.purple.withOpacity(0.9),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(ChatMessageModel msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Delete this message?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'This message will be deleted forever.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _controller.deleteMessage(msg.id);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _controller.currentUser;
    final name = user?.displayName ?? user?.email ?? 'User';
    final myInitials = _controller.initials(name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(name, myInitials),
            Expanded(
              child: StreamBuilder<List<ChatMessageModel>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.purple),
                    );
                  }
                  final msgs = snapshot.data ?? [];
                  if (msgs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet.\nBe the first to say hello!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    );
                  }

                  if (msgs.length != _prevMsgCount) {
                    _prevMsgCount = msgs.length;
                    _scrollToBottom();
                  }

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final msg = msgs[i];
                      final isMe = msg.uid == user?.uid;
                      return _buildBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String name, String initials) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: const Text(
                'Global Chat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _signOut,
            child: Builder(
              builder: (_) {
                final bgColor = AppColors.avatarColorFor(name);
                final textColor = AppColors.avatarTextColorFor(bgColor);
                return Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _avatarWidget(msg.initials, msg.name),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      msg.name,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context, msg),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.purple : AppColors.card,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                    ),
                    child: _buildMessageText(msg.text, isMe),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _avatarWidget(msg.initials, msg.name),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageText(String text, bool isMe) {
    final urlRegex = RegExp(r'(https?://[^\s]+)', caseSensitive: false);

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in urlRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        );
      }

      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: isMe ? Colors.white : AppColors.blue,
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: isMe ? Colors.white70 : AppColors.blue,
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Future<void> _launchUrl(String url) async {
    // Opening via platform channel instead of url_launcher
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Widget _avatarWidget(String initials, String name) {
    final bgColor = AppColors.avatarColorFor(name);
    final textColor = AppColors.avatarTextColorFor(bgColor);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final isOverLimit = _wordCount > _maxWords;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_wordCount > 150)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 4),
              child: Text(
                '$_wordCount / $_maxWords words',
                style: TextStyle(
                  fontSize: 11,
                  color: isOverLimit ? Colors.redAccent : Colors.white38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(26),
                    border: isOverLimit
                        ? Border.all(color: Colors.redAccent.withOpacity(0.6))
                        : null,
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: isOverLimit ? null : _send,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isOverLimit ? null : AppColors.primaryGradient,
                    color: isOverLimit ? Colors.white12 : null,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: isOverLimit ? Colors.white24 : Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
