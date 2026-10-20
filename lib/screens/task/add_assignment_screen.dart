import 'package:flutter/material.dart';
import 'task_data.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final titleController = TextEditingController();
  final subjectController = TextEditingController();
  final deadlineController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提出物追加')),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("課題名", style: TextStyle(fontSize: 16)),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "例：レポート"),
            ),

            const SizedBox(height: 20),

            const Text("科目名", style: TextStyle(fontSize: 16)),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(hintText: "例：情報"),
            ),

            const SizedBox(height: 20),

            const Text("締切", style: TextStyle(fontSize: 16)),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(hintText: "例：2026-08-09"),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 入力チェック
                  if (titleController.text.isEmpty ||
                      subjectController.text.isEmpty ||
                      deadlineController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("すべて入力してください")),
                    );
                    return;
                  }

                  // ★ Task を返す（ここが重要）
                  final newTask = Task(
                    title: titleController.text,
                    subject: subjectController.text,
                    deadline: deadlineController.text,
                  );

                  Navigator.pop(context, newTask);
                },
                child: const Text("追加する"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
