import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:musafirah_app/firebase_options.dart';
import 'package:musafirah_app/splash_screen.dart';
import 'package:musafirah_app/driver_dashboard_screen.dart';
import 'package:musafirah_app/passenger_dashboard_screen.dart';
import 'package:musafirah_app/services/auth_service.dart';
import 'package:musafirah_app/services/database_service.dart';
import 'package:musafirah_app/services/notification_service.dart';
import 'package:musafirah_app/providers/theme_provider.dart';
import 'package:musafirah_app/screens/admin/admin_login_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/admin_dashboard_screen.dart'
    as admin;
import 'package:musafirah_app/screens/admin/drivers_list_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/riders_list_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/live_rides_screen.dart' as admin;
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  Widget home = const SplashScreen();

  if (!AuthService.useDemoMode) {
    try {
      final initialLink = Uri.base.toString();
      final credential = await AuthService.handleIncomingLink(initialLink);

      if (credential != null && credential.user != null) {
        final uid = credential.user!.uid;
        String? role = await DatabaseService.getUserRole(uid);
        role ??= 'passenger';
        home = role == 'driver'
            ? const DriverDashboardScreen()
            : const PassengerDashboardScreen();
        debugPrint('main: email-link deep sign-in OK → role=$role');
      }
    } catch (e) {
      debugPrint('main: email-link check skipped — $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(home: home),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Musafirah',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'),
      supportedLocales: const [Locale('en', 'US')],
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFC153b)),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFC153b),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
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
