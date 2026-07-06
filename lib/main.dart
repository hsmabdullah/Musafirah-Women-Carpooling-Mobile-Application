import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:musafirah_app/firebase_options.dart';
import 'package:musafirah_app/splash_screen.dart';
import 'package:musafirah_app/driver_dashboard_screen.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'package:musafirah_app/services/notification_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:musafirah_app/screens/admin/admin_login_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/admin_dashboard_screen.dart'
    as admin;
import 'package:musafirah_app/screens/admin/drivers_list_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/riders_list_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/live_rides_screen.dart' as admin;

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix for CERTIFICATE_VERIFY_FAILED error in some network environments
  HttpOverrides.global = MyHttpOverrides();

  // Initialize Stripe
  Stripe.publishableKey =
      "pk_test_51TFXeuH0Dn2ZkytqM7S9bVbDd6xWsCsfGqkD8NNHd5eZH1XuxAff4yredcagA9RH0NyB592Q2UxwPjcYr2l0QjzG00jklgVyqb";
  await Stripe.instance.applySettings();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      debugPrint('Firebase already initialized');
    } else {
      rethrow;
    }
  }

  // Initialise notifications (FCM + local)
  await NotificationService.init();

  // CLEANUP: Delete all rejected accounts (non-blocking)
  DatabaseService.deleteAllRejectedUsers();

  Widget home = const SplashScreen();

  if (!AuthService.useDemoMode) {
    try {
      final initialLink = Uri.base.toString();
      final credential = await AuthService.handleIncomingLink(initialLink);

      if (credential != null && credential.user != null) {
        final uid = credential.user!.uid;

        // Use the locally saved role if available to prevent misidentification
        final lastRole = await AuthService.getLastUsedRole();

        String? role = await DatabaseService.getUserRole(
          uid,
          expectedRole: lastRole,
        );
        role ??= lastRole ?? 'passenger';

        home = role == 'driver'
            ? const DriverDashboardScreen()
            : const PassengerDashboardScreen();
        debugPrint(
          'main: email-link deep sign-in OK → role=$role (Local: $lastRole)',
        );
      }
    } catch (e) {
      debugPrint('main: email-link check skipped — $e');
    }
  }

  runApp(MyApp(home: home));
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musafirah',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFC153b)),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: home,
      routes: {
        '/login': (context) => const admin.LoginScreen(),
        '/dashboard': (context) => const admin.DashboardScreen(),
        '/drivers': (context) => const admin.DriversListScreen(),
        '/riders': (context) => const admin.RidersListScreen(),
        '/rides': (context) => const admin.LiveRidesScreen(),
      },
    );
  }
}
