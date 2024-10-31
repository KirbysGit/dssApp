import 'package:flutter/material.dart';
import 'camera_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32-CAM Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32-CAM Viewer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const CameraView(
        ipAddress: '172.20.10.3', // Replace with your ESP32-CAM's IP address
      ),
    );
  }
}
