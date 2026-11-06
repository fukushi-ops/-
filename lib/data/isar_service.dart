import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_models.dart';

class IsarService {
  static Isar? _instance;

  static Future<Isar> open() async {
    final current = _instance;
    if (current != null && current.isOpen) {
      return current;
    }

    final directory = await getApplicationDocumentsDirectory();
    _instance = await Isar.open([
      AcademicTermSchema,
      CourseEntitySchema,
      LessonEntitySchema,
      TaskEntitySchema,
      AttendanceEntitySchema,
      AppSettingsSchema,
      CalendarEventEntitySchema,
    ], directory: directory.path);
    return _instance!;
  }

  static Isar get instance {
    final isar = _instance;
    if (isar == null || !isar.isOpen) {
      throw StateError('Isar is not open. Call  IsarService.open() first.');
    }
    return isar;
  }
}
