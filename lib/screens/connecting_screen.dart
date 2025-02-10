import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class ConnectingScreen extends StatefulWidget {
  const ConnectingScreen({Key? key}) : super(key: key);

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> {
  bool _isChecking = false;
  String _statusMessage = 'Please connect to the SecureScape WiFi network';
  bool _hasError = false;
  Timer? _connectionCheckTimer;
  final String _gadgetIp = '192.168.8.151'; // Your gadget's IP address

  @override
  void initState() {
    super.initState();
    _startConnectionCheck();
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _startConnectionCheck() async {
    setState(() {
      _isChecking = true;
      _hasError = false;
      _statusMessage = 'Checking connection to SecureScape...';
    });

    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkGadgetConnection();
    });
  }

  Future<void> _checkGadgetConnection() async {
    try {
      final response = await http.get(
        Uri.parse('http://$_gadgetIp/ping'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _connectionCheckTimer?.cancel();
        setState(() {
          _statusMessage = 'Connected successfully!';
          _isChecking = false;
        });
        
        // Wait a moment to show success message before navigating
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isChecking = false;
        _statusMessage = 'Unable to connect to SecureScape.\nPlease make sure you are connected to the correct WiFi network.';
      });
      _connectionCheckTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepForestGreen.withOpacity(0.9),
              AppTheme.pineGreen.withOpacity(0.7),
              AppTheme.mistGray,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 48.0 : 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/dssLogo.png',
                      height: isLargeScreen ? 150 : 100,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Status Message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: isLargeScreen ? 20 : 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Loading Indicator or Retry Button
                      if (_isChecking)
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      else if (_hasError)
                        ElevatedButton(
                          onPressed: _startConnectionCheck,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            minimumSize: const Size(200, 50),
                          ),
                          child: Text(
                            'Retry Connection',
                            style: TextStyle(
                              color: AppTheme.deepForestGreen,
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // WiFi Instructions
                if (!_isChecking && !_hasError)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.wifi,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Network Name: SecureScape\nPassword: securescape123',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 16 : 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 