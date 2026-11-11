import 'package:flutter/foundation.dart';

class Task {
  int? id; // ISAR上で編集・削除する課題を特定するID
  String title; // 課題名
  String subject; // 科目名
  String deadline; // 締切
  bool isDone; // 提出済みかどうか

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
    this.reflectionScore,
    this.reflectionDifficulty,
    this.reflectionLearned,
    this.reflectionGoodPoint,
    this.reflectionImprovement,
  });
}

class TaskData {
  static final ValueNotifier<Object?> changed = ValueNotifier<Object?>(null);
  static List<Task> tasks = [];

  static void notifyChanged() {
    changed.value = Object();
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
