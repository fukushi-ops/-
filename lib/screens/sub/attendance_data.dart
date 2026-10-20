import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../lesson_data.dart';

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
  static const String key = 'attendance_data';
  static Map<String, AttendanceStatus> _statuses = {};

  static AttendanceStatus? statusFor(DateTime date, Lesson lesson) {
    return _statuses[_recordKey(date, lesson)];
  }

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null) {
      _statuses = {};
      return;
    }

    final decoded = Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
    _statuses = decoded.map(
      (recordKey, value) =>
          MapEntry(recordKey, AttendanceStatus.values.byName(value as String)),
    );
  }

  static Future<void> setStatus(
    DateTime date,
    Lesson lesson,
    AttendanceStatus? status,
  ) async {
    final recordKey = _recordKey(date, lesson);
    if (status == null) {
      _statuses.remove(recordKey);
    } else {
      _statuses[recordKey] = status;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonMap = _statuses.map(
      (recordKey, value) => MapEntry(recordKey, value.name),
    );
    await prefs.setString(key, jsonEncode(jsonMap));
  }

  static String _recordKey(DateTime date, Lesson lesson) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return jsonEncode([
      dateKey,
      lesson.name,
      lesson.teacher,
      lesson.room,
      lesson.startTime,
    ]);
  }
}
