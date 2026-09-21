class Lesson {
  String name; // 授業名
  String teacher; // 先生
  String room; // 教室
  String time; // 時間（例：9:00〜10:30）
  int startTime; // 900 のように数値化した時間

  Lesson({
    required this.name,
    required this.teacher,
    required this.room,
    required this.time,
    required this.startTime,
  });
}

class LessonData {
  static Map<String, List<Lesson>> lessonsByDay = {
    "月": [],
    "火": [],
    "水": [],
    "木": [],
    "金": [],
    "土": [],
    "日": [],
  };
}
