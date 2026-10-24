import 'package:flutter/material.dart';
import 'task_data.dart';

class EditAssignmentScreen extends StatefulWidget {
  final Task task;

  const EditAssignmentScreen({super.key, required this.task});

  @override
  State<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends State<EditAssignmentScreen> {
  late TextEditingController _titleController;
  late TextEditingController _subjectController;
  late TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _subjectController = TextEditingController(text: widget.task.subject);
    _deadlineController = TextEditingController(text: widget.task.deadline);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('課題編集')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '課題名'),
            ),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: '教科'),
            ),
            TextField(
              controller: _deadlineController,
              decoration: const InputDecoration(labelText: '締切日'),
            ),
            ElevatedButton(
              onPressed: () {
                // 編集された課題を保存
                widget.task.title = _titleController.text;
                widget.task.subject = _subjectController.text;
                widget.task.deadline = _deadlineController.text;
                TaskStorage.save();
                Navigator.pop(context, widget.task); // 編集された課題を返す
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
