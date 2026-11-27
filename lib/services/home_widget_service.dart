import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../screens/class/lesson_data.dart';
import '../screens/task/task_data.dart';

class HomeWidgetService {
  static const _providerName = 'com.example.my_app.HomeWidgetProvider';

  static String encodeTasks(List<Task> tasks) {
    final pendingTasks =
        tasks
            .where((task) => !task.isDone)
            .map((task) {
              final deadline = DateTime.tryParse(
                task.deadline.trim(),
              )?.toLocal();
              if (deadline == null) return null;
              return {
                'title': task.title,
                'deadline': deadline.toIso8601String().substring(0, 10),
              };
            })
            .whereType<Map<String, String>>()
            .toList()
          ..sort((a, b) => a['deadline']!.compareTo(b['deadline']!));
    return jsonEncode(pendingTasks);
  }

  static String encodeLessons(Map<String, List<Lesson>> lessonsByDay) {
    return jsonEncode({
      for (final entry in lessonsByDay.entries)
        entry.key:
            (List<Lesson>.of(entry.value)
                  ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber)))
                .map(
                  (lesson) => {
                    'name': lesson.name,
                    'time': '${lesson.periodNumber}限',
                  },
                )
                .toList(),
    });
  }

  static void refreshInBackground() {
    if (!Platform.isAndroid) return;
    refresh().catchError((Object error, StackTrace stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'home screen widget',
          context: ErrorDescription('while refreshing the Android widget'),
        ),
      );
    });
  }

  static Future<void> refresh() async {
    if (!Platform.isAndroid) return;

    final tasksSaved = await HomeWidget.saveWidgetData<String>(
      'widget_tasks',
      encodeTasks(TaskData.tasks),
    );
    if (tasksSaved == false) {
      throw StateError('ウィジェットの課題データを保存できませんでした。');
    }

    final lessonsSaved = await HomeWidget.saveWidgetData<String>(
      'widget_lessons',
      encodeLessons(LessonData.lessonsByDay),
    );
    if (lessonsSaved == false) {
      throw StateError('ウィジェットの授業データを保存できませんでした。');
    }

    final updated = await HomeWidget.updateWidget(
      qualifiedAndroidName: _providerName,
    );
    if (updated == false) {
      throw StateError('ホーム画面ウィジェットを更新できませんでした。');
    }
  }
}
