import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'add_class_screen.dart';
import 'edit_class_screen.dart';
import 'lesson_data.dart';

class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key});

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  // 授業一覧に表示する曜日。画面を開いた直後は月曜日を表示する。
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

  @override
  Widget build(BuildContext context) {
    // 選択中の曜日に登録されている授業を取得する。
    final todayClassList = LessonData.lessonsByDay[selectedDay]!;

    return Scaffold(
      appBar: AppBar(title: const Text('授業一覧')),

      body: Column(
        children: [
          // 表示する曜日を選ぶドロップダウン。
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: selectedDay,
              // 各曜日の文字列を、ドロップダウンの選択項目に変換する。
              items: ["月", "火", "水", "木", "金", "土", "日"].map((day) {
                return DropdownMenuItem(value: day, child: Text(day));
              }).toList(),
              // 曜日が選ばれたら選択状態を更新し、画面を再描画する。
              onChanged: (value) {
                setState(() {
                  selectedDay = value!;
                });
              },
            ),
          ),

          // 選択中の曜日の授業を一覧表示する。
          Expanded(
            child: ListView.builder(
              itemCount: todayClassList.length,
              itemBuilder: (context, index) {
                final lesson = todayClassList[index];

                // 左にスワイプすると、この授業を削除する。
                return Dismissible(
                  key: ValueKey("${lesson.name}_${lesson.time}"),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    setState(() {
                      // 選択中の曜日のリストから授業を取り除く。
                      LessonData.lessonsByDay[selectedDay]!.removeAt(index);
                    });
                    // 変更した授業一覧をFirebaseに保存する。
                    await _saveLessons();
                  },

                  child: ListTile(
                    title: Text(lesson.name),
                    subtitle: Text(
                      "${lesson.room} / ${lesson.teacher} / ${lesson.time}",
                    ),

                    // 授業をタップすると編集画面を開き、編集後の授業を受け取る。
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
                          // 編集後の授業で一覧の元の項目を置き換える。
                          todayClassList[index] = result;
                        });
                        await _saveLessons();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 「＋」ボタンから授業追加画面を開く。
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddClassScreen()),
          );

          if (result != null) {
            setState(() {
              // 追加画面から戻ってきた授業を、選択中の曜日に登録する。
              LessonData.lessonsByDay[selectedDay]!.add(result);
            });
            // 追加した授業をFirebaseに保存する。
            await _saveLessons();
          }
        },
      ),
    );
  }
}
