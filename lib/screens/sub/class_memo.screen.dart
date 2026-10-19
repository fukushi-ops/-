import 'package:flutter/material.dart';

class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('メモ'),
      ),
      body: const Center(child: Text('メモ画面', style: TextStyle(fontSize: 20))),
    );
  }
}
