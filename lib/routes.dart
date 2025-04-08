// lib/routes.dart

// Description :
// This file contains the AppRoutes class which is responsible for :
// - Providing the routes for the app.

// Importing Flutter Material Package.
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
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
    '/about': (context) => const AboutScreen(),
  };
} 