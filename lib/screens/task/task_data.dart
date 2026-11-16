import 'package:flutter/foundation.dart';

class Task {
  int? id; // ISAR上で編集・削除する課題を特定するID
  String title; // 課題名
  String subject; // 科目名
  String deadline; // 締切
  bool isDone; // 提出済みかどうか
  int priority;
  int progress;
  String workMemo;
  List<TaskChecklistItem> checklist;

  // 自己評価・振り返り
  int? reflectionScore;
  String? reflectionDifficulty;
  String? reflectionLearned;
  String? reflectionGoodPoint;
  String? reflectionImprovement;

  Task({
    this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    this.isDone = false,
    this.priority = 2,
    this.progress = 0,
    this.workMemo = '',
    this.checklist = const [],
    this.reflectionScore,
    this.reflectionDifficulty,
    this.reflectionLearned,
    this.reflectionGoodPoint,
    this.reflectionImprovement,
  });

  String get progressStatus => isDone
      ? '提出済み'
      : progress > 0
      ? '取り組み中'
      : '未着手';

  Task copyWith({
    String? title,
    String? subject,
    String? deadline,
    bool? isDone,
    int? priority,
    int? progress,
    String? workMemo,
    List<TaskChecklistItem>? checklist,
    int? reflectionScore,
    String? reflectionDifficulty,
    String? reflectionLearned,
    String? reflectionGoodPoint,
    String? reflectionImprovement,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      deadline: deadline ?? this.deadline,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      workMemo: workMemo ?? this.workMemo,
      checklist: checklist ?? this.checklist,
      reflectionScore: reflectionScore ?? this.reflectionScore,
      reflectionDifficulty: reflectionDifficulty ?? this.reflectionDifficulty,
      reflectionLearned: reflectionLearned ?? this.reflectionLearned,
      reflectionGoodPoint: reflectionGoodPoint ?? this.reflectionGoodPoint,
      reflectionImprovement:
          reflectionImprovement ?? this.reflectionImprovement,
    );
  }
}

class TaskChecklistItem {
  const TaskChecklistItem({required this.title, this.isDone = false});

  final String title;
  final bool isDone;
}

class TaskData {
  static final ValueNotifier<Object?> changed = ValueNotifier<Object?>(null);
  static List<Task> tasks = [];

  static void notifyChanged() {
    changed.value = Object();
  }

  static bool removeTask(Task task) {
    final removed = tasks.remove(task);
    if (removed) notifyChanged();
    return removed;
  }
}

class TaskArtifact {
  const TaskArtifact({
    required this.name,
    required this.description,
    required this.location,
  });

  final String name;
  final String description;
  final String location;
}
