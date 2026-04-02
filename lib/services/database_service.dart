import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Musafirah – DatabaseService
// Project: musafirah-db-updated
//
// Firestore Collections
// ─────────────────────
//  Passengers/{uid}           – passenger profile
//  Drivers/{uid}              – driver profile
//  Rides/{rideId}             – ride records
//  Wallets/{uid}              – wallet balance + transactions (sub-collection)
//  Wallets/{uid}/Transactions/{txId}
//  Ratings/{ratingId}         – post-ride ratings
//  SupportTickets/{ticketId}  – in-app support requests
//
// All methods return null on success, an error String on failure.
// The app never crashes from a database error.
// ─────────────────────────────────────────────────────────────────────────────

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // PASSENGERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates or updates a Passenger document immediately after signup.
  ///
  /// Fields: uid · name · email · phone · emergencyContact ·
  ///         profileImageUrl · cnicNumber · isVerified ·
  ///         createdAt · updatedAt
  static Future<String?> savePassenger({
    required String uid,
    required String phone,
    String name = '',
    String email = '',
    String emergencyContact = '',
    String profileImageUrl = '',
    String cnicNumber = '',
    bool isVerified = false,
    String status = 'pending', // 'pending' | 'approved' | 'rejected'
  }) async {
    try {
      await _db.collection('Passengers').doc(uid).set(
        {
          'uid': uid,
          'name': name,
          'email': email,
          'phone': phone,
          'emergencyContact': emergencyContact,
          'profileImageUrl': profileImageUrl,
          'cnicNumber': cnicNumber,
          'isVerified': isVerified,
          'status': status,
          'totalRides': 0,
          'rating': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('DB: Passenger saved → $uid');
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Passenger save failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Passenger save failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  /// Updates specific passenger fields without overwriting the whole document.
  static Future<String?> updatePassenger({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      await _db.collection('Passengers').doc(uid).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Passenger update failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Passenger update failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  /// Fetches a passenger document. Returns null if not found or on error.
  static Future<Map<String, dynamic>?> getPassenger(String uid) async {
    try {
      final doc = await _db.collection('Passengers').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('DB ERROR (getPassenger): $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRIVERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates or updates a Driver document immediately after phone verification.
  ///
  /// Fields: uid · name · email · phone · cnicNumber · cnicName ·
  ///         cnicDob · cnicIssue · cnicExpiry · cnicFrontUrl · cnicBackUrl ·
  ///         vehicleModel · vehicleColor · vehicleRegistration ·
  ///         drivingLicense · licenseExpiry · licenseFrontUrl ·
  ///         licenseBackUrl · selfieUrl · profileImageUrl ·
  ///         emergencyContact · city · dob ·
  ///         isVerified · registrationStep ·
  ///         rating · totalRides · createdAt · updatedAt
  static Future<String?> saveDriver({
    required String uid,
    required String phone,
    String name = '',
    String email = '',
    String cnicNumber = '',
    String cnicName = '',
    String cnicDob = '',
    String cnicIssue = '',
    String cnicExpiry = '',
    String cnicFrontUrl = '',
    String cnicBackUrl = '',
    String vehicleModel = '',
    String vehicleColor = '',
    String vehicleRegistration = '',
    String drivingLicense = '',
    String licenseExpiry = '',
    String licenseFrontUrl = '',
    String licenseBackUrl = '',
    String selfieUrl = '',
    String profileImageUrl = '',
    String emergencyContact = '',
    String city = '',
    String dob = '',
    bool isVerified = false,
    String status = 'pending', // 'pending' | 'approved' | 'rejected'
    String registrationStep = 'phone_verified',
  }) async {
    try {
      await _db.collection('Drivers').doc(uid).set(
        {
          'uid': uid,
          'name': name,
          'email': email,
          'phone': phone,
          // CNIC
          'cnicNumber': cnicNumber,
          'cnicName': cnicName,
          'cnicDob': cnicDob,
          'cnicIssue': cnicIssue,
          'cnicExpiry': cnicExpiry,
          'cnicFrontUrl': cnicFrontUrl,
          'cnicBackUrl': cnicBackUrl,
          // Vehicle
          'vehicleModel': vehicleModel,
          'vehicleColor': vehicleColor,
          'vehicleRegistration': vehicleRegistration,
          // License
          'drivingLicense': drivingLicense,
          'licenseExpiry': licenseExpiry,
          'licenseFrontUrl': licenseFrontUrl,
          'licenseBackUrl': licenseBackUrl,
          // Profile
          'selfieUrl': selfieUrl,
          'profileImageUrl': profileImageUrl,
          'emergencyContact': emergencyContact,
          'city': city,
          'dob': dob,
          // Status
          'isVerified': isVerified,
          'status': status,
          'registrationStep': registrationStep,
          'rating': 0.0,
          'totalRides': 0,
          'isOnline': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('DB: Driver saved → $uid');
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Driver save failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Driver save failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  /// Merges a partial map of fields into a Driver document.
  /// Use this during multi-step registration to update individual steps.
  static Future<String?> updateDriverFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    try {
      await _db.collection('Drivers').doc(uid).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('DB: Driver fields updated → $uid');
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Driver update failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Driver update failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  /// Fetches a driver document. Returns null if not found or on error.
  static Future<Map<String, dynamic>?> getDriver(String uid) async {
    try {
      final doc = await _db.collection('Drivers').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('DB ERROR (getDriver): $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIDES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new ride record and returns its auto-generated ID,
  /// or null on failure.
  ///
  /// Fields: rideId · passengerId · driverId · originAddress ·
  ///         originLat · originLng · destinationAddress ·
  ///         destinationLat · destinationLng · distanceKm ·
  ///         durationMinutes · fare · status · createdAt · updatedAt
  ///
  /// Status values: 'requested' → 'accepted' → 'active' → 'completed' | 'cancelled'
  static Future<String?> createRide({
    required String passengerId,
    required String originAddress,
    required double originLat,
    required double originLng,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required double distanceKm,
    required double durationMinutes,
    required double fare,
    String driverId = '',
  }) async {
    try {
      final ref = _db.collection('Rides').doc();
      await ref.set({
        'rideId': ref.id,
        'passengerId': passengerId,
        'driverId': driverId,
        'originAddress': originAddress,
        'originLat': originLat,
        'originLng': originLng,
        'destinationAddress': destinationAddress,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'distanceKm': distanceKm,
        'durationMinutes': durationMinutes,
        'fare': fare,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('DB: Ride created → ${ref.id}');
      return ref.id;
    } on FirebaseException catch (e) {
      debugPrint('DB ERROR (createRide) [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('DB ERROR (createRide): $e');
      return null;
    }
  }

  /// Updates the status of an existing ride.
  static Future<String?> updateRideStatus({
    required String rideId,
    required String status,
    String? driverId,
  }) async {
    try {
      final data = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (driverId != null) data['driverId'] = driverId;
      await _db.collection('Rides').doc(rideId).update(data);
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Ride status update failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Ride status update failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  /// Returns all rides for a passenger, newest first.
  static Future<List<Map<String, dynamic>>> getPassengerRides(
    String passengerId,
  ) async {
    try {
      final snap = await _db
          .collection('Rides')
          .where('passengerId', isEqualTo: passengerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('DB ERROR (getPassengerRides): $e');
      return [];
    }
  }

  /// Returns all rides for a driver, newest first.
  static Future<List<Map<String, dynamic>>> getDriverRides(
    String driverId,
  ) async {
    try {
      final snap = await _db
          .collection('Rides')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('DB ERROR (getDriverRides): $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WALLETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a wallet document for a new user (balance starts at 0).
  ///
  /// Fields: uid · balance · currency · createdAt · updatedAt
  static Future<String?> createWallet({required String uid}) async {
    try {
      await _db.collection('Wallets').doc(uid).set(
        {
          'uid': uid,
          'balance': 0.0,
          'currency': 'PKR',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Wallet create failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Wallet create failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  /// Adds a transaction to the Wallets/{uid}/Transactions sub-collection
  /// and updates the wallet balance atomically.
  ///
  /// [type]: 'credit' | 'debit'
  static Future<String?> addTransaction({
    required String uid,
    required double amount,
    required String type,
    required String description,
    String? rideId,
  }) async {
    try {
      final walletRef = _db.collection('Wallets').doc(uid);
      final txRef = walletRef.collection('Transactions').doc();

      await _db.runTransaction((tx) async {
        final walletSnap = await tx.get(walletRef);
        final currentBalance =
            (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

        final newBalance = type == 'credit'
            ? currentBalance + amount
            : currentBalance - amount;

        tx.update(walletRef, {
          'balance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(txRef, {
          'txId': txRef.id,
          'uid': uid,
          'amount': amount,
          'type': type,
          'description': description,
          'rideId': rideId ?? '',
          'balanceAfter': newBalance,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      debugPrint('DB: Transaction added → $uid  $type PKR$amount');
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Transaction failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Transaction failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  /// Returns all transactions for a user, newest first.
  static Future<List<Map<String, dynamic>>> getTransactions(
    String uid,
  ) async {
    try {
      final snap = await _db
          .collection('Wallets')
          .doc(uid)
          .collection('Transactions')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('DB ERROR (getTransactions): $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RATINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submits a post-ride rating.
  ///
  /// Fields: ratingId · rideId · fromUid · toUid · toRole ·
  ///         stars · comment · createdAt
  static Future<String?> submitRating({
    required String rideId,
    required String fromUid,
    required String toUid,
    required String toRole, // 'driver' | 'passenger'
    required int stars,     // 1–5
    String comment = '',
  }) async {
    try {
      final ref = _db.collection('Ratings').doc();
      await ref.set({
        'ratingId': ref.id,
        'rideId': rideId,
        'fromUid': fromUid,
        'toUid': toUid,
        'toRole': toRole,
        'stars': stars,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update the average rating on the target user's document.
      final collection = toRole == 'driver' ? 'Drivers' : 'Passengers';
      final userRef = _db.collection(collection).doc(toUid);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final data = snap.data() ?? {};
        final currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final totalRides = (data['totalRides'] as int?) ?? 0;
        final newTotal = totalRides + 1;
        final newRating =
            ((currentRating * totalRides) + stars) / newTotal;
        tx.update(userRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'totalRides': newTotal,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      debugPrint('DB: Rating submitted → ride=$rideId  to=$toUid  stars=$stars');
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Rating submit failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Rating submit failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPPORT TICKETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a support ticket.
  ///
  /// Fields: ticketId · uid · userRole · subject · message ·
  ///         status · createdAt · updatedAt
  static Future<String?> createSupportTicket({
    required String uid,
    required String userRole, // 'passenger' | 'driver'
    required String subject,
    required String message,
  }) async {
    try {
      final ref = _db.collection('SupportTickets').doc();
      await ref.set({
        'ticketId': ref.id,
        'uid': uid,
        'userRole': userRole,
        'subject': subject,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      final msg = 'Support ticket failed [${e.code}]: ${e.message}';
      debugPrint('DB ERROR: $msg');
      return msg;
    } catch (e) {
      final msg = 'Support ticket failed: $e';
      debugPrint('DB ERROR: $msg');
      return msg;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE RESOLUTION  (checks new + legacy collections)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns 'driver', 'passenger', or null if the UID is unknown.
  static Future<String?> getUserRole(String uid) async {
    try {
      final driver = await _db.collection('Drivers').doc(uid).get();
      if (driver.exists) return 'driver';

      final passenger = await _db.collection('Passengers').doc(uid).get();
      if (passenger.exists) return 'passenger';

      // Legacy fallback
      final legacyDriver = await _db.collection('drivers').doc(uid).get();
      if (legacyDriver.exists) return 'driver';

      final legacyUser = await _db.collection('users').doc(uid).get();
      if (legacyUser.exists) {
        return (legacyUser.data()?['role'] as String?) ?? 'passenger';
      }

      return null;
    } catch (e) {
      debugPrint('DB ERROR (getUserRole): $e');
      return null;
    }
  }

  /// Updates the status of any user ('Passengers' or 'Drivers').
  static Future<String?> updateUserStatus({
    required String uid,
    required String collection,
    required String status,
  }) async {
    try {
      await _db.collection(collection).doc(uid).update({
        'status': status,
        'isVerified': status == 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('DB: Status updated for $uid to $status');
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Fetches the full document for any user.
  static Future<Map<String, dynamic>?> getUserData(String uid, String collection) async {
    try {
      final doc = await _db.collection(collection).doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('DB ERROR (getUserData): $e');
      return null;
    }
  }

  /// Returns a stream of a specific user document for real-time UI updates.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDocStream(
    String uid,
    String collection,
  ) {
    return _db.collection(collection).doc(uid).snapshots();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONNECTIVITY & TRIP BROADCASTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Updates a driver's active trip details to broadcast to matching passengers.
  static Future<String?> updateDriverTrip({
    required String uid,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required List<Map<String, double>> routePoints,
    required bool isOnline,
  }) async {
    try {
      await _db.collection('Drivers').doc(uid).update({
        'isOnline': isOnline,
        'currentTrip': {
          'pickupLat': pickupLat,
          'pickupLng': pickupLng,
          'pickupAddress': pickupAddress,
          'dropoffLat': dropoffLat,
          'dropoffLng': dropoffLng,
          'dropoffAddress': dropoffAddress,
          'routePoints': routePoints,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns a stream of all drivers who are currently online.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getOnlineDriversStream() {
    return _db
        .collection('Drivers')
        .where('isOnline', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .snapshots();
  }

  /// Returns a stream of all ride requests that are currently pending/requested.
  static Stream<QuerySnapshot<Map<String, dynamic>>> getRequestedRidesStream() {
    return _db
        .collection('Rides')
        .where('status', isEqualTo: 'requested')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Creates a new ride request in Firestore to broadcast for matching drivers.
  /// Returns the ride ID on success, or a string starting with "Error:" on failure.
  static Future<String> createRideRequest({
    required String uid,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required double fare,
  }) async {
    try {
      final docRef = await _db.collection('Rides').add({
        'userId': uid,
        'passengerName': passengerName,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'pickupAddress': pickupAddress,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'dropoffAddress': dropoffAddress,
        'fare': fare,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }
}
