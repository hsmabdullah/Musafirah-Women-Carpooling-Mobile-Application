import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Set to true to bypass real SMS and use "123456" as OTP
  static const bool useDemoMode = true;
  static String? _demoPhoneNumber;
  static const String _demoOtp = "123456";

  // 1. Initialize Driver Data (Call this ONCE during registration)
  static Future<void> initializeDriverData({
    required String uid,
    required String phone,
    String? name,
  }) async {
    if (useDemoMode) {
      debugPrint(
        "Demo Mode: Skipping Firestore driver initialization for $uid",
      );
      return;
    }
    try {
      debugPrint("Initializing driver document for $uid");
      Map<String, dynamic> placeholders = {
        'uid': uid,
        'phone': phone,
        'role': 'driver',
        'name': name ?? '',
        'city': '',
        'dob': '',
        'cnic_name': '',
        'Cnic_Number': '',
        'cnic_dob': '',
        'cnic_issue': '',
        'cnic_expiry': '',
        'emergency_relation': '',
        'emergency_contact': '',
        'image_cnic_front': '',
        'image_cnic_back': '',
        'License_Number': '',
        'license_expiry': '',
        'image_license_front': '',
        'image_license_back': '',
        'registrationStep': 'none',
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('drivers').doc(uid).set(placeholders);
      debugPrint("Driver document initialized successfully.");
    } catch (e) {
      debugPrint("Error initializing driver data: $e");
      rethrow;
    }
  }

  // 2. Verify Phone Number
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onFailed,
  }) async {
    if (useDemoMode) {
      _demoPhoneNumber = phoneNumber;
      // Bypass Firebase SMS and trigger codeSent immediately
      await Future.delayed(const Duration(seconds: 1));
      onCodeSent("demo_verification_id");
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // This only happens on Android when automatic SMS code resolution works
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: onFailed,
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
      );
    } catch (e) {
      debugPrint("Error in verifyPhoneNumber: $e");
    }
  }

  // 2. Sign In with OTP
  static Future<UserCredential?> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (useDemoMode) {
      debugPrint(
        "Demo Mode: Checking OTP. Entered: '$smsCode', Expected: '$_demoOtp'",
      );
      if (smsCode == _demoOtp) {
        // Use Anonymous Auth or a dummy sign-in for Demo Mode
        // Note: Firestore still needs a valid UID to save data.
        // We'll sign in anonymously to get a real UID for persistence.
        try {
          UserCredential result = await _auth.signInAnonymously();
          debugPrint(
            "Demo Mode: Anonymous Sign-in successful. UID: ${result.user?.uid}",
          );
          return result;
        } catch (e) {
          debugPrint("!!!! Demo Mode ERROR !!!! Anonymous Sign-in failed: $e");
          debugPrint(
            "Please make sure 'Anonymous' provider is enabled in Firebase Console > Authentication > Sign-in method",
          );
          return null;
        }
      } else {
        debugPrint("Demo Mode: OTP Mismatch!");
        return null;
      }
    }

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Error in signInWithOTP: $e");
      return null;
    }
  }

  // 3. Save User Data
  static Future<void> saveUserData({
    required String uid,
    required String role, // 'passenger' or 'driver'
    required String phone,
    String? name,
    Map<String, dynamic>? extraData,
  }) async {
    if (useDemoMode) {
      debugPrint("!!!! DEMO MODE: Bypassing Firestore Save !!!!");
      debugPrint("Role: $role, Phone: $phone, Name: $name");
      debugPrint("Extra Data: $extraData");
      return;
    }
    try {
      Map<String, dynamic> data = {
        'uid': uid,
        'role': role,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) data['name'] = name;
      if (extraData != null) data.addAll(extraData);

      String collection = role == 'driver' ? 'drivers' : 'users';
      debugPrint("Updating $collection/$uid with: $data");

      await _firestore
          .collection(collection)
          .doc(uid)
          .set(data, SetOptions(merge: true));
      debugPrint("Data updated successfully.");
    } catch (e) {
      debugPrint("!!!! FIRESTORE SAVE ERROR !!!! $e");
      rethrow;
    }
  }

  // 4. Get User Data
  static Future<DocumentSnapshot?> getUserData(String uid) async {
    if (useDemoMode) {
      debugPrint("Demo Mode: Skipping getUserData for $uid");
      return null;
    }
    try {
      DocumentSnapshot driverDoc = await _firestore
          .collection('drivers')
          .doc(uid)
          .get();
      if (driverDoc.exists) return driverDoc;

      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      debugPrint("Error in getUserData: $e");
      return null;
    }
  }

  // 5. Upload Image
  static Future<String?> uploadImage(String path, File file) async {
    if (useDemoMode) {
      debugPrint("!!!! DEMO MODE: Bypassing Storage Upload for $path !!!!");
      // Return a public placeholder image relative to the path
      // This ensures the app doesn't crash and has something to show
      return "https://firebasestorage.googleapis.com/v0/b/musafirah-app.firebasestorage.app/o/placeholder.jpg?alt=media";
    }
    String currentUid = _auth.currentUser?.uid ?? "unknown";
    debugPrint(">>> STARTING UPLOAD REQUEST <<<");
    debugPrint("Target Path: $path");
    debugPrint("Current UID: $currentUid");
    debugPrint("Target Bucket: ${_storage.bucket}");

    try {
      // 1. Verify local file exists
      if (!await file.exists()) {
        throw 'Local file does not exist at: ${file.path}';
      }
      debugPrint("Local file verified, size: ${await file.length()} bytes");

      String cleanPath = path.startsWith('/') ? path.substring(1) : path;
      Reference ref = _storage.ref().child(cleanPath);

      debugPrint("Attempting putFile to: ${ref.fullPath}");
      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Listen for task completion/failure
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            100.0 * (snapshot.bytesTransferred / snapshot.totalBytes);
        debugPrint(
          'Progress for ${snapshot.ref.name}: ${progress.toStringAsFixed(2)}% (${snapshot.state})',
        );
      }, onError: (e) => debugPrint("!!!! UploadTask Stream Error: $e"));

      TaskSnapshot finalSnapshot = await uploadTask;
      debugPrint("UploadTask finished with state: ${finalSnapshot.state}");

      if (finalSnapshot.state == TaskState.success) {
        // Wait a small propagation delay (1s) before first attempt
        debugPrint("Waiting 1s for Storage propagation...");
        await Future.delayed(const Duration(seconds: 1));

        int retryCount = 0;
        const int maxRetries = 5;

        while (true) {
          try {
            debugPrint(
              "Fetching download URL (Attempt ${retryCount + 1}) for ${ref.fullPath}",
            );
            String url = await ref.getDownloadURL();
            debugPrint("UPLOAD SUCCESS! Final URL: $url");
            return url;
          } on FirebaseException catch (e) {
            debugPrint(
              "FirebaseException (getDownloadURL): [${e.code}] ${e.message}",
            );
            bool shouldRetry =
                e.code == 'object-not-found' ||
                e.code == 'unknown' ||
                e.toString().contains('object-not-found');

            if (shouldRetry && retryCount < maxRetries) {
              retryCount++;
              int delay = 2000 * retryCount;
              debugPrint("Retrying URL fetch in ${delay}ms...");
              await Future.delayed(Duration(milliseconds: delay));
            } else {
              rethrow;
            }
          }
        }
      } else {
        throw 'Storage upload failed with state: ${finalSnapshot.state}';
      }
    } catch (e) {
      debugPrint("!!!! CRITICAL UPLOAD FAILURE !!!!");
      debugPrint("Error detail: $e");
      rethrow;
    }
  }

  // 6. Sign Out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // 7. Get Current User
  static User? get currentUser => _auth.currentUser;

  // 8. Get Demo Phone Number (if applicable)
  static String? get demoPhone => _demoPhoneNumber;

  // 9. Get Generated Demo OTP
  static String get demoGeneratedOtp => _demoOtp;
}
