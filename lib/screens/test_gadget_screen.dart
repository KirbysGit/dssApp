import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/security_provider.dart';
import '../theme/app_theme.dart';
import './dashboard_screen.dart';
import './logs_screen.dart';
import './cameras_screen.dart';

class TestGadgetScreen extends ConsumerStatefulWidget {
  const TestGadgetScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TestGadgetScreen> createState() => _TestGadgetScreenState();
}

class _TestGadgetScreenState extends ConsumerState<TestGadgetScreen> {
  bool _isLoading = false;

  Future<void> _sendTestCommand(String endpoint, String commandName) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('\n========== SENDING TEST COMMAND ==========');
      debugPrint('Command: $commandName');
      debugPrint('Endpoint: $endpoint');
      
      final gadgetIp = ref.read(gadgetIpProvider);
      final uri = Uri.parse('http://$gadgetIp$endpoint');
      debugPrint('Full URL: $uri');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$commandName sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        final gadgetIp = ref.read(gadgetIpProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send $commandName: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('$commandName Error Details'),
                    content: SingleChildScrollView(
                      child: Text(
                        'Error: $e\n\n'
                        'Please check:\n'
                        '1. Gadget is powered on\n'
                        '2. Connected to the same network\n'
                        '3. IP address is correct ($gadgetIp)\n'
                        '4. No firewall blocking the connection'
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('=========================================\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.deepForestGreen.withOpacity(0.95),
              AppTheme.pineGreen.withOpacity(0.85),
              AppTheme.mistGray.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Test Gadget Controls',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24.0 : 16.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test Environment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use these controls to test the gadget functionality without physical hardware switches. Each button simulates a hardware switch action.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Test Controls
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildTestButton(
                            icon: Icons.warning,
                            label: 'Trigger Alarm',
                            color: Colors.red,
                            onPressed: () => _sendTestCommand('/test_trigger_alarm', 'Trigger Alarm'),
                          ),
                          _buildTestButton(
                            icon: Icons.notifications_off,
                            label: 'Turn Off Alarm',
                            color: Colors.orange,
                            onPressed: () => _sendTestCommand('/test_turn_off_alarm', 'Turn Off Alarm'),
                          ),
                          _buildTestButton(
                            icon: Icons.lightbulb,
                            label: 'Turn On Lights',
                            color: AppTheme.pineGreen,
                            onPressed: () => _sendTestCommand('/test_turn_on_lights', 'Turn On Lights'),
                          ),
                          _buildTestButton(
                            icon: Icons.lightbulb_outline,
                            label: 'Turn Off Lights',
                            color: AppTheme.deepForestGreen,
                            onPressed: () => _sendTestCommand('/test_turn_off_lights', 'Turn Off Lights'),
                          ),
                          _buildTestButton(
                            icon: Icons.power_settings_new,
                            label: 'Restart Gadget',
                            color: Colors.grey,
                            onPressed: () => _sendTestCommand('/test_restart_gadget', 'Restart Gadget'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.deepForestGreen,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 65,
          selectedIndex: 3, // New index for test screen
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.history, color: Colors.white),
              label: 'Logs',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.home, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.camera_alt, color: Colors.white),
              label: 'Cameras',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined, color: Colors.white.withOpacity(0.7)),
              selectedIcon: const Icon(Icons.build, color: Colors.white),
              label: 'Test',
            ),
          ],
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LogsScreen(),
                  ),
                );
                break;
              case 1:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
                break;
              case 2:
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const CamerasScreen(),
                  ),
                );
                break;
              case 3:
                // Already on test screen
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }
} 