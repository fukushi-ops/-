import 'package:isar_community/isar.dart';

import '../../screens/class/lesson_data.dart';
import '../data_main/isar_models.dart';
import '../data_main/isar_service.dart';

class LessonRepository {
  static int? _activeTermId;

  static int get activeTermId {
    final id = _activeTermId;
    if (id == null) {
      throw StateError('授業データが初期化されていません。');
    }
    return id;
  }

  static Future<int> ensureTerm({
    required int schoolYear,
    required String termName,
  }) async {
    final isar = IsarService.instance;

    final term = await isar.academicTerms
        .filter()
        .schoolYearEqualTo(schoolYear)
        .termNameEqualTo(termName)
        .findFirst();

    final activeTerm =
        term ??
        (AcademicTerm()
          ..schoolYear = schoolYear
          ..termName = termName);

    await isar.writeTxn(() async {
      if (term == null) {
        await isar.academicTerms.put(activeTerm);
      }

      final settings = await isar.appSettings.get(1) ?? (AppSettings()..id = 1);
      settings.selectedTermId = activeTerm.id;
      await isar.appSettings.put(settings);
    });

    _activeTermId = activeTerm.id;
    return activeTerm.id;
  }

  static Future<Map<String, List<Lesson>>> loadLessons({
    required int termId,
  }) async {
    final isar = IsarService.instance;
    final lessonsByDay = {
      '月': <Lesson>[],
      '火': <Lesson>[],
      '水': <Lesson>[],
      '木': <Lesson>[],
      '金': <Lesson>[],
      '土': <Lesson>[],
      '日': <Lesson>[],
    };

    final courses = await isar.courseEntitys
        .filter()
        .termIdEqualTo(termId)
        .findAll();

    for (final course in courses) {
      final lessons = await isar.lessonEntitys
          .filter()
          .courseIdEqualTo(course.id)
          .findAll();

      for (final lesson in lessons) {
        final dayLessons = lessonsByDay[lesson.weekday];
        if (dayLessons == null) {
          throw StateError('登録されていない曜日です: ${lesson.weekday}');
        }

        dayLessons.add(
          Lesson(
            name: course.name,
            teacher: lesson.teacher,
            room: lesson.room,
            time: lesson.time,
            startTime: lesson.startTime,
            courseId: course.id,
            lessonId: lesson.id,
          ),
        );
      }
    }

    return lessonsByDay;
  }

  static Future<Lesson> addLesson({
    required int termId,
    required String weekday,
    required Lesson lesson,
  }) async {
    final isar = IsarService.instance;
    late CourseEntity course;
    late LessonEntity lessonEntity;

    await isar.writeTxn(() async {
      course = CourseEntity()
        ..termId = termId
        ..name = lesson.name;
      await isar.courseEntitys.put(course);

      lessonEntity = LessonEntity()
        ..courseId = course.id
        ..weekday = weekday
        ..teacher = lesson.teacher
        ..room = lesson.room
        ..time = lesson.time
        ..startTime = lesson.startTime;
      await isar.lessonEntitys.put(lessonEntity);
    });

    return Lesson(
      name: lesson.name,
      teacher: lesson.teacher,
      room: lesson.room,
      time: lesson.time,
      startTime: lesson.startTime,
      courseId: course.id,
      lessonId: lessonEntity.id,
    );
  }

  static Future<void> updateLesson({
    required String weekday,
    required Lesson lesson,
  }) async {
    final courseId = lesson.courseId;
    final lessonId = lesson.lessonId;
    if (courseId == null || lessonId == null) {
      throw StateError('更新対象の授業IDがありません。');
    }

    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final course = await isar.courseEntitys.get(courseId);
      final lessonEntity = await isar.lessonEntitys.get(lessonId);

      if (course == null ||
          lessonEntity == null ||
          lessonEntity.courseId != courseId) {
        throw StateError('更新対象の授業が見つかりません。');
      }

      course.name = lesson.name;
      lessonEntity
        ..weekday = weekday
        ..teacher = lesson.teacher
        ..room = lesson.room
        ..time = lesson.time
        ..startTime = lesson.startTime;

      await isar.courseEntitys.put(course);
      await isar.lessonEntitys.put(lessonEntity);
    });
  }

  static Future<void> deleteLesson({required Lesson lesson}) async {
    final courseId = lesson.courseId;
    final lessonId = lesson.lessonId;
    if (courseId == null || lessonId == null) {
      throw StateError('削除対象の授業IDがありません。');
    }

    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final lessonEntity = await isar.lessonEntitys.get(lessonId);

      if (lessonEntity == null || lessonEntity.courseId != courseId) {
        throw StateError('削除対象の授業が見つかりません。');
      }

      await isar.lessonEntitys.delete(lessonId);
      await isar.courseEntitys.delete(courseId);
    });
  }
}
