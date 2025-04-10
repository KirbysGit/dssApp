import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/about_screen.dart';
import 'screens/connecting_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'providers/security_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service and provider container
  final container = ProviderContainer(
    overrides: [
      // Set default IP but allow it to be changed
      gadgetIpProvider.overrideWith((ref) => '192.168.8.207'),
    ],
  );
  
  runApp(
    ProviderScope(
      parent: container,
      child: const MyApp(),
    ),
  );

  // Send a test notification after a short delay
  Future.delayed(const Duration(seconds: 5), () async {
    await NotificationService().sendTestNotification();
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _notificationService.initialize(ProviderScope.containerOf(context));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _notificationService.setAppLifecycleState(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
