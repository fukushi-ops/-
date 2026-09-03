import 'package:flutter/material.dart';
import 'schedule.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final titleController = TextEditingController();
  int startDay = 1;
  int endDay = 1;
  Color selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("予定を追加")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "予定名（例：冬休み）"),
            ),

            const SizedBox(height: 16),
            const Text("開始日"),
            DropdownButton<int>(
              value: startDay,
              items: List.generate(31, (i) => i + 1)
                  .map((d) => DropdownMenuItem(value: d, child: Text("$d日")))
                  .toList(),
              onChanged: (v) => setState(() => startDay = v!),
            ),

            const SizedBox(height: 16),
            const Text("終了日"),
            DropdownButton<int>(
              value: endDay,
              items: List.generate(31, (i) => i + 1)
                  .map((d) => DropdownMenuItem(value: d, child: Text("$d日")))
                  .toList(),
              onChanged: (v) => setState(() => endDay = v!),
            ),

            const SizedBox(height: 16),
            const Text("色を選択"),
            Row(
              children: [
                _colorBox(Colors.blue),
                _colorBox(Colors.pink),
                _colorBox(Colors.yellow),
                _colorBox(Colors.green),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              child: const Text("追加"),
              onPressed: () {
                Navigator.pop(
                  context,
                  Schedule(
                    title: titleController.text,
                    startDay: startDay,
                    endDay: endDay,
                    color: selectedColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorBox(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
