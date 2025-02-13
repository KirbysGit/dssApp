import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/about_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String photos = '/photos';
  static const String alerts = '/alerts';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
    welcome: (context) => const WelcomeScreen(),
    home: (context) => const HomeScreen(),
    '/about': (context) => const AboutScreen(),
  };
} 