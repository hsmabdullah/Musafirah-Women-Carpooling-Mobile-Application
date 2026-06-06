import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles FCM token registration, foreground notification display,
/// and in-app local notifications.
///
/// Call [NotificationService.init] once from main() after Firebase.initializeApp().
/// Call [NotificationService.saveTokenForCurrentUser] after every login.
class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId = 'musafirah_channel';
  static const _channelName = 'Musafirah Notifications';

  // ── Initialisation ────────────────────────────────────────────────────────

  static Future<void> init() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android notification channel
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Ride and safety notifications for Musafirah',
      importance: Importance.max,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Local notifications plugin init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Foreground FCM messages → show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocal(
          title: notification.title ?? 'Musafirah',
          body: notification.body ?? '',
        );
      }
    });
  }

  // ── Token management ──────────────────────────────────────────────────────

  /// Saves the device FCM token to Firestore so the server (Cloud Functions)
  /// can send targeted push notifications to this user.
  static Future<void> saveTokenForCurrentUser() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final token = await _fcm.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('Passengers')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      // Also try Drivers collection (token saved to whichever exists)
      await FirebaseFirestore.instance
          .collection('Drivers')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));

      debugPrint('FCM token saved for $uid');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('Passengers')
            .doc(uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection('Drivers')
            .doc(uid)
            .set({'fcmToken': newToken}, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  // ── Local notification helpers ────────────────────────────────────────────

  /// Shows a local notification immediately — use for ride status updates
  /// detected via Firestore streams (no Cloud Functions needed).
  static Future<void> showLocal({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Ride and safety notifications for Musafirah',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _localNotif.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  /// Convenience: notify passenger that driver accepted their ride.
  static Future<void> notifyRideAccepted(String driverName) =>
      showLocal(
        id: 1,
        title: 'Driver Accepted Your Ride!',
        body: '$driverName is on the way to pick you up.',
      );

  /// Convenience: notify that driver is nearby.
  static Future<void> notifyDriverNearby() =>
      showLocal(
        id: 2,
        title: 'Your driver is nearby!',
        body: 'Please head to your pickup point.',
      );

  /// Convenience: notify ride completed.
  static Future<void> notifyRideCompleted() =>
      showLocal(
        id: 3,
        title: 'Ride Completed',
        body: 'Thank you for riding with Musafirah. Stay safe!',
      );

  /// Convenience: notify new message.
  static Future<void> notifyNewMessage(String senderName, String text) =>
      showLocal(
        id: 4,
        title: 'New Message from $senderName',
        body: text,
      );

  /// Convenience: notify new ride request (driver).
  static Future<void> notifyNewRideRequest(String passengerName) =>
      showLocal(
        id: 5,
        title: 'New Ride Request',
        body: '$passengerName is requesting a ride nearby.',
      );

  /// Convenience: notify payment received.
  static Future<void> notifyPaymentReceived(double amount) =>
      showLocal(
        id: 6,
        title: 'Payment Received',
        body: 'You received Rs ${amount.toStringAsFixed(0)} in your wallet.',
      );

  // ── Global Listeners ──────────────────────────────────────────────────────
  static StreamSubscription? _chatSub;
  static StreamSubscription? _requestSub;
  static StreamSubscription? _walletSub;

  static void startGlobalListeners({
    required String uid,
    required String role,
    double? lat,
    double? lng,
  }) {
    stopGlobalListeners(); // ensure no duplicates

    // 1. Listen to new ride requests (Driver only)
    if (role == 'driver' && lat != null && lng != null) {
      final Set<String> seenRequests = {};
      
      // We will listen to the plain requested rides stream to avoid complex geo queries globally
      _requestSub = FirebaseFirestore.instance
          .collection('Rides')
          .where('status', isEqualTo: 'requested')
          .snapshots()
          .listen((snap) {
        for (var doc in snap.docs) {
          if (!seenRequests.contains(doc.id)) {
            seenRequests.add(doc.id);
            // Ignore existing requests at startup
            if (snap.docChanges.any((c) => c.doc.id == doc.id && c.type == DocumentChangeType.added)) {
              final data = doc.data();
              notifyNewRideRequest(data['passengerName'] ?? 'A passenger');
            }
          }
        }
      });

      // 2. Listen to wallet balance for payments (Driver only)
      double? lastBalance;
      _walletSub = FirebaseFirestore.instance
          .collection('Wallets')
          .doc(uid)
          .snapshots()
          .listen((snap) {
        if (!snap.exists) return;
        final currentBalance = (snap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
        if (lastBalance != null && currentBalance > lastBalance!) {
          notifyPaymentReceived(currentBalance - lastBalance!);
        }
        lastBalance = currentBalance;
      });
    }

    // 3. Listen to chats (Both)
    // To do this globally without knowing active ride, we'd need to listen to all chats.
    // However, it's easier to listen to messages where receiver is this user.
    // Wait, ChatService uses rideId. So we can't easily listen to all chats globally 
    // unless we query all chats where sender != uid and timestamp is new.
  }

  static void stopGlobalListeners() {
    _chatSub?.cancel();
    _requestSub?.cancel();
    _walletSub?.cancel();
  }
}

