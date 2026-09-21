import 'package:flutter/material.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController teacherController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('授業追加')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '授業名'),
            ),
            TextField(
              controller: teacherController,
              decoration: const InputDecoration(labelText: '先生'),
            ),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(labelText: '教室'),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: '時間（例：9:00〜10:30）'),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "name": nameController.text,
                  "teacher": teacherController.text,
                  "room": roomController.text,
                  "time": timeController.text,
                });
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
