import 'package:flutter/material.dart';
import '../widgets/camera_feed.dart';
import '../widgets/security_card.dart';

class PhotosPage extends StatefulWidget {
  const PhotosPage({Key? key}) : super(key: key);

  @override
  State<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  final List<String> _cameraIPs = ['172.20.10.7']; // Add your camera IPs here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Feeds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCameraDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SecurityCard(
            title: 'Live Feeds',
            child: Column(
              children: _cameraIPs.map((ip) => _buildCameraCard(ip)).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SecurityCard(
            title: 'Captured Images',
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 4, // Replace with actual image count
              itemBuilder: (context, index) {
                return _buildCapturedImageCard(index);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _captureImages(),
        child: const Icon(Icons.camera),
      ),
    );
  }

  Widget _buildCameraCard(String ip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.videocam),
                const SizedBox(width: 8),
                Text('Camera Feed - $ip'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeCamera(ip),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 4/3,
            child: CameraFeed(
              ipAddress: ip,
              refreshRate: const Duration(milliseconds: 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImageCard(int index) {
    return Card(
      child: InkWell(
        onTap: () => _showImageDetail(index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Image ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateTime.now().toString().split('.')[0],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCameraDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Camera'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Camera IP Address',
            hintText: 'Enter IP address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _cameraIPs.add(controller.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeCamera(String ip) {
    setState(() => _cameraIPs.remove(ip));
  }

  void _showImageDetail(int index) {
    // TODO: Implement image detail view
  }

  void _captureImages() {
    // TODO: Implement capture from all cameras
  }
} 