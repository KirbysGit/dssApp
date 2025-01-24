import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/about_screen.dart';
import 'providers/security_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SecurityProvider(),
      child: MaterialApp(
        title: 'SecureScape',
        theme: AppTheme.lightTheme,
        home: const WelcomeScreen(),
        routes: {
          '/about': (context) => const AboutScreen(),
        },
      ),
    );
  }
}
