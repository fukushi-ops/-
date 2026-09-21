import 'package:flutter/material.dart';

class EditClassScreen extends StatefulWidget {
  final Map<String, dynamic> lessonData;

  const EditClassScreen({super.key, required this.lessonData});

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
    nameController = TextEditingController(text: widget.lessonData["name"]);
    teacherController = TextEditingController(
      text: widget.lessonData["teacher"],
    );
    roomController = TextEditingController(text: widget.lessonData["room"]);
    timeController = TextEditingController(text: widget.lessonData["time"]);
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
                Navigator.pop(context, {
                  "name": nameController.text,
                  "teacher": teacherController.text,
                  "room": roomController.text,
                  "time": timeController.text,
                });
              },
              child: const Text("保存"),
            ),
          ],
        ),
      ),
    );
  }
}
