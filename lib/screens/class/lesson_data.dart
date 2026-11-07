class Lesson {
  Lesson({
    required this.name,
    required this.teacher,
    required this.room,
    required this.time,
    required this.startTime,
    this.courseId,
    this.lessonId,
  });

  String name;
  String teacher;
  String room;
  String time;
  int startTime;

  // ISAR上で編集・削除する授業を特定するID
  int? courseId;
  int? lessonId;
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
