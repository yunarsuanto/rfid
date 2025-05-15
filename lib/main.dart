import 'dart:io';

import 'package:flutter/material.dart';
import 'package:elibrary/config/http_overrides.dart';
import 'package:elibrary/screens/home_screen.dart';
import 'package:elibrary/screens/login_screen.dart';
import 'package:elibrary/screens/onboarding_screen.dart';
import 'package:elibrary/screens/register_screen.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RFID App',
      // home: OnboardingScreen(),
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
