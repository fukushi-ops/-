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
class SubjectEntity {
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

  late String room;

  late int periodNumber;
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
  int priority = 2;
  int progress = 0;
  String workMemo = '';
  String checklistJson = '[]';
  String deadlineReminderDaysJson = '[3]';
  String deadlineReminderFrequency = 'daily';
  int? deadlineReminderHour;
  int? deadlineReminderMinute;

  int? reflectionScore;
  String? reflectionDifficulty;
  String? reflectionLearned;
  String? reflectionGoodPoint;
  String? reflectionImprovement;
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
  bool homeRegistrationFlowHidden = false;
}

@collection
class CalendarEventEntity {
  Id id = Isar.autoIncrement;

  late String title;
  late DateTime startDate;
  late DateTime endDate;

  late int colorValue;
}

@collection
class TaskArtifactEntity {
  Id id = Isar.autoIncrement;

  @Index()
  late int taskId;

  late String name;
  late String description;
  late String location;
}
