import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'geo_service.dart';

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
      if (doc.exists) return doc.data();
      
      // Fallback for legacy
      final legacy = await _db.collection('users').doc(uid).get();
      if (legacy.exists) return legacy.data();
      
      return null;
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
      if (doc.exists) return doc.data();

      // Fallback for legacy
      final legacy = await _db.collection('drivers').doc(uid).get();
      if (legacy.exists) return legacy.data();

      return null;
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
        'userId': passengerId, // Added for consistency with createRideRequest
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
          .where(Filter.or(
            Filter('passengerId', isEqualTo: passengerId),
            Filter('userId', isEqualTo: passengerId),
          ))
          .get();
      
      final docs = snap.docs.map((d) => d.data()).toList();
      
      // Sort locally to avoid index requirement
      docs.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return docs;
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
          .get();
      
      final docs = snap.docs.map((d) => d.data()).toList();
      
      // Sort locally to avoid index requirement
      docs.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return docs;
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
  // ROLE RESOLUTION  — STRICT, collection-isolated checks
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns 'driver', 'passenger', or null if the UID is unknown.
  ///
  /// STRICT MODE: If [expectedRole] is provided, ONLY that collection is
  /// checked. There is zero fallthrough to the other collection — this is the
  /// core guarantee that prevents passengers from being misidentified as
  /// drivers and vice-versa.
  ///
  /// GENERIC MODE: If [expectedRole] is null, checks Passengers first, then
  /// Drivers, then legacy collections.
  static Future<String?> getUserRole(String uid, {String? expectedRole}) async {
    try {
      debugPrint('DB INFO: getUserRole uid=$uid expected=$expectedRole');

      // ── STRICT: passenger login ──────────────────────────────────────────
      if (expectedRole == 'passenger') {
        final doc = await _db.collection('Passengers').doc(uid).get();
        if (doc.exists) {
          debugPrint('DB INFO: UID $uid confirmed as passenger (Passengers collection)');
          return 'passenger';
        }
        // NOT in Passengers → return null. Do NOT touch Drivers.
        debugPrint('DB INFO: UID $uid NOT found in Passengers — returning null');
        return null;
      }

      // ── STRICT: driver login ─────────────────────────────────────────────
      if (expectedRole == 'driver') {
        final doc = await _db.collection('Drivers').doc(uid).get();
        if (doc.exists) {
          debugPrint('DB INFO: UID $uid confirmed as driver (Drivers collection)');
          return 'driver';
        }
        final legacyDoc = await _db.collection('drivers').doc(uid).get();
        if (legacyDoc.exists) {
          debugPrint('DB INFO: UID $uid confirmed as driver (legacy drivers collection)');
          return 'driver';
        }
        // NOT in Drivers → return null. Do NOT touch Passengers.
        debugPrint('DB INFO: UID $uid NOT found in Drivers — returning null');
        return null;
      }

      // ── GENERIC: no expected role (auto-login / phone login) ─────────────
      // Check Passengers FIRST so a user who signed up as passenger is never
      // misidentified as a driver even if stale data exists in Drivers.
      final passengerDoc = await _db.collection('Passengers').doc(uid).get();
      if (passengerDoc.exists) return 'passenger';

      final driverDoc = await _db.collection('Drivers').doc(uid).get();
      if (driverDoc.exists) return 'driver';

      final legacyDriverDoc = await _db.collection('drivers').doc(uid).get();
      if (legacyDriverDoc.exists) return 'driver';

      final legacyUserDoc = await _db.collection('users').doc(uid).get();
      if (legacyUserDoc.exists) {
        return (legacyUserDoc.data()?['role'] as String?) ?? 'passenger';
      }

      return null;
    } catch (e) {
      debugPrint('DB ERROR (getUserRole): $e');
      return null;
    }
  }

  /// Removes a UID from every collection EXCEPT [keepCollection].
  /// Call this after saving a new user to ensure no stale duplicate exists.
  static Future<void> cleanupStaleRoleData({
    required String uid,
    required String keepCollection, // 'Passengers' or 'Drivers'
  }) async {
    try {
      final batch = _db.batch();
      if (keepCollection != 'Passengers') {
        batch.delete(_db.collection('Passengers').doc(uid));
      }
      if (keepCollection != 'Drivers') {
        batch.delete(_db.collection('Drivers').doc(uid));
        batch.delete(_db.collection('drivers').doc(uid));
      }
      batch.delete(_db.collection('users').doc(uid));
      await batch.commit();
      debugPrint('DB INFO: Cleaned up stale role data for $uid (keeping $keepCollection)');
    } catch (e) {
      debugPrint('DB WARN (cleanupStaleRoleData): $e — non-fatal');
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
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('DB: Status updated for $uid to $status');
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes a user document from a specific collection (Admin action)
  static Future<String?> deleteUserDoc({
    required String uid,
    required String collection,
  }) async {
    try {
      await _db.collection(collection).doc(uid).delete();
      debugPrint('DB: User document $uid deleted from $collection');
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Moves a user from one collection to another (e.g. Driver to Passenger).
  /// This is used to fix role conflicts.
  static Future<bool> moveUserToCollection({
    required String uid,
    required String fromCollection,
    required String toCollection,
    required String newRole,
  }) async {
    try {
      // 1. Find the source document (checking both current and legacy collections)
      DocumentSnapshot<Map<String, dynamic>>? sourceDoc;
      
      final primaryDoc = await _db.collection(fromCollection).doc(uid).get();
      if (primaryDoc.exists) {
        sourceDoc = primaryDoc;
      } else {
        // Fallback for legacy drivers collection
        if (fromCollection == 'Drivers') {
          final legacyDoc = await _db.collection('drivers').doc(uid).get();
          if (legacyDoc.exists) sourceDoc = legacyDoc;
        }
        // Fallback for legacy users collection
        if (sourceDoc == null) {
          final usersDoc = await _db.collection('users').doc(uid).get();
          if (usersDoc.exists) sourceDoc = usersDoc;
        }
      }

      if (sourceDoc == null || !sourceDoc.exists) {
        debugPrint('DB ERROR: Source document for $uid not found in $fromCollection or legacy collections');
        return false;
      }

      final data = sourceDoc.data()!;
      data['role'] = newRole;
      data['updatedAt'] = FieldValue.serverTimestamp();

      // 2. Copy to the NEW collection
      await _db.collection(toCollection).doc(uid).set(data, SetOptions(merge: true));
      
      // 3. AGGRESSIVE CLEANUP: Delete from ALL potential old locations except the new one
      await _db.runTransaction((transaction) async {
        // Delete from current collection names
        if (toCollection != 'Drivers') {
          transaction.delete(_db.collection('Drivers').doc(uid));
        }
        if (toCollection != 'Passengers') {
          transaction.delete(_db.collection('Passengers').doc(uid));
        }
        
        // Delete from legacy collection names
        transaction.delete(_db.collection('drivers').doc(uid));
        transaction.delete(_db.collection('users').doc(uid));
      });
      
      debugPrint('DB INFO: Aggressively moved UID $uid to $toCollection and cleaned up everywhere else');
      return true;
    } catch (e) {
      debugPrint('DB ERROR (moveUserToCollection): $e');
      return false;
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
        'passengerId': uid,
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

  /// Real-time stream for a single ride document — used by the passenger
  /// waiting screen to detect when a driver accepts the ride.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getRideStream(
      String rideId) {
    return _db.collection('Rides').doc(rideId).snapshots();
  }

  /// Called by the driver when accepting a ride request. Uses a Firestore
  /// transaction to atomically verify the ride is still 'requested' before
  /// writing driver details — prevents two drivers accepting the same ride.
  ///
  /// Returns null on success, an error string on failure.
  /// Returns 'already_accepted' if another driver got there first.
  static Future<String?> acceptRideByDriver({
    required String rideId,
    required String driverUid,
    required String driverName,
    required String driverPhone,
    required String vehicleModel,
    required String vehicleColor,
    required String vehiclePlate,
    String driverImageUrl = '',
  }) async {
    try {
      final rideRef = _db.collection('Rides').doc(rideId);
      String? txError;

      await _db.runTransaction((tx) async {
        final snap = await tx.get(rideRef);
        if (!snap.exists) {
          txError = 'ride_not_found';
          return;
        }
        final status = snap.data()?['status'] as String? ?? '';
        if (status == 'cancelled') {
          txError = 'ride_cancelled';
          return;
        }
        if (status != 'requested') {
          txError = 'already_accepted';
          return;
        }
        tx.update(rideRef, {
          'status': 'accepted',
          'driverId': driverUid,
          'driverName': driverName,
          'driverPhone': driverPhone,
          'vehicleModel': vehicleModel,
          'vehicleColor': vehicleColor,
          'vehiclePlate': vehiclePlate,
          'driverImageUrl': driverImageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return txError;
    } on FirebaseException catch (e) {
      return 'Ride accept failed [${e.code}]: ${e.message}';
    } catch (e) {
      return 'Ride accept failed: $e';
    }
  }

  /// Cancels a ride request. Can be called by passenger or system.
  static Future<String?> cancelRide(String rideId) async {
    try {
      await _db.collection('Rides').doc(rideId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return 'Cancel failed [${e.code}]: ${e.message}';
    } catch (e) {
      return 'Cancel failed: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GEO-AWARE RIDE MATCHING
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // Firestore indexes required (create in Firebase Console → Firestore →
  // Indexes → Composite):
  //
  //  Collection: Rides
  //    Field 1: status        ASC
  //    Field 2: pickupGeohash ASC
  //
  //  Collection: Drivers
  //    Field 1: isOnline      ASC
  //    Field 2: status        ASC
  //    Field 3: currentGeohash ASC
  //
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a ride request with geohash + GeoPoint fields so that
  /// [streamNearbyRideRequests] can find it efficiently.
  ///
  /// Caller is responsible for supplying [capacityNeeded] (seats required).
  /// [gender] defaults to 'female' for the women-only Musafirah app.
  static Future<String> createGeoRideRequest({
    required String uid,
    required String passengerName,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required double fare,
    int capacityNeeded = 1,
    String gender = 'female',
  }) async {
    try {
      final geohash = GeoService.encode(pickupLat, pickupLng);
      final docRef = await _db.collection('Rides').add({
        'userId': uid,
        'passengerName': passengerName,
        // coordinates as plain doubles (legacy compatibility)
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'pickupAddress': pickupAddress,
        'dropoffLat': dropoffLat,
        'dropoffLng': dropoffLng,
        'dropoffAddress': dropoffAddress,
        'fare': fare,
        // geo fields for radius queries
        'pickupGeopoint': GeoPoint(pickupLat, pickupLng),
        'pickupGeohash': geohash,
        // filter fields
        'capacityNeeded': capacityNeeded,
        'gender': gender,
        'status': 'requested',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// [DRIVER SIDE] — Real-time stream of 'requested' rides whose pickup is
  /// within [radiusKm] of the driver's current position.
  ///
  /// Query uses geohash cells so Firestore only scans a geographic slice.
  /// Client-side post-filter removes anything outside the true circle and
  /// applies [minSeats] / [gender] constraints.
  ///
  /// Composite index needed: Rides → status ASC + pickupGeohash ASC
  static Stream<List<Map<String, dynamic>>> streamNearbyRideRequests({
    required double driverLat,
    required double driverLng,
    double radiusKm = 10,
    int minSeats = 1,
    String gender = 'female',
  }) {
    final hashes = GeoService.searchHashes(driverLat, driverLng,
        radiusKm: radiusKm);

    return _db
        .collection('Rides')
        .where('status', isEqualTo: 'requested')
        .where('pickupGeohash', whereIn: hashes)
        .snapshots()
        .map((snap) {
      final results = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        // Accurate distance check (geohash cells are square, not circular)
        final distKm = GeoService.distanceKm(
          driverLat,
          driverLng,
          (data['pickupLat'] as num).toDouble(),
          (data['pickupLng'] as num).toDouble(),
        );
        if (distKm > radiusKm) continue;
        // Women-only filter
        if (data['gender'] != gender) continue;
        // Seat capacity filter
        final needed = (data['capacityNeeded'] as num?)?.toInt() ?? 1;
        if (needed < minSeats) continue;

        results.add({...data, 'rideId': doc.id, 'distanceKm': distKm});
      }
      // Sort closest first
      results.sort((a, b) =>
          (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
      return results;
    });
  }

  /// [PASSENGER SIDE] — Real-time stream of 'available' drivers within
  /// [radiusKm] who are online, approved, women-only, and have [minSeats].
  ///
  /// Composite index needed: Drivers → isOnline ASC + status ASC + currentGeohash ASC
  static Stream<List<Map<String, dynamic>>> streamNearbyDrivers({
    required double passengerLat,
    required double passengerLng,
    double radiusKm = 10,
    int minSeats = 1,
    String gender = 'female',
  }) {
    final hashes = GeoService.searchHashes(passengerLat, passengerLng,
        radiusKm: radiusKm);

    return _db
        .collection('Drivers')
        .where('isOnline', isEqualTo: true)
        .where('status', isEqualTo: 'approved')
        .where('currentGeohash', whereIn: hashes)
        .snapshots()
        .map((snap) {
      final results = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        // Skip drivers without location yet
        if (data['currentLat'] == null) continue;
        final distKm = GeoService.distanceKm(
          passengerLat,
          passengerLng,
          (data['currentLat'] as num).toDouble(),
          (data['currentLng'] as num).toDouble(),
        );
        if (distKm > radiusKm) continue;
        // Women-only filter — driver's gender field
        if ((data['gender'] ?? 'female') != gender) continue;
        // Available seat capacity
        final seats = (data['availableSeats'] as num?)?.toInt() ?? 0;
        if (seats < minSeats) continue;

        results.add({...data, 'driverId': doc.id, 'distanceKm': distKm});
      }
      results.sort((a, b) =>
          (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));
      return results;
    });
  }

  /// Updates driver's [availableSeats] and [gender] in their Drivers document.
  /// Call once after the driver sets up their trip before going online.
  static Future<String?> updateDriverTripMeta({
    required String uid,
    required int availableSeats,
    String gender = 'female',
  }) async {
    try {
      await _db.collection('Drivers').doc(uid).update({
        'availableSeats': availableSeats,
        'gender': gender,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Deletes all users with status 'rejected' from both Drivers and Passengers collections.
  static Future<void> deleteAllRejectedUsers() async {
    try {
      final db = FirebaseFirestore.instance;
      // 1. Delete from Drivers
      final rejectedDrivers = await db
          .collection('Drivers')
          .where('status', isEqualTo: 'rejected')
          .get();
      for (var doc in rejectedDrivers.docs) {
        await doc.reference.delete();
        debugPrint('DB: Deleted rejected driver → ${doc.id}');
      }

      // 2. Delete from Passengers
      final rejectedPassengers = await db
          .collection('Passengers')
          .where('status', isEqualTo: 'rejected')
          .get();
      for (var doc in rejectedPassengers.docs) {
        await doc.reference.delete();
        debugPrint('DB: Deleted rejected passenger → ${doc.id}');
      }
      
      debugPrint('DB: All rejected users cleared.');
    } catch (e) {
      debugPrint('DB ERROR (deleteAllRejectedUsers): $e');
    }
  }
}
