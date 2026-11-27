import 'package:flutter/material.dart';

import '../../data/repository/lesson_repository.dart';
import '../../widgets/subject_dropdown_field.dart';
import 'lesson_data.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key, required this.periodNumber});

  final int periodNumber;

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  String? _selectedSubject;
  final roomController = TextEditingController();

  @override
  void dispose() {
    roomController.dispose();
    super.dispose();
  }

  int parseStartTime(String time) {
    final period = RegExp(r'^\s*(\d{1,2})\s*限').firstMatch(time);
    if (period != null) return int.parse(period.group(1)!) * 100;

    final separators = ["～", "〜", "~", "-", "ー"];
    String start = time;

    for (var s in separators) {
      if (time.contains(s)) {
        start = time.split(s)[0];
        break;
      }
    }

    final parts = start.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return hour * 100 + minute;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("授業追加")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SubjectDropdownField(
              termId: LessonRepository.activeTermId,
              onChanged: (subject) => setState(() {
                _selectedSubject = subject;
              }),
            ),

            const SizedBox(height: 20),
            const Text("教室"),
            TextField(controller: roomController),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  final subject = _selectedSubject;
                  if (subject == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('科目を選択してください')),
                    );
                    return;
                  }
                  if (roomController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('教室を入力してください')),
                    );
                    return;
                  }

                  final newLesson = Lesson(
                    name: subject,
                    room: roomController.text.trim(),
                    periodNumber: widget.periodNumber,
                  );

                  Navigator.pop(context, newLesson);
                },
                child: const Text("保存"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
