import 'package:flutter/material.dart';
import 'lesson_data.dart';

class EditClassScreen extends StatefulWidget {
  final Lesson lesson;

  const EditClassScreen({super.key, required this.lesson});

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  late TextEditingController nameController;
  late TextEditingController teacherController;
  late TextEditingController roomController;
  late TextEditingController timeController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.lesson.name);
    teacherController = TextEditingController(text: widget.lesson.teacher);
    roomController = TextEditingController(text: widget.lesson.room);
    timeController = TextEditingController(text: widget.lesson.time);
  }

  int parseStartTime(String time) {
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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "授業名"),
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
                final editedLesson = Lesson(
                  name: nameController.text,
                  teacher: teacherController.text,
                  room: roomController.text,
                  time: timeController.text,
                  startTime: parseStartTime(timeController.text), // ★ これが必須！
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
