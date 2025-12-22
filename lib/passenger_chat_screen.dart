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
<<<<<<< HEAD
    // TODO: Integrate with backend chat APIs or socket events.
=======
>>>>>>> origin/Shayan
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
=======
    // Get screen dimensions using MediaQuery
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Calculate responsive values
    final double horizontalPadding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final double verticalPadding = (screenHeight * 0.02).clamp(12.0, 20.0);
    final double messagePadding = (screenWidth * 0.035).clamp(12.0, 18.0);
    final double messageVerticalPadding = (screenHeight * 0.012).clamp(8.0, 14.0);
    final double messageMargin = (screenHeight * 0.005).clamp(3.0, 6.0);
    final double borderRadius = (screenWidth * 0.03).clamp(10.0, 16.0);
    final double fontSizeSender = (screenWidth * 0.030).clamp(11.0, 14.0);
    final double fontSizeMessage = (screenWidth * 0.038).clamp(14.0, 16.0);
    final double inputPadding = (screenWidth * 0.04).clamp(12.0, 18.0);
    final double inputVerticalPadding = (screenHeight * 0.015).clamp(10.0, 14.0);
    final double spacingBetween = (screenWidth * 0.03).clamp(10.0, 16.0);
    final double iconSize = (screenWidth * 0.06).clamp(20.0, 28.0);
    final double appBarFontSize = (screenWidth * 0.042).clamp(18.0, 20.0);

>>>>>>> origin/Shayan
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.driverName,
<<<<<<< HEAD
          style: GoogleFonts.inter(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFFFC153b),
=======
          style: GoogleFonts.inter(
            fontSize: appBarFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFC153b),
        foregroundColor: Colors.white,
>>>>>>> origin/Shayan
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
<<<<<<< HEAD
              padding: const EdgeInsets.all(16),
=======
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
>>>>>>> origin/Shayan
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.sender == 'You';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
<<<<<<< HEAD
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
=======
                    margin: EdgeInsets.symmetric(vertical: messageMargin),
                    padding: EdgeInsets.symmetric(
                      horizontal: messagePadding,
                      vertical: messageVerticalPadding,
>>>>>>> origin/Shayan
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFFFC153b)
                          : Colors.grey.shade200,
<<<<<<< HEAD
                      borderRadius: BorderRadius.circular(12),
=======
                      borderRadius: BorderRadius.circular(borderRadius),
>>>>>>> origin/Shayan
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sender,
                          style: GoogleFonts.inter(
<<<<<<< HEAD
                            fontSize: 12,
                            color: isUser ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.text,
                          style: GoogleFonts.inter(
=======
                            fontSize: fontSizeSender,
                            color: isUser ? Colors.white70 : Colors.grey,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          message.text,
                          style: GoogleFonts.inter(
                            fontSize: fontSizeMessage,
>>>>>>> origin/Shayan
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
<<<<<<< HEAD
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
=======
            padding: EdgeInsets.symmetric(
              horizontal: inputPadding,
              vertical: inputVerticalPadding,
            ),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(fontSize: fontSizeMessage),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: GoogleFonts.inter(
                          fontSize: fontSizeMessage,
                          color: Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: inputPadding * 0.6,
                          vertical: inputVerticalPadding,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: spacingBetween),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC153b),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(spacingBetween * 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child: Icon(Icons.send, size: iconSize * 0.7),
                  ),
                ],
              ),
>>>>>>> origin/Shayan
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
