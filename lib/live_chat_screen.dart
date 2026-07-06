import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:musafirah_app/services/chat_service.dart';

const _kRed = Color(0xFFFC153b);

class LiveChatScreen extends StatefulWidget {
  final String rideId;
  final String peerId;
  final String peerName;
  final String peerImageUrl;
  final String myName;
  final String myImageUrl;
  final bool isDriver; // True if the current user is the driver

  const LiveChatScreen({
    super.key,
    required this.rideId,
    required this.peerId,
    required this.peerName,
    this.peerImageUrl = '',
    this.myName = '',
    this.myImageUrl = '',
    required this.isDriver,
  });

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;

  String _currentMyName = '';
  String _currentMyImageUrl = '';

  String get _myId => FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

  late final List<String> _quickReplies;

  @override
  void initState() {
    super.initState();
    _currentMyName = widget.myName;
    _currentMyImageUrl = widget.myImageUrl;

    _loadMyProfile();

    _quickReplies = widget.isDriver
        ? [
            'I\'m here!',
            'Please come out',
            'I am stuck in traffic',
            'On my way!',
          ]
        : [
            'On my way!',
            'Please wait 2 mins',
            'I\'m at the gate',
            'Almost there!',
          ];

    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  Future<void> _loadMyProfile() async {
    final bool isPlaceholder = _currentMyName.isEmpty || 
                               _currentMyName == 'Customer' || 
                               _currentMyName == 'You' || 
                               _currentMyName == 'unknown_user';
    
    if (!isPlaceholder && _currentMyImageUrl.isNotEmpty) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection(widget.isDriver ? 'Drivers' : 'Passengers')
          .doc(uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          if (_currentMyName.isEmpty) {
            _currentMyName = doc.data()?['name'] ?? 'You';
          }
          if (_currentMyImageUrl.isEmpty) {
            _currentMyImageUrl = doc.data()?['profileImageUrl'] ?? '';
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading my profile: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = (quickText ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ChatService.sendMessage(
      rideId: widget.rideId,
      senderId: _myId,
      senderName: _currentMyName.isNotEmpty ? _currentMyName : (FirebaseAuth.instance.currentUser?.displayName ?? 'You'),
      text: text,
      isDriver: widget.isDriver,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(Timestamp? ts) {
    final dt = ts?.toDate() ?? DateTime.now();
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ChatService.messagesStream(widget.rideId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: _kRed));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return _buildEmptyState();

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final isUser = data['senderId'] == _myId;
                    return _buildBubble(
                      text: data['text'] ?? '',
                      isUser: isUser,
                      senderName: data['senderName'] ?? '',
                      timestamp: data['timestamp'] as Timestamp?,
                    );
                  },
                );
              },
            ),
          ),
          _buildQuickReplies(),
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(double size, String imageUrl, String name, {bool isPeer = true}) {
    Widget inner;
    if (imageUrl.startsWith('data:image')) {
      try {
        final Uint8List bytes = base64Decode(imageUrl.split(',').last);
        inner = Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
      } catch (_) {
        inner = _initialsAvatar(size, name, isPeer);
      }
    } else if (imageUrl.isNotEmpty) {
      inner = Image.network(imageUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _initialsAvatar(size, name, isPeer));
    } else {
      inner = _initialsAvatar(size, name, isPeer);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPeer ? _kRed.withValues(alpha: 0.1) : const Color(0xFFEFF0F2),
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _initialsAvatar(double size, String name, bool isPeer) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.outfit(
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
          color: isPeer ? _kRed : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: 12,
        left: 8,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
            color: const Color(0xFF0F172A),
          ),
          _buildAvatar(40, widget.peerImageUrl, widget.peerName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFF0F172A))),
                Row(
                  children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(widget.isDriver ? 'Active · Waiting for you' : 'Active · On the way',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: _kRed, size: 32),
          ),
          const SizedBox(height: 16),
          Text('Start the conversation',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          Text('Chat with your ${widget.isDriver ? 'passenger' : 'driver'} about pickup details',
              style:
                  GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBubble({
    required String text,
    required bool isUser,
    required String senderName,
    required Timestamp? timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(30, widget.peerImageUrl, widget.peerName),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context).size.width * 0.68),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? _kRed : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(text,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isUser
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        height: 1.4)),
              ),
              const SizedBox(height: 4),
              Text(_formatTime(timestamp),
                  style: GoogleFonts.outfit(
                      fontSize: 10, color: Colors.grey[400])),
            ],
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(30, _currentMyImageUrl, _currentMyName, isPeer: false),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 44,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _sendMessage(_quickReplies[i]),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(_quickReplies[i],
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155))),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.outfit(
                    fontSize: 14, color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Message your ${widget.isDriver ? 'passenger' : 'driver'}…',
                  hintStyle: GoogleFonts.outfit(
                      fontSize: 14, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _hasText ? _kRed : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send_rounded,
                  color: _hasText ? Colors.white : Colors.grey[400],
                  size: 20),
              onPressed: _hasText ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }
}
