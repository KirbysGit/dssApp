import 'package:flutter/material.dart';

class AlertList extends StatelessWidget {
  const AlertList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3, // Mock data count
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text('Mock Alert ${index + 1}'),
          subtitle: Text('Sample alert description ${index + 1}'),
          trailing: Text('${DateTime.now().hour}:${DateTime.now().minute}'),
        );
      },
    );
  }
} 