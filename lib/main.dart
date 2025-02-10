import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/about_screen.dart';
import 'screens/connecting_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureScape',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: AppTheme.mistGray,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/connecting': (context) => const ConnectingScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
