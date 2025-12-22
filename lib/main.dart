import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:musafirah_app/firebase_options.dart';
import 'package:musafirah_app/splash_screen.dart';
import 'package:musafirah_app/screens/admin/admin_login_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/admin_dashboard_screen.dart'
    as admin;
import 'package:musafirah_app/screens/admin/drivers_list_screen.dart' as admin;
import 'package:musafirah_app/screens/admin/riders_list_screen.dart' as admin;

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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musafirah',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en', 'US'), // Force English locale
      supportedLocales: const [
        Locale('en', 'US'), // English
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFC153b)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const admin.LoginScreen(),
        '/dashboard': (context) => const admin.DashboardScreen(),
        '/drivers': (context) => const admin.DriversListScreen(),
        '/riders': (context) => const admin.RidersListScreen(),
      },
    );
  }
}
