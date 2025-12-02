import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/drivers_list_screen.dart';
import 'screens/riders_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musafirah Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF1744),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF1744),
          primary: const Color(0xFFFF1744),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/drivers': (context) => const DriversListScreen(),
        '/riders': (context) => const RidersListScreen(),
      },
    );
  }
}
