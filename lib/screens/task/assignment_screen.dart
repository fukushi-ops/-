import 'package:flutter/material.dart';
import 'add_assignment_screen.dart';
import 'task_data.dart'; // ★ TaskData / TaskStorage を使う
import 'EditAssingumentScreen.dart'; // ★ 課題編集画面を使う

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  int selectedIndex = 0; // 0:すべて 1:未提出 2:提出済み

  @override
  Widget build(BuildContext context) {
    // 選択中のタブに応じて、表示する課題を変更
    List<Task> filteredTasks = _getFilteredTasks();

    return Scaffold(
      // ★ AppBar に戻るボタンを追加
      appBar: AppBar(
        title: const Text(
          '課題一覧',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          const SizedBox(height: 8),
          // タブボタンの行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('すべて', 0),
              _buildTabButton('未提出', 1),
              _buildTabButton('提出済み', 2),
            ],
          ),
          // タブボタンの下に、選択中のタブに応じた課題一覧を表示
          Expanded(
            // ★ filteredTasks が空の場合は「課題はありません」と表示する。
            child: filteredTasks.isEmpty
                ? const Center(
                    child: Text('課題はありません', style: TextStyle(fontSize: 16)),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      // ★ Dismissible で左にスワイプすると削除できるようにする。
                      return Dismissible(
                        key: ValueKey(task.title),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        // 左にスワイプすると、この課題を削除する。
                        onDismissed: (_) {
                          setState(() {
                            TaskData.tasks.remove(task);
                          });
                          TaskStorage.save(); // ★ 削除したら保存
                        },
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Text("${task.subject} / ${task.deadline}"),
                          onTap: () async {
                            final editedTask = await Navigator.push<Task>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditAssignmentScreen(task: task),
                              ),
                            );
                            if (!mounted || editedTask == null) return;
                            setState(() {
                              task.title = editedTask.title;
                              task.subject = editedTask.subject;
                              task.deadline = editedTask.deadline;
                            });
                            await TaskStorage.save();
                          },
                          trailing: Checkbox(
                            value: task.isDone,
                            onChanged: (value) {
                              setState(() {
                                task.isDone = value!;
                              });
                              TaskStorage.save(); // ★ 完了状態変更も保存
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
          );

          if (result != null) {
            setState(() {
              TaskData.tasks.add(result);
            });

            TaskStorage.save(); // ★ 保存
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // ★ タブごとのフィルタ処理
  List<Task> _getFilteredTasks() {
    if (selectedIndex == 1) {
      return TaskData.tasks.where((t) => !t.isDone).toList();
    } else if (selectedIndex == 2) {
      return TaskData.tasks.where((t) => t.isDone).toList();
    }
    return TaskData.tasks;
  }

  // タブボタン
  Widget _buildTabButton(String text, int index) {
    final bool isSelected = selectedIndex == index;
    // タップ時の処理を追加して、選択中のタブを更新するようにします。
    return GestureDetector(
      // タップされたときに選択中のタブを更新
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        width: 80,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan : Colors.white,
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
