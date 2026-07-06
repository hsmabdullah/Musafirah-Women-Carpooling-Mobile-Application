import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore structure
/// Chats/{rideId}/Messages/{messageId}
///   senderId   : String
///   senderName : String
///   text       : String
///   timestamp  : Timestamp
///   isDriver   : bool
class ChatService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _msgs(String rideId) =>
      _db.collection('Chats').doc(rideId).collection('Messages');

  /// Stream of messages for a ride, ordered by time ascending.
  static Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(
          String rideId) =>
      _msgs(rideId)
          .orderBy('timestamp', descending: false)
          .snapshots();

  /// Send a message.
  static Future<void> sendMessage({
    required String rideId,
    required String senderId,
    required String senderName,
    required String text,
    bool isDriver = false,
  }) async {
    await _msgs(rideId).add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isDriver': isDriver,
    });
  }
}
