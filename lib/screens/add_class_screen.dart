import 'package:flutter/material.dart';
import 'lesson_data.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final nameController = TextEditingController();
  final teacherController = TextEditingController();
  final roomController = TextEditingController();
  final timeController = TextEditingController();

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
      appBar: AppBar(title: const Text("授業追加")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("授業名"),
            TextField(controller: nameController),

            const SizedBox(height: 20),
            const Text("先生"),
            TextField(controller: teacherController),

            const SizedBox(height: 20),
            const Text("教室"),
            TextField(controller: roomController),

            const SizedBox(height: 20),
            const Text("時間（例：9:00～10:30）"),
            TextField(controller: timeController),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty ||
                      teacherController.text.isEmpty ||
                      roomController.text.isEmpty ||
                      timeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("すべて入力してください")),
                    );
                    return;
                  }

                  // ★ Lesson を返す（ここが重要）
                  final newLesson = Lesson(
                    name: nameController.text,
                    teacher: teacherController.text,
                    room: roomController.text,
                    time: timeController.text,
                    startTime: parseStartTime(timeController.text),
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
