import 'package:flutter/material.dart';

class DevMenu extends StatelessWidget {
  const DevMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.developer_mode),
      onPressed: () {
        // TODO: Implement dev menu
      },
    );
  }
} 