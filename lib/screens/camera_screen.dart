import 'package:flutter/material.dart';
import '../widgets/camera_feed.dart';
import '../services/ip_storage_service.dart';

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
      appBar: AppBar(
        title: const Text('Camera Feeds'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Camera IP',
                      hintText: 'e.g., 192.168.1.100',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
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
            child: ListView.builder(
              itemCount: _cameraIPs.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Camera ${index + 1}'),
                        subtitle: Text(_cameraIPs[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _ipStorage.removeIP(_cameraIPs[index]);
                            await _loadIPs();
                          },
                        ),
                      ),
                      SizedBox(
                        height: 240,
                        child: CameraFeed(
                          ipAddress: _cameraIPs[index],
                          refreshRate: const Duration(milliseconds: 50),
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