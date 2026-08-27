import 'package:flutter/material.dart';

class AddAssignmentScreen extends StatelessWidget {
  const AddAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提出物追加')),
      body: const Center(child: Text('提出物追加フォーム')),
    );
  }
}
