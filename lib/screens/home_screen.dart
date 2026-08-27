import 'package:flutter/material.dart';
import 'class_screen.dart';
import 'assignment_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('授業・提出物管理')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('授業一覧'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClassScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              child: const Text('提出物一覧'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssignmentScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
