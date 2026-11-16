import 'package:flutter/material.dart';

import '../../data/repository/lesson_repository.dart';
import '../../widgets/subject_dropdown_field.dart';
import 'task_deadline_picker.dart';
import 'task_data.dart';

class AddAssignmentScreen extends StatefulWidget {
  const AddAssignmentScreen({super.key});

  @override
  State<AddAssignmentScreen> createState() => _AddAssignmentScreenState();
}

class _AddAssignmentScreenState extends State<AddAssignmentScreen> {
  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  String? _selectedSubject;

  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    super.dispose();
  }

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

            SubjectDropdownField(
              termId: LessonRepository.activeTermId,
              onChanged: (subject) => setState(() {
                _selectedSubject = subject;
              }),
            ),

            const SizedBox(height: 20),

            const Text("締切", style: TextStyle(fontSize: 16)),
            TextField(
              controller: deadlineController,
              readOnly: true,
              onTap: _selectDeadline,
              decoration: InputDecoration(
                hintText: '日付を選択',
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: IconButton(
                  tooltip: '日付を選択',
                  onPressed: _selectDeadline,
                  icon: const Icon(Icons.calendar_month),
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  final subject = _selectedSubject;
                  if (subject == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("科目を選択してください")),
                    );
                    return;
                  }
                  if (titleController.text.trim().isEmpty ||
                      deadlineController.text.trim().isEmpty) {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger?.showSnackBar(
                      const SnackBar(content: Text("すべて入力してください")),
                    );
                    return;
                  }

                  final newTask = Task(
                    title: titleController.text.trim(),
                    subject: subject,
                    deadline: deadlineController.text.trim(),
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

  Future<void> _selectDeadline() async {
    final selected = await selectTaskDeadline(context);
    if (selected == null || !mounted) return;
    deadlineController.text = formatTaskDeadline(selected);
  }
}
