import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isConnected = false;
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Check connection every 10 seconds
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnection(),
    );
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    final gadgetIp = ref.read(gadgetIpProvider);
    try {
      final response = await http.get(
        Uri.parse('http://$gadgetIp/health'),
      ).timeout(const Duration(seconds: 2));
      
      if (mounted) {
        setState(() => _isConnected = response.statusCode == 200);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnected = false);
      }
    }
  }

  Future<void> _sendTestCommand(String endpoint, String commandName) async {
    if (!_isConnected) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Not connected to gadget'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            left: 20,
            right: 20,
          ),
          action: SnackBarAction(
            label: 'Check IP',
            textColor: Colors.white,
            onPressed: () => _showIpConfigDialog(),
          ),
        ),
      );
      return;
    }

    final gadgetIp = ref.read(gadgetIpProvider);
    final uri = Uri.parse('http://$gadgetIp$endpoint');

    try {
      HapticFeedback.lightImpact();
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$commandName sent successfully ✅'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                left: 20,
                right: 20,
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to send $commandName'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              left: 20,
              right: 20,
            ),
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
    }
  }

  Future<void> _showIpConfigDialog() async {
    final currentIp = ref.read(gadgetIpProvider);
    final TextEditingController ipController = TextEditingController(text: currentIp);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Gadget IP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.8.225',
                helperText: 'Enter the IP address of your SecureScape gadget',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newIp = ipController.text.trim();
              if (_isValidIpAddress(newIp)) {
                ref.read(gadgetIpProvider.notifier).state = newIp;
                Navigator.pop(context);
                _checkConnection();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gadget IP updated to: $newIp'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid IP address'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isValidIpAddress(String ip) {
    if (ip.isEmpty) return false;
    
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    return parts.every((part) {
      try {
        final number = int.parse(part);
        return number >= 0 && number <= 255;
      } catch (e) {
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final gadgetIp = ref.watch(gadgetIpProvider);

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
                      'Gadget Utility',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLargeScreen ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const Spacer(),
                    // Connection status and IP
                    GestureDetector(
                      onTap: _showIpConfigDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isConnected ? Icons.link : Icons.link_off,
                              color: _isConnected ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gadgetIp,
                              style: TextStyle(
                                color: _isConnected ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                          ],
                        ),
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
                  child: isLargeScreen
                      ? GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _buildUtilityButtons(),
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _buildUtilityButtons(),
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
          selectedIndex: 3,
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
              label: 'Utility',
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
                // Already on utility screen
                break;
            }
          },
        ),
      ),
    );
  }

  List<Widget> _buildUtilityButtons() {
    return [
      _buildUtilityButton(
        icon: Icons.warning,
        label: 'Trigger Alarm',
        color: Colors.red,
        onPressed: () => _sendTestCommand('/test_trigger_alarm', 'Trigger Alarm'),
      ),
      _buildUtilityButton(
        icon: Icons.notifications_off,
        label: 'Turn Off Alarm',
        color: Colors.orange,
        onPressed: () => _sendTestCommand('/test_turn_off_alarm', 'Turn Off Alarm'),
      ),
      _buildUtilityButton(
        icon: Icons.lightbulb,
        label: 'Turn On Lights',
        color: AppTheme.pineGreen,
        onPressed: () => _sendTestCommand('/test_turn_on_lights', 'Turn On Lights'),
      ),
      _buildUtilityButton(
        icon: Icons.lightbulb_outline,
        label: 'Turn Off Lights',
        color: AppTheme.deepForestGreen,
        onPressed: () => _sendTestCommand('/test_turn_off_lights', 'Turn Off Lights'),
      ),
      _buildUtilityButton(
        icon: Icons.power_settings_new,
        label: 'Restart Gadget',
        color: Colors.grey,
        onPressed: () => _confirmDestructiveAction(
          'Restart Gadget',
          'Are you sure you want to restart the gadget? This will temporarily disconnect all services.',
          () => _sendTestCommand('/test_restart_gadget', 'Restart Gadget'),
        ),
      ),
    ];
  }

  Widget _buildUtilityButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 160,
      child: ElevatedButton(
        onPressed: onPressed,
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

  Future<void> _confirmDestructiveAction(
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
} 