import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PassengerChatScreen extends StatefulWidget {
  const PassengerChatScreen({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.driverName,
  });

  final String rideId;
  final String driverId;
  final String driverName;

  @override
  State<PassengerChatScreen> createState() => _PassengerChatScreenState();
}

class _PassengerChatScreenState extends State<PassengerChatScreen> {
  final List<_Message> _messages = <_Message>[];
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        _Message(sender: 'You', text: text, timestamp: DateTime.now()),
      );
    });
    _controller.clear();
    // TODO: Integrate with backend chat APIs or socket events.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.driverName,
          style: GoogleFonts.inter(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFFFC153b),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.sender == 'You';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFFC153b)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sender,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isUser ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.text,
                          style: GoogleFonts.inter(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFC153b),
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  _Message({required this.sender, required this.text, required this.timestamp});

  final String sender;
  final String text;
  final DateTime timestamp;
}
