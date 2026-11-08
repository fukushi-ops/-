import 'package:isar_community/isar.dart';

import '../../screens/class/lesson_data.dart';
import '../data_main/isar_models.dart';
import '../data_main/isar_service.dart';

class AttendanceRepository {
  static Future<List<AttendanceEntity>> load() async {
    final isar = IsarService.instance;
    return isar.attendanceEntitys.where().findAll();
  }

  static Future<void> setStatus({
    required DateTime date,
    required Lesson lesson,
    required String? status,
  }) async {
    final courseId = lesson.courseId;
    final lessonId = lesson.lessonId;

    if (courseId == null || lessonId == null) {
      throw StateError('授業のIDがないため出席状況を保存できません。');
    }
    final datekey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final isar = IsarService.instance;

    await isar.writeTxn(() async {
      final records = await isar.attendanceEntitys
          .filter()
          .lessonIdEqualTo(lessonId)
          .findAll();

      AttendanceEntity? existing;
      for (final record in records) {
        if (record.date == datekey) {
          existing = record;
          break;
        }
      }
      if (status == null) {
        if (existing != null) {
          await isar.attendanceEntitys.delete(existing.id);
        }
        return;
      }
      final record = existing ?? AttendanceEntity();
      record
        ..courseId = courseId
        ..lessonId = lessonId
        ..date = datekey
        ..status = status;

      await isar.attendanceEntitys.put(record);
    });
  }
}
