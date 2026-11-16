import 'package:isar_community/isar.dart';

import '../../screens/class/lesson_data.dart';
import '../data_main/isar_models.dart';
import '../data_main/isar_service.dart';

class LessonRepository {
  static int? _activeTermId;
  static String? _activeTermName;

  static int get activeTermId {
    final id = _activeTermId;
    if (id == null) {
      throw StateError('授業データが初期化されていません。');
    }
    return id;
  }

  static int? get maybeActiveTermId => _activeTermId;

  static String? get activeTermName => _activeTermName;

  static Future<int> ensureTerm({
    required int schoolYear,
    required String termName,
  }) async {
    final isar = IsarService.instance;

    final settings = await isar.appSettings.get(1);
    final selectedTermId = settings?.selectedTermId;
    if (selectedTermId != null) {
      final selectedTerm = await isar.academicTerms.get(selectedTermId);
      if (selectedTerm != null) {
        _activeTermId = selectedTerm.id;
        _activeTermName = selectedTerm.termName;
        return selectedTerm.id;
      }
    }

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
    _activeTermName = activeTerm.termName;
    return activeTerm.id;
  }

  static Future<List<AcademicTerm>> loadTerms() async {
    final terms = await IsarService.instance.academicTerms.where().findAll();
    terms.sort((a, b) {
      final yearOrder = b.schoolYear.compareTo(a.schoolYear);
      return yearOrder != 0 ? yearOrder : a.termName.compareTo(b.termName);
    });
    return terms;
  }

  static Future<bool> termExists({
    required int schoolYear,
    required String termName,
  }) async {
    return await IsarService.instance.academicTerms
            .filter()
            .schoolYearEqualTo(schoolYear)
            .termNameEqualTo(termName.trim())
            .findFirst() !=
        null;
  }

  static Future<bool> hasTermData({required int termId}) async {
    final isar = IsarService.instance;
    final course = await isar.courseEntitys
        .filter()
        .termIdEqualTo(termId)
        .findFirst();
    if (course != null) return true;

    final task = await isar.taskEntitys
        .filter()
        .termIdEqualTo(termId)
        .findFirst();
    if (task != null) return true;

    final subject = await isar.subjectEntitys
        .filter()
        .termIdEqualTo(termId)
        .findFirst();
    return subject != null;
  }

  static Future<AcademicTerm> createTerm({
    required int schoolYear,
    required String termName,
    required bool moveExistingData,
  }) async {
    final normalizedName = termName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(termName, 'termName', '期間名を入力してください。');
    }
    if (await termExists(schoolYear: schoolYear, termName: normalizedName)) {
      throw StateError('同じ年度に同じ期間名がすでに登録されています。');
    }

    final sourceTermId = moveExistingData ? activeTermId : null;
    final isar = IsarService.instance;
    final term = AcademicTerm()
      ..schoolYear = schoolYear
      ..termName = normalizedName;

    await isar.writeTxn(() async {
      await isar.academicTerms.put(term);

      if (sourceTermId != null) {
        final courses = await isar.courseEntitys
            .filter()
            .termIdEqualTo(sourceTermId)
            .findAll();
        for (final course in courses) {
          course.termId = term.id;
        }
        if (courses.isNotEmpty) await isar.courseEntitys.putAll(courses);

        final tasks = await isar.taskEntitys
            .filter()
            .termIdEqualTo(sourceTermId)
            .findAll();
        for (final task in tasks) {
          task.termId = term.id;
        }
        if (tasks.isNotEmpty) await isar.taskEntitys.putAll(tasks);

        final subjects = await isar.subjectEntitys
            .filter()
            .termIdEqualTo(sourceTermId)
            .findAll();
        for (final subject in subjects) {
          subject.termId = term.id;
        }
        if (subjects.isNotEmpty) await isar.subjectEntitys.putAll(subjects);
      }

      final settings = await isar.appSettings.get(1) ?? (AppSettings()..id = 1);
      settings.selectedTermId = term.id;
      await isar.appSettings.put(settings);
    });

    _activeTermId = term.id;
    _activeTermName = term.termName;
    return term;
  }

  static Future<void> selectTerm({required int termId}) async {
    final isar = IsarService.instance;
    final term = await isar.academicTerms.get(termId);
    if (term == null) {
      throw StateError('切り替え先の期間が見つかりません。');
    }

    await isar.writeTxn(() async {
      final settings = await isar.appSettings.get(1) ?? (AppSettings()..id = 1);
      settings.selectedTermId = termId;
      await isar.appSettings.put(settings);
    });

    _activeTermId = term.id;
    _activeTermName = term.termName;
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

  static Future<List<LessonImport>> addLessons({
    required int termId,
    required List<LessonImport> lessons,
  }) async {
    final isar = IsarService.instance;
    final savedLessons = <LessonImport>[];

    await isar.writeTxn(() async {
      for (final item in lessons) {
        final course = CourseEntity()
          ..termId = termId
          ..name = item.lesson.name;
        await isar.courseEntitys.put(course);

        final lessonEntity = LessonEntity()
          ..courseId = course.id
          ..weekday = item.weekday
          ..teacher = item.lesson.teacher
          ..room = item.lesson.room
          ..time = item.lesson.time
          ..startTime = item.lesson.startTime;
        await isar.lessonEntitys.put(lessonEntity);

        savedLessons.add(
          LessonImport(
            weekday: item.weekday,
            lesson: Lesson(
              name: item.lesson.name,
              teacher: item.lesson.teacher,
              room: item.lesson.room,
              time: item.lesson.time,
              startTime: item.lesson.startTime,
              courseId: course.id,
              lessonId: lessonEntity.id,
            ),
          ),
        );
      }
    });

    return savedLessons;
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
