import 'package:flutter/material.dart';

import '../class/lesson_data.dart';
import 'attendance_data.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadAttendance(showLoading: false);
  }

  Future<void> _loadAttendance({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        isLoading = true;
        loadError = null;
      });
    }

    try {
      await AttendanceStorage.load();
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadError = error.toString();
      });
    }
  }

  Future<void> _changeStatus(Lesson lesson, AttendanceStatus? status) async {
    final save = AttendanceStorage.setStatus(selectedDate, lesson, status);
    setState(() {});

    try {
      await save;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('出席状況を保存できませんでした: $error')));
    }
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: today,
    );

    if (selected != null) {
      setState(() {
        selectedDate = DateUtils.dateOnly(selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekday = _weekday(selectedDate.weekday);
    final lessons = List<Lesson>.from(
      LessonData.lessonsByDay[weekday] ?? const <Lesson>[],
    )..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(title: const Text('出席状況')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('出席記録を読み込めませんでした。'),
                    const SizedBox(height: 8),
                    Text(loadError!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAttendance,
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: '前の日',
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.subtract(
                              const Duration(days: 1),
                            );
                          });
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      TextButton(
                        onPressed: _selectDate,
                        child: Text(
                          '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日（$weekday）',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: '次の日',
                        onPressed:
                            DateUtils.isSameDay(selectedDate, DateTime.now())
                            ? null
                            : () {
                                setState(() {
                                  selectedDate = selectedDate.add(
                                    const Duration(days: 1),
                                  );
                                });
                              },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: lessons.isEmpty
                      ? const Center(child: Text('この日の授業は登録されていません'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: lessons.length,
                          itemBuilder: (context, index) {
                            final lesson = lessons[index];
                            final status = AttendanceStorage.statusFor(
                              selectedDate,
                              lesson,
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${lesson.time} · ${lesson.room} · ${lesson.teacher}',
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      children: AttendanceStatus.values
                                          .map(
                                            (option) => ChoiceChip(
                                              label: Text(option.label),
                                              selected: status == option,
                                              onSelected: (_) =>
                                                  _changeStatus(lesson, option),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    if (status != null)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () =>
                                              _changeStatus(lesson, null),
                                          child: const Text('記録を取り消す'),
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
    );
  }
}

class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('メモ'),
      ),
      body: const Center(child: Text('メモ画面', style: TextStyle(fontSize: 20))),
    );
  }
}

String _weekday(int weekday) {
  const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  return weekdays[weekday - 1];
}
