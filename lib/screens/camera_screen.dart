import 'package:flutter/material.dart';
import '../widgets/camera_feed.dart';
import '../services/ip_storage_service.dart';
import '../theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final IPStorageService _ipStorage = IPStorageService();
  List<String> _cameraIPs = [];
  final _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIPs();
  }

  Future<void> _loadIPs() async {
    final ips = await _ipStorage.getIPs();
    setState(() {
      _cameraIPs = ips;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mistGray,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.pineGreen, size: 32),
            const SizedBox(width: 12),
            const Text('Camera Feeds'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: AppTheme.cardDecoration,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Enter Camera IP',
                      labelStyle: TextStyle(color: AppTheme.deepForestGreen),
                      hintText: 'e.g., 192.168.1.100',
                      hintStyle: TextStyle(
                        color: AppTheme.deepForestGreen.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.pineGreen),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.pineGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.deepForestGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(
                    Icons.add_circle,
                    color: AppTheme.pineGreen,
                    size: 32,
                  ),
                  onPressed: () async {
                    if (_ipController.text.isNotEmpty) {
                      await _ipStorage.addIP(_ipController.text);
                      _ipController.clear();
                      await _loadIPs();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _cameraIPs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 64,
                          color: AppTheme.deepForestGreen.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No cameras added yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.deepForestGreen.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a camera IP address above to get started',
                          style: TextStyle(
                            color: AppTheme.deepForestGreen.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cameraIPs.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                'Camera ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.deepForestGreen,
                                ),
                              ),
                              subtitle: Text(
                                _cameraIPs[index],
                                style: TextStyle(
                                  color: AppTheme.deepForestGreen.withOpacity(0.7),
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: AppTheme.pineGreen,
                                ),
                                onPressed: () async {
                                  await _ipStorage.removeIP(_cameraIPs[index]);
                                  await _loadIPs();
                                },
                              ),
                            ),
                            Container(
                              height: 240,
                              decoration: BoxDecoration(
                                color: AppTheme.deepForestGreen.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                child: CameraFeed(
                                  ipAddress: _cameraIPs[index],
                                  refreshRate: const Duration(milliseconds: 50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 