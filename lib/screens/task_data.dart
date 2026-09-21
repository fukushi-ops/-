import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Task {
  String title; // 課題名
  String subject; // 科目名
  String deadline; // 締切
  bool isDone; // 提出済みかどうか

  Task({
    required this.title,
    required this.subject,
    required this.deadline,
    this.isDone = false,
  });

  // ★ JSON に変換
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "subject": subject,
      "deadline": deadline,
      "isDone": isDone,
    };
  }

  // ★ JSON から復元
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json["title"],
      subject: json["subject"],
      deadline: json["deadline"],
      isDone: json["isDone"],
    );
  }
}

class TaskData {
  static List<Task> tasks = [];
}

class TaskStorage {
  static const String key = "task_data";

  // ★ 保存
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = TaskData.tasks.map((t) => t.toJson()).toList();
    prefs.setString(key, jsonEncode(jsonList));
  }

  // ★ 読み込み
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) return;

    final decoded = jsonDecode(jsonString);
    TaskData.tasks = (decoded as List)
        .map((item) => Task.fromJson(item))
        .toList();
  }
}
