import 'package:flutter/material.dart';
import 'dart:async';
import '../services/PouliService.dart';

class ChatPage extends StatefulWidget {
  final String? initialMessage;
  const ChatPage({super.key, this.initialMessage});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// ── Message model ─────────────────────────────────────────────────────────────
class _Message {
  final String text;
  final bool isUser;
  final String time;
  bool isAnimating;

  _Message({
    required this.text,
    required this.isUser,
    required this.time,
    this.isAnimating = false,
  });
}

class _ChatPageState extends State<ChatPage> {
  static const Color primary    = Color(0xFF19e16c);
  static const Color lightBg    = Color(0xFFf6f8f7);
  static const Color darkText   = Color(0xFF1a1a2e);
  static const Color greyText   = Color(0xFF6b7280);
  static const Color userBubble = Color(0xFF19e16c);
  static const Color aiBubble   = Colors.white;

  final PouliService _pouliService = PouliService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // API conversation history sent to PouliService
  final List<Map<String, String>> _apiHistory = [];

  // Typing animation state
  final Map<int, int> _revealedChars = {};
  final Map<int, Timer?> _typingTimers = {};

  bool _isWaiting = false; // true while waiting for API response

  List<_Message> messages = [];

  @override
  void initState() {
    super.initState();
    _sendInitialGreeting();
    // If opened from ResultsPage, auto-send the diagnosis context
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialMessage!;
        _sendMessage();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (final timer in _typingTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

  // ── Opening greeting ────────────────────────────────────────────────────────
  void _sendInitialGreeting() {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final greeting =
        "$timeGreeting! I'm PouliPal, your poultry health assistant. 🐥\n\n"
        "I can help you with questions about Salmonella, Coccidiosis, Newcastle Disease, "
        "or general Healthy Bird Management. How is your flock doing today?";

    final msg = _Message(
      text: greeting,
      isUser: false,
      time: _timeNow(),
    );

    messages.add(msg);
    final idx = messages.length - 1;
    _revealedChars[idx] = greeting.length; // no animation for greeting

    // Add to API history so AI knows it already introduced itself
    _apiHistory.add({"role": "assistant", "content": greeting});
  }

  // ── Send message ────────────────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isWaiting) return;

    final userText = _messageController.text.trim();
    _messageController.clear();

    // Add user message
    setState(() {
      _isWaiting = true;
      final userMsg =
          _Message(text: userText, isUser: true, time: _timeNow());
      messages.add(userMsg);
      final userIdx = messages.length - 1;
      _revealedChars[userIdx] = userText.length;
      _apiHistory.add({"role": "user", "content": userText});
    });

    _scrollToBottom();

    // Call PouliService
    final response = await _pouliService.sendMessage(_apiHistory);

    // Add AI response with typing animation
    setState(() {
      _isWaiting = false;
      final aiMsg = _Message(
        text: response,
        isUser: false,
        time: _timeNow(),
        isAnimating: true,
      );
      messages.add(aiMsg);
      final aiIdx = messages.length - 1;
      _revealedChars[aiIdx] = 0;
      _animateMessage(aiIdx);
      _apiHistory.add({"role": "assistant", "content": response});
    });

    _scrollToBottom();
  }

  // ── Typing animation ────────────────────────────────────────────────────────
  void _animateMessage(int index) {
    final fullText = messages[index].text;
    const int charsPerTick = 3;
    const Duration tickDuration = Duration(milliseconds: 18);

    _typingTimers[index] =
        Timer.periodic(tickDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        final current = _revealedChars[index] ?? 0;
        final next =
            (current + charsPerTick).clamp(0, fullText.length);
        _revealedChars[index] = next;
        if (next >= fullText.length) {
          messages[index].isAnimating = false;
          timer.cancel();
          _typingTimers[index] = null;
        }
      });
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _timeNow() {
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: lightBg,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: primary, width: 2),
                  ),
                  child: const Icon(Icons.smart_toy_outlined,
                      color: primary, size: 20),
                ),
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: lightBg, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PouliPal",
                  style: TextStyle(
                    color: darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Online · Poultry Health Assistant",
                  style: TextStyle(fontSize: 11, color: primary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: greyText),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(index),
            ),
          ),

          // Waiting indicator — shows while API is responding
          if (_isWaiting) _buildWaitingIndicator(),

          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Waiting dots ────────────────────────────────────────────────────────────
  Widget _buildWaitingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: aiBubble,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _ThinkingDots(),
        ),
      ),
    );
  }

  // ── Message bubble ──────────────────────────────────────────────────────────
  Widget _buildMessageBubble(int index) {
    final message = messages[index];
    final isUser = message.isUser;
    final revealed =
        _revealedChars[index] ?? message.text.length;
    final displayText = message.text.substring(0, revealed);
    final isTyping = message.isAnimating;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: Align(
        alignment:
            isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smart_toy_outlined,
                          color: primary, size: 12),
                    ),
                    const SizedBox(width: 6),
                    const Text('PouliPal',
                        style: TextStyle(
                            fontSize: 11, color: greyText)),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser ? userBubble : aiBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: isUser ? Colors.black87 : darkText,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (isTyping && !isUser) ...[
                    const SizedBox(width: 2),
                    _BlinkingCursor(),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 12, left: 4, right: 4),
              child: Text(
                message.time,
                style: const TextStyle(
                    fontSize: 10, color: greyText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: const Color(0xFFe5e7eb)),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isWaiting,
                style: const TextStyle(
                    fontSize: 14, color: darkText),
                decoration: InputDecoration(
                  hintText: _isWaiting
                      ? "PouliPal is thinking..."
                      : "Ask about your flock...",
                  hintStyle: const TextStyle(
                      color: greyText, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isWaiting ? null : _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isWaiting
                    ? greyText.withValues(alpha: 0.3)
                    : primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blinking cursor ───────────────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _controller.value,
        child: Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ── Animated thinking dots while waiting for API ──────────────────────────────
class _ThinkingDots extends StatefulWidget {
  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot bounces with a staggered delay
            final delay = i * 0.3;
            final t = (_controller.value - delay) % 1.0;
            final offset = t < 0.5
                ? -4.0 * (t / 0.5)
                : -4.0 * ((1.0 - t) / 0.5);
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF19e16c),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
