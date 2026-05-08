import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/PouliService.dart'; // Ensure your service file is named correctly
import '../models/message_model.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final PouliService _pouliService = PouliService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // _apiHistory stores the raw roles for the AI (limit 10 in service)
  final List<Map<String, String>> _apiHistory = [];
  // _displayMessages stores the UI models
  final List<Message> _displayMessages = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with the dynamic greeting
    _sendInitialGreeting();
  }

  // 1. Generate a dynamic greeting based on time of day
  void _sendInitialGreeting() {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = "Good morning";
    } else if (hour < 17) {
      timeGreeting = "Good afternoon";
    } else {
      timeGreeting = "Good evening";
    }

    final String introText =
        "$timeGreeting! I am PouliPal, your poultry health friend. 🐥\n\n"
        "I can help you with questions about **Salmonella, Coccidiosis, Newcastle Disease**, or general **Healthy Bird Management**. "
        "How is your flock doing today?";

    setState(() {
      _displayMessages.insert(0,
          Message(text: introText, isUser: false, timestamp: DateTime.now()));
      // Add to history so AI knows it introduced itself
      _apiHistory.add({"role": "assistant", "content": introText});
    });
  }

  // 2. The main send logic
  void _handleSend() async {
    // Prevent sending if empty or if already waiting for a response
    if (_controller.text.trim().isEmpty || _isLoading) return;

    final userText = _controller.text.trim();

    setState(() {
      _isLoading = true;
      _displayMessages.insert(
          0, Message(text: userText, isUser: true, timestamp: DateTime.now()));
      _apiHistory.add({"role": "user", "content": userText});
    });

    _controller.clear();

    // Call the service (which handles the rate limiting and 429 errors)
    final response = await _pouliService.sendMessage(_apiHistory);

    setState(() {
      _isLoading = false;
      _displayMessages.insert(
          0, Message(text: response, isUser: false, timestamp: DateTime.now()));
      _apiHistory.add({"role": "assistant", "content": response});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "🐥 PouliPal Assistant",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Chat Window
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Newest messages at the bottom
              padding: const EdgeInsets.all(15),
              itemCount: _displayMessages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_displayMessages[index]);
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(
                color: Colors.orangeAccent,
                backgroundColor: Colors.transparent,
              ),
            ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    bool isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.orangeAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: MarkdownBody(
          data: msg.text,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.4,
            ),
            strong: TextStyle(
              color: isUser ? Colors.white : Colors.orange[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(), // Enter key support
                decoration: const InputDecoration(
                  hintText: "Type a message...",
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send Button
          GestureDetector(
            onTap: _isLoading ? null : _handleSend,
            child: CircleAvatar(
              radius: 25,
              backgroundColor: _isLoading ? Colors.grey : Colors.orangeAccent,
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
