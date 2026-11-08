import 'package:flutter/material.dart';
import 'add_assignment_screen.dart';
import 'task_data.dart'; // ★ TaskData / TaskStorage を使う
import 'edit_assignument_screen.dart'; // ★ 課題編集画面を使う
import '../../data/repository/task_repository.dart';
import '../../data/repository/lesson_repository.dart';
import 'task_detail_screen.dart';

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
                        confirmDismiss: (_) async {
                          try {
                            await TaskRepository.delete(task);
                            return true;
                          } catch (error) {
                            if (!mounted) return false;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('課題の削除に失敗しました。$error')),
                            );
                            return false;
                          }
                        },
                        onDismissed: (_) {
                          setState(() {
                            TaskData.tasks.remove(task);
                          });
                        },
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Text("${task.subject} / ${task.deadline}"),
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(task: task),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: '編集',
                                onPressed: () async {
                                  final editedTask = await Navigator.push<Task>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditAssignmentScreen(task: task),
                                    ),
                                  );

                                  if (!mounted || editedTask == null) return;

                                  try {
                                    await TaskRepository.update(editedTask);
                                    if (!mounted) return;

                                    setState(() {
                                      final taskIndex = TaskData.tasks.indexOf(
                                        task,
                                      );
                                      if (taskIndex != -1) {
                                        TaskData.tasks[taskIndex] = editedTask;
                                      }
                                    });
                                  } catch (error) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('課題の更新に失敗しました：$error'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              Checkbox(
                                value: task.isDone,
                                onChanged: (value) async {
                                  if (value == null) return;

                                  try {
                                    await TaskRepository.updateIsDone(
                                      task: task,
                                      isDone: value,
                                    );
                                    if (!mounted) return;

                                    setState(() {
                                      task.isDone = value;
                                    });
                                  } catch (error) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('完了状態の更新に失敗しました。$error'),
                                      ),
                                    );
                                  }
                                },
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("課題を追加"),
        onPressed: () async {
          final result = await Navigator.push<Task>(
            context,
            MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
          );

          if (result == null) return;

          try {
            final savedTask = await TaskRepository.add(
              termId: LessonRepository.activeTermId,
              task: result,
            );
            if (!mounted) return;

            setState(() {
              TaskData.tasks.add(savedTask);
            });
          } catch (error) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('タスクの追加に失敗しました。$error')));
          }
        },
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
