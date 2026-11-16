import 'package:flutter/material.dart';

import 'class/class_screen.dart';
import 'home_screen.dart';
import 'class/lesson_data.dart';
import '../data/repository/lesson_repository.dart';
import '../data/repository/subject_repository.dart';
import '../data/repository/task_repository.dart';
import '../services/simple_notification_service.dart';
import 'task/assignment_screen.dart';
import 'task/learning_history_screen.dart';
import 'task/task_data.dart';

class MainScreen extends StatefulWidget {
  final String userName;

  const MainScreen({super.key, required this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _homeRefreshToken = 0;

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _homeRefreshToken++;
    });
  }

  Future<void> _selectTerm(int termId) async {
    final lessonsByDay = await LessonRepository.loadLessons(termId: termId);
    final tasks = await TaskRepository.load(termId: termId);
    await SubjectRepository.importExisting(termId: termId);
    await LessonRepository.selectTerm(termId: termId);
    if (!mounted) return;

    setState(() {
      for (final day in LessonData.lessonsByDay.keys) {
        LessonData.lessonsByDay[day]!
          ..clear()
          ..addAll(lessonsByDay[day]!);
      }
      TaskData.tasks = tasks;
      TaskData.notifyChanged();
      _homeRefreshToken++;
    });

    try {
      await NotificationService.syncTaskDeadlineNotifications(tasks);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('期間は切り替えましたが、締切通知の更新に失敗しました: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        userName: widget.userName,
        onSelectTab: _selectTab,
        onTermSelected: _selectTerm,
        refreshToken: _homeRefreshToken,
      ),
      ClassScreen(onTermSelected: _selectTerm),
      AssignmentScreen(onTermSelected: _selectTerm),
      LearningHistoryScreen(onTermSelected: _selectTerm),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _selectTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '時間割',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '課題'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '分析'),
        ],
      ),
    );
  }
}
