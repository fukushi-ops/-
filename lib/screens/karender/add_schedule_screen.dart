import 'package:flutter/material.dart';

import 'schedule.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final titleController = TextEditingController();
  DateTime startDate = DateUtils.dateOnly(DateTime.now());
  DateTime endDate = DateUtils.dateOnly(DateTime.now());
  Color selectedColor = Colors.blue;

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );

    if (selected == null) return;

    setState(() {
      startDate = DateUtils.dateOnly(selected);
      if (endDate.isBefore(startDate)) {
        endDate = startDate;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2100, 12, 31),
    );

    if (selected == null) return;

    setState(() {
      endDate = DateUtils.dateOnly(selected);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('予定を追加')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '予定名（例：冬休み）'),
            ),
            const SizedBox(height: 16),
            const Text('開始日'),
            TextButton(
              onPressed: _selectStartDate,
              child: Text(_formatDate(startDate)),
            ),
            const SizedBox(height: 16),
            const Text('終了日'),
            TextButton(
              onPressed: _selectEndDate,
              child: Text(_formatDate(endDate)),
            ),
            const SizedBox(height: 16),
            const Text('色を選択'),
            Row(
              children: [
                _colorBox(Colors.blue),
                _colorBox(Colors.pink),
                _colorBox(Colors.yellow),
                _colorBox(Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('予定名を入力してください')),
                    );
                    return;
                  }

                  Navigator.pop(
                    context,
                    Schedule(
                      title: title,
                      startDate: startDate,
                      endDate: endDate,
                      color: selectedColor,
                    ),
                  );
                },
                child: const Text('追加'),
              ),
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
