import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'add_class_screen.dart';
import 'edit_class_screen.dart';
import 'lesson_data.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  static const _days = ["月", "火", "水", "木", "金", "土", "日"];
  String selectedDay = "月";

  Future<void> _saveLessons() async {
    try {
      await LessonStorage.save();
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebaseへの保存に失敗しました: ${error.message ?? error.code}'),
          action: SnackBarAction(label: '再試行', onPressed: _saveLessons),
        ),
      );
    }
  }

  Future<void> _addLesson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddClassScreen()),
    );

    if (result != null) {
      setState(() {
        LessonData.lessonsByDay[selectedDay]!.add(result);
      });
      await _saveLessons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = LessonData.lessonsByDay[selectedDay]!;
    final sortedLessons = List.of(lessons)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(title: const Text('授業一覧'), centerTitle: true),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final day = _days[index];
                return ChoiceChip(
                  label: Text('$day曜日'),
                  selected: selectedDay == day,
                  onSelected: (_) {
                    setState(() {
                      selectedDay = day;
                    });
                  },
                );
              },
            ),
          ),
          Expanded(
            child: sortedLessons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$selectedDay曜日の授業はありません',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text('＋ボタンから授業を登録できます'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: sortedLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = sortedLessons[index];
                      return Dismissible(
                        key: ObjectKey(lesson),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) async {
                          setState(() {
                            lessons.remove(lesson);
                          });
                          await _saveLessons();
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              radius: 28,
                              child: Text(
                                '${index + 1}\n限目',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            title: Text(
                              lesson.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LessonDetail(
                                    icon: Icons.access_time,
                                    text: lesson.time,
                                  ),
                                  const SizedBox(height: 4),
                                  _LessonDetail(
                                    icon: Icons.meeting_room_outlined,
                                    text: lesson.room,
                                  ),
                                  const SizedBox(height: 4),
                                  _LessonDetail(
                                    icon: Icons.person_outline,
                                    text: lesson.teacher,
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditClassScreen(lesson: lesson),
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  final lessonIndex = lessons.indexOf(lesson);
                                  if (lessonIndex != -1) {
                                    lessons[lessonIndex] = result;
                                  }
                                });
                                await _saveLessons();
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLesson,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LessonDetail extends StatelessWidget {
  const _LessonDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }
}
