class Task {
  int? id; // ISAR上で編集・削除する課題を特定するID
  String title; // 課題名
  String subject; // 科目名
  String deadline; // 締切
  bool isDone; // 提出済みかどうか

  Task({
    this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    this.isDone = false,
  });
}

class TaskData {
  static List<Task> tasks = [];
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
