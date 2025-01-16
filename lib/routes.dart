import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/dashboard_page.dart';
import 'screens/photos_page.dart';
import 'screens/alerts_page.dart';
import 'screens/settings_page.dart';
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
    dashboard: (context) => const DashboardPage(),
    photos: (context) => const PhotosPage(),
    alerts: (context) => const AlertsPage(),
    settings: (context) => const SettingsPage(),
    '/about': (context) => const AboutScreen(),
  };
} 