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
  String selectedDay = "月";

  @override
  Widget build(BuildContext context) {
    final todayClassList = LessonData.lessonsByDay[selectedDay]!;

    return Scaffold(
      appBar: AppBar(title: const Text('授業一覧')),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: selectedDay,
              items: ["月", "火", "水", "木", "金", "土", "日"].map((day) {
                return DropdownMenuItem(value: day, child: Text(day));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value!;
                });
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: todayClassList.length,
              itemBuilder: (context, index) {
                final lesson = todayClassList[index];

                return Dismissible(
                  key: ValueKey("${lesson.name}_${lesson.time}"),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    setState(() {
                      LessonData.lessonsByDay[selectedDay]!.removeAt(index);
                    });
                    LessonStorage.save();
                  },

                  child: ListTile(
                    title: Text(lesson.name),
                    subtitle: Text(
                      "${lesson.room} / ${lesson.teacher} / ${lesson.time}",
                    ),

                    // ★ 編集画面へ
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditClassScreen(
                            lesson: lesson, // ★ Lesson を渡す
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          todayClassList[index] = result; // ★ Lesson をそのまま置き換え
                        });
                        LessonStorage.save();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClassScreen()),
          );

          if (result != null) {
            setState(() {
              LessonData.lessonsByDay[selectedDay]!.add(
                result,
              ); // ★ Lesson をそのまま追加
            });
            LessonStorage.save();
          }
        },
      ),
    );
  }
}
