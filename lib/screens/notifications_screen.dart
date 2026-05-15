import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFC153B),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text("Please log in to see notifications."))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFC153B)));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading notifications."));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] as String? ?? 'Notification';
                    final body = data['body'] as String? ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final isRead = data['isRead'] as bool? ?? false;
                    
                    // Mark as read if it's unread
                    if (!isRead) {
                      docs[index].reference.update({'isRead': true});
                    }

                    return _buildNotificationTile(
                      title: title,
                      body: body,
                      timestamp: timestamp?.toDate(),
                      isRead: isRead,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFC153B).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Color(0xFFFC153B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Notifications Yet",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When you get updates about your rides,\nthey will show up here.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String body,
    DateTime? timestamp,
    required bool isRead,
  }) {
    IconData iconData = Icons.notifications;
    Color iconColor = const Color(0xFFFC153B);
    
    // Simple logic to change icon based on title keywords
    if (title.toLowerCase().contains('payment') || title.toLowerCase().contains('receipt')) {
      iconData = Icons.receipt_long;
      iconColor = Colors.green;
    } else if (title.toLowerCase().contains('driver') || title.toLowerCase().contains('ride')) {
      iconData = Icons.directions_car;
      iconColor = Colors.blue;
    } else if (title.toLowerCase().contains('promo') || title.toLowerCase().contains('discount')) {
      iconData = Icons.local_offer;
      iconColor = Colors.orange;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      _formatTimestamp(timestamp),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isRead ? Colors.grey[600] : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return '1d';
    return '${dt.day}/${dt.month}';
  }
}
