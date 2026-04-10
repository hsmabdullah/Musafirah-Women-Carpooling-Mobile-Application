import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Set to false for production — real SMS/email OTPs are sent.
  // Set to true only during local development to bypass Firebase SMS.
  static const bool useDemoMode = false;
  static String? _demoPhoneNumber;
  static const String _demoOtp = "123456";

  // ── Email OTP state (demo only) ────────────────────────────────────────────
  static String? _pendingEmailForOtp;

  // SharedPreferences key used to persist the email across app restarts while
  // the user is clicking the Firebase email link in their mail client.
  static const String _kEmailForSignIn = 'musafirah_email_for_signin';

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

      await _firestore.collection('Drivers').doc(uid).set(placeholders);
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
      if (smsCode != _demoOtp) {
        debugPrint("Demo Mode: OTP Mismatch! Entered='$smsCode' Expected='$_demoOtp'");
        return null; // null = wrong code, not a Firebase error
      }

      // OTP correct — get a real Firebase UID using a 3-strategy cascade so
      // the demo works regardless of which sign-in methods are enabled in the
      // Firebase Console.
      return await _demoSignIn();
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
  
  // 2. Sign Up with Email & Password
  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Error in signUpWithEmail: $e");
      rethrow;
    }
  }

  // 3. Sign In with Email & Password
  static Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Error in signInWithEmailPassword: $e");
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

      String collection = role == 'driver' ? 'Drivers' : 'Passengers';
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
  // Checks new 'Drivers'/'Passengers' collections first, then legacy fallback.
  static Future<DocumentSnapshot?> getUserData(String uid) async {
    if (useDemoMode) {
      debugPrint("Demo Mode: Skipping getUserData for $uid");
      return null;
    }
    try {
      // New capitalized collections (created by DatabaseService)
      final newDriver = await _firestore.collection('Drivers').doc(uid).get();
      if (newDriver.exists) return newDriver;

      final newPassenger =
          await _firestore.collection('Passengers').doc(uid).get();
      if (newPassenger.exists) return newPassenger;

      // Legacy fallback for existing accounts
      final legacyDriver =
          await _firestore.collection('drivers').doc(uid).get();
      if (legacyDriver.exists) return legacyDriver;

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

      TaskSnapshot finalSnapshot = await uploadTask.timeout(const Duration(seconds: 30));
      debugPrint("UploadTask finished with state: ${finalSnapshot.state}");

      if (finalSnapshot.state == TaskState.success) {
        String url = await ref.getDownloadURL();
        debugPrint("UPLOAD SUCCESS! Final URL: $url");
        return url;
      } else {
        throw 'Storage upload failed with state: ${finalSnapshot.state}';
      }
    } catch (e) {
      debugPrint("!!!! CRITICAL UPLOAD FAILURE !!!!");
      debugPrint("Error detail: $e");
      rethrow;
    }
  }

  /// Compresses and encodes an image to a Base64 data URI.
  /// Used for storing images directly in Firestore to bypass Storage issues.
  static Future<String?> compressAndEncodeImage(File file) async {
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      // Basic Base64 encoding without additional compression beyond ImagePicker's
      final base64String = base64Encode(bytes);
      return "data:image/jpeg;base64,$base64String";
    } catch (e) {
      debugPrint("Error encoding image to Base64: $e");
      return null;
    }
  }

  /// Returns an ImageProvider for either a network URL or a Base64 data URI.
  static ImageProvider getImageProvider(String path) {
    if (path.isEmpty) return const AssetImage('assets/images/placeholder.png');

    if (path.startsWith('data:image')) {
      try {
        final base64Data = path.split(',').last;
        final bytes = base64Decode(base64Data);
        return MemoryImage(Uint8List.fromList(bytes));
      } catch (e) {
        debugPrint("Error decoding Base64 for ImageProvider: $e");
        return const AssetImage('assets/images/placeholder.png');
      }
    }
    return NetworkImage(path);
  }

  // 6. Sign In with Email & Password
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (useDemoMode) {
      debugPrint("Demo Mode: Anonymous sign-in for email login.");
      try {
        final result = await _auth.signInAnonymously();
        debugPrint("Demo Mode: Anonymous sign-in success. UID: ${result.user?.uid}");
        return result;
      } catch (e) {
        debugPrint("Demo Mode ERROR (signInWithEmail): $e");
        return null;
      }
    }
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint("Error in signInWithEmail: $e");
      return null;
    }
  }

  // ── Email OTP / Email Sign-in Link ─────────────────────────────────────────

  /// Sends an email sign-in link (production) or pretends to (demo).
  ///
  /// [onLinkSent]  — called when the link/OTP has been dispatched.
  /// [onFailed]    — called with a human-readable error string on failure.
  ///
  /// Production note
  /// ───────────────
  /// Firebase sends the email automatically via `sendSignInLinkToEmail`.
  /// The link opens the app if Android App Links / iOS Universal Links are
  /// configured.  Without that setup the user pastes the link into the
  /// "Paste sign-in link" field on step 2.
  ///
  /// To enable deep-link auto-open:
  ///   Android → add SHA-256 fingerprint in Firebase Console > Project Settings
  ///             and configure the assetlinks.json via App Links.
  ///   iOS     → add the Associated Domains entitlement in Xcode.
  static Future<void> sendEmailSignInLink({
    required String email,
    required void Function() onLinkSent,
    required void Function(String) onFailed,
  }) async {
    if (useDemoMode) {
      _pendingEmailForOtp = email;
      await Future.delayed(const Duration(milliseconds: 700));
      onLinkSent();
      return;
    }

    try {
      // Persist the email so we can retrieve it after the user returns from
      // their mail client (the link itself does not carry the email address).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kEmailForSignIn, email);

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          // Must match the project that owns this app: musafirah-db-updated.
          // handleCodeInApp = false → link opens in the device browser,
          // Firebase completes sign-in there, then auth state propagates
          // automatically to the app. No SHA-1 / deep-link setup required.
          url: 'https://musafirah-db-updated.firebaseapp.com/',
          handleCodeInApp: false,
        ),
      );
      debugPrint('AuthService: Email sign-in link sent to $email');
      onLinkSent();
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Failed to send sign-in link';
      debugPrint('AuthService ERROR (sendEmailSignInLink): $msg');
      onFailed(msg);
    } catch (e) {
      final msg = 'Unexpected error: $e';
      debugPrint('AuthService ERROR (sendEmailSignInLink): $msg');
      onFailed(msg);
    }
  }

  /// Verifies a 6-digit code in **demo mode**.
  /// Returns a [UserCredential] on success, `null` on wrong code.
  static Future<UserCredential?> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    if (!useDemoMode) return null; // production uses link, not code

    if (otp.trim() != _demoOtp || email != _pendingEmailForOtp) {
      debugPrint('Demo Email OTP: code or email mismatch');
      return null; // null = wrong code, not a Firebase error
    }

    final result = await _demoSignIn();
    _pendingEmailForOtp = null;
    return result;
  }

  /// Verifies a Firebase email sign-in **link** in **production mode**.
  ///
  /// Pass the full link URL the user copied from their email client.
  /// Returns a [UserCredential] on success, `null` on any failure.
  static Future<UserCredential?> verifyEmailSignInLink({
    required String emailLink,
  }) async {
    if (useDemoMode) return null;

    try {
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        debugPrint('AuthService: provided string is not a valid email link');
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_kEmailForSignIn);
      if (email == null || email.isEmpty) {
        debugPrint('AuthService: no stored email found for link sign-in');
        return null;
      }

      final result = await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      await prefs.remove(_kEmailForSignIn);
      debugPrint('AuthService: email link sign-in OK. UID: ${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService ERROR (verifyEmailSignInLink) [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('AuthService ERROR (verifyEmailSignInLink): $e');
      return null;
    }
  }

  /// Called from [main.dart] when the app is opened via a deep link.
  /// Returns a completed [UserCredential] if the link is a valid email
  /// sign-in link, otherwise `null`.
  static Future<UserCredential?> handleIncomingLink(String? link) async {
    if (link == null || useDemoMode) return null;
    return verifyEmailSignInLink(emailLink: link);
  }

  // ── Getters ─────────────────────────────────────────────────────────────────

  static String? get pendingEmailForOtp => _pendingEmailForOtp;

  // ── Demo sign-in cascade ────────────────────────────────────────────────────
  /// Obtains a Firebase [UserCredential] for demo mode using the first
  /// strategy that succeeds:
  ///
  ///   1. Re-use the active session (no network call needed).
  ///   2. Anonymous sign-in  — requires "Anonymous" enabled in Firebase Console
  ///      > Authentication > Sign-in method.
  ///   3. Demo email/password — requires "Email/Password" enabled.
  ///      Auto-creates the demo account on first run.
  ///
  /// Throws a [FirebaseAuthException] with a clear setup message only if
  /// **all three** strategies fail.
  static Future<UserCredential> _demoSignIn() async {
    // ── Strategy 1: reuse existing session ──────────────────────────────────
    if (_auth.currentUser != null) {
      debugPrint('Demo: reusing existing session UID=${_auth.currentUser!.uid}');
      // signInAnonymously on an anonymous user just refreshes the token.
      // For non-anonymous providers we just return the current credential
      // via a lightweight re-authentication that never fails if already signed in.
      try {
        return await _auth.signInAnonymously();
      } catch (_) {
        // Non-anonymous session — wrap currentUser in a fake sign-in result
        // by signing in with the same email if available.
      }
    }

    // ── Strategy 2: anonymous ────────────────────────────────────────────────
    try {
      final result = await _auth.signInAnonymously();
      debugPrint('Demo: anonymous sign-in OK. UID=${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint('Demo: anonymous sign-in failed [${e.code}]');
      if (e.code != 'operation-not-allowed') {
        // Unexpected error — surface it immediately.
        throw FirebaseAuthException(
          code: e.code,
          message: 'Demo sign-in error: ${e.message}',
        );
      }
      // operation-not-allowed → Anonymous is disabled, try next strategy.
    }

    // ── Strategy 3: demo email/password ──────────────────────────────────────
    const demoEmail = 'demo@musafirah-app.com';
    const demoEmailPass = 'MusafirahDemo2024!';
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: demoEmail,
        password: demoEmailPass,
      );
      debugPrint('Demo: email/password sign-in OK. UID=${result.user?.uid}');
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        // First run — create the demo account automatically.
        try {
          final result = await _auth.createUserWithEmailAndPassword(
            email: demoEmail,
            password: demoEmailPass,
          );
          debugPrint('Demo: created demo account. UID=${result.user?.uid}');
          return result;
        } on FirebaseAuthException catch (ce) {
          debugPrint('Demo: createUser failed [${ce.code}]: ${ce.message}');
          if (ce.code == 'operation-not-allowed') {
            // Fall through to final error below.
          } else {
            rethrow;
          }
        }
      } else if (e.code != 'operation-not-allowed') {
        rethrow;
      }
    }

    // ── All strategies exhausted ──────────────────────────────────────────────
    throw FirebaseAuthException(
      code: 'demo-no-auth-method',
      message:
          'Firebase setup needed. In Firebase Console → '
          'Authentication → Sign-in method, enable at least ONE of:\n'
          '  • Anonymous\n'
          '  • Email / Password\n'
          'Project: musafirah-db-updated',
    );
  }

  // 7. Sign Out
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
