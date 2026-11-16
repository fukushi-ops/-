import 'package:flutter/material.dart';

import 'lesson_data.dart';

class TimetableImportReviewScreen extends StatefulWidget {
  const TimetableImportReviewScreen({super.key, required this.lessons});

  final List<LessonImport> lessons;

  @override
  State<TimetableImportReviewScreen> createState() =>
      _TimetableImportReviewScreenState();
}

class _TimetableImportReviewScreenState
    extends State<TimetableImportReviewScreen> {
  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  late final List<_EditableLesson> _lessons;

  @override
  void initState() {
    super.initState();
    _lessons = widget.lessons.map(_EditableLesson.fromImport).toList();
  }

  @override
  void dispose() {
    for (final lesson in _lessons) {
      lesson.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_lessons.any((lesson) => lesson.name.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('授業名が空の行があります。内容を確認してください。')),
      );
      return;
    }

    Navigator.pop(
      context,
      _lessons
          .map(
            (item) => LessonImport(
              weekday: item.weekday,
              lesson: Lesson(
                name: item.name.text.trim(),
                teacher: item.teacher.text.trim(),
                room: item.room.text.trim(),
                time: item.time.text.trim(),
                startTime: _parseStartTime(item.time.text, item.startTime),
              ),
            ),
          )
          .toList(),
    );
  }

  int _parseStartTime(String value, int fallback) {
    final period = RegExp(r'^\s*(\d{1,2})\s*限').firstMatch(value);
    if (period != null) return int.parse(period.group(1)!) * 100;

    final clock = RegExp(r'^\s*(\d{1,2}):(\d{2})').firstMatch(value);
    if (clock != null) {
      return int.parse(clock.group(1)!) * 100 + int.parse(clock.group(2)!);
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('読み取り結果の確認')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text('画像から読み取った授業です。曜日・授業名を確認してください。先生と教室は必要に応じて入力できます。'),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final item = _lessons[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: item.weekday,
                          decoration: const InputDecoration(labelText: '曜日'),
                          items: _weekdays
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day,
                                  child: Text('$day曜日'),
                                ),
                              )
                              .toList(),
                          onChanged: (day) {
                            if (day != null) item.weekday = day;
                          },
                        ),
                        TextField(
                          controller: item.name,
                          decoration: const InputDecoration(labelText: '授業名'),
                        ),
                        TextField(
                          controller: item.time,
                          decoration: const InputDecoration(
                            labelText: '時刻または時限（例：9:00～10:30、1限目）',
                          ),
                        ),
                        TextField(
                          controller: item.teacher,
                          decoration: const InputDecoration(
                            labelText: '先生（任意）',
                          ),
                        ),
                        TextField(
                          controller: item.room,
                          decoration: const InputDecoration(
                            labelText: '教室（任意）',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('この内容で追加'),
      ),
    );
  }
}

class _EditableLesson {
  _EditableLesson({
    required this.weekday,
    required this.name,
    required this.teacher,
    required this.room,
    required this.time,
    required this.startTime,
  });

  factory _EditableLesson.fromImport(LessonImport item) {
    return _EditableLesson(
      weekday: item.weekday,
      name: TextEditingController(text: item.lesson.name),
      teacher: TextEditingController(text: item.lesson.teacher),
      room: TextEditingController(text: item.lesson.room),
      time: TextEditingController(text: item.lesson.time),
      startTime: item.lesson.startTime,
    );
  }

  String weekday;
  final TextEditingController name;
  final TextEditingController teacher;
  final TextEditingController room;
  final TextEditingController time;
  final int startTime;

  void dispose() {
    name.dispose();
    teacher.dispose();
    room.dispose();
    time.dispose();
  }
}
