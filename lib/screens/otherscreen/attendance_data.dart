import 'package:my_app/data/repository/attendance_repository.dart';

import '../class/lesson_data.dart';

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusLabel on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return '出席';
      case AttendanceStatus.absent:
        return '欠席';
      case AttendanceStatus.late:
        return '遅刻';
      case AttendanceStatus.excused:
        return '公欠';
    }
  }
}

class AttendanceStorage {
  static Map<String, AttendanceStatus> _statuses = {};

  static int get attendedCount => _statuses.values
      .where((status) => status == AttendanceStatus.present)
      .length;

  static int get countedCount => _statuses.values
      .where((status) => status != AttendanceStatus.excused)
      .length;

  static double? get attendanceRate =>
      countedCount == 0 ? null : attendedCount / countedCount;

  static AttendanceStatus? statusFor(DateTime date, Lesson lesson) {
    return _statuses[_recordKey(date, lesson)];
  }

  static Future<void> load() async {
    final records = await AttendanceRepository.load();

    _statuses = {
      for (final record in records)
        '${record.date}:${record.lessonId}': AttendanceStatus.values.byName(
          record.status,
        ),
    };
  }

  static Future<void> setStatus(
    DateTime date,
    Lesson lesson,
    AttendanceStatus? status,
  ) async {
    final key = _recordKey(date, lesson);

    if (status == null) {
      _statuses.remove(key);
    } else {
      _statuses[key] = status;
    }

    await AttendanceRepository.setStatus(
      date: date,
      lesson: lesson,
      status: status?.name,
    );
  }

  static String _recordKey(DateTime date, Lesson lesson) {
    final lessonId = lesson.lessonId;
    if (lessonId == null) {
      throw StateError('授業のIDがないため出席状況を特定できません。');
    }
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$dateKey:$lessonId';
  }
}
