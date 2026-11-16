import 'package:flutter/material.dart';

import '../../data/repository/lesson_repository.dart';
import '../../widgets/subject_dropdown_field.dart';
import 'lesson_data.dart';

class EditClassScreen extends StatefulWidget {
  final Lesson lesson;

  const EditClassScreen({super.key, required this.lesson});

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  String? _selectedSubject;
  late TextEditingController teacherController;
  late TextEditingController roomController;
  late TextEditingController timeController;

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.lesson.name;
    teacherController = TextEditingController(text: widget.lesson.teacher);
    roomController = TextEditingController(text: widget.lesson.room);
    timeController = TextEditingController(text: widget.lesson.time);
  }

  @override
  void dispose() {
    teacherController.dispose();
    roomController.dispose();
    timeController.dispose();
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
      appBar: AppBar(title: const Text("授業編集")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SubjectDropdownField(
              termId: LessonRepository.activeTermId,
              initialValue: _selectedSubject,
              onChanged: (subject) => setState(() {
                _selectedSubject = subject;
              }),
            ),
            TextField(
              controller: teacherController,
              decoration: const InputDecoration(labelText: "先生"),
            ),
            TextField(
              controller: roomController,
              decoration: const InputDecoration(labelText: "教室"),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: "時間（例：9:00～10:30）"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (_selectedSubject == null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('科目を選択してください')));
                  return;
                }
                final editedLesson = Lesson(
                  name: _selectedSubject!,
                  teacher: teacherController.text,
                  room: roomController.text,
                  time: timeController.text,
                  startTime: parseStartTime(timeController.text),
                  courseId: widget.lesson.courseId,
                  lessonId: widget.lesson.lessonId,
                );

                Navigator.pop(context, editedLesson);
              },
              child: const Text("保存"),
            ),
          ],
        ),
      ),
    );
  }
}
