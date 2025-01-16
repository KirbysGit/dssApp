import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecureScape',
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.welcome, // Start with welcome screen
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}
