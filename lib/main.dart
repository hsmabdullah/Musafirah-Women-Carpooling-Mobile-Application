import 'package:flutter/material.dart';
import 'package:musafirah_app/login_screen.dart';
import 'package:musafirah_app/splashScreen.dart';

void main() {
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
    );
  }
}
