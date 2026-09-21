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
                  },

                  child: ListTile(
                    title: Text(lesson.name),
                    subtitle: Text(
                      "${lesson.room} / ${lesson.teacher} / ${lesson.time}",
                    ),

                    // ★ タップで編集画面へ
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditClassScreen(
                            lessonData: {
                              "name": lesson.name,
                              "teacher": lesson.teacher,
                              "room": lesson.room,
                              "time": lesson.time,
                            },
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          todayClassList[index] = Lesson(
                            name: result["name"],
                            teacher: result["teacher"],
                            room: result["room"],
                            time: result["time"],
                            startTime: parseStartTime(result["time"]),
                          );
                        });
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
            MaterialPageRoute(builder: (context) => const AddClassScreen()),
          );

          if (result != null) {
            setState(() {
              LessonData.lessonsByDay[selectedDay]!.add(
                Lesson(
                  name: result["name"],
                  teacher: result["teacher"],
                  room: result["room"],
                  time: result["time"],
                  startTime: parseStartTime(result["time"]),
                ),
              );
            });
          }
        },
      ),
    );
  }
}
