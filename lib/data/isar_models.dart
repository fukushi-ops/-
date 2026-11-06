import 'package:isar_community/isar.dart';

part 'isar_models.g.dart';

@collection
class AcademicTerm {
  Id id = Isar.autoIncrement;

  late int schoolYear;
  late String termName;
}

@collection
class CourseEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late int termId;
  late String name;
}

@collection
class LessonEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late int courseId;
  @Index()
  late String weekday;

  late String teacher;
  late String room;
  late String time;

  late int startTime;
}

@collection
class TaskEntity {
  Id id = Isar.autoIncrement;
  @Index()
  late int termId;

  late String title;
  late String subject;
  late String deadline;
  bool isDone = false;
}

@collection
class AttendanceEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late int courseId;
  @Index()
  late int lessonId;

  late String date;
  late String status;
}

@collection
class AppSettings {
  Id id = 1;
  int? selectedTermId;
}

@collection
class CalendarEventEntity {
  Id id = Isar.autoIncrement;

  late String title;
  late DateTime startDate;
  late DateTime endDate;

  late int colorValue;
}
