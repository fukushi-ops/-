class Lesson {
  Lesson({
    required this.name,
    required this.room,
    required this.periodNumber,
    this.courseId,
    this.lessonId,
  });

  String name;
  String room;
  int periodNumber;

  // ISAR上で編集・削除する授業を特定するID
  int? courseId;
  int? lessonId;
}

class LessonImport {
  const LessonImport({required this.weekday, required this.lesson});

  final String weekday;
  final Lesson lesson;
}

class LessonData {
  static final Map<String, List<Lesson>> lessonsByDay = {
    '月': [],
    '火': [],
    '水': [],
    '木': [],
    '金': [],
    '土': [],
    '日': [],
  };
}
