import 'package:flutter/material.dart';

// その他画面

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: const Center(child: Text('設定画面', style: TextStyle(fontSize: 20))),
    );
  }
}
