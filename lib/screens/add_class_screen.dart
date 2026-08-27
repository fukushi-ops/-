import 'package:flutter/material.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('授業追加')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '授業名'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
