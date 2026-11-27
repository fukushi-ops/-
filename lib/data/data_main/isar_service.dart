import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_models.dart';

class IsarService {
  static Isar? _instance;

  static Future<Isar> open({String? directory}) async {
    final current = _instance;
    if (current != null && current.isOpen) {
      return current;
    }

    final directoryPath =
        directory ?? (await getApplicationDocumentsDirectory()).path;
    _instance = await Isar.open([
      AcademicTermSchema,
      CourseEntitySchema,
      SubjectEntitySchema,
      LessonEntitySchema,
      TaskEntitySchema,
      TaskArtifactEntitySchema,
      AttendanceEntitySchema,
      AppSettingsSchema,
      CalendarEventEntitySchema,
    ], directory: directoryPath);
    return _instance!;
  }

  static Future<void> close() async {
    final isar = _instance;
    if (isar != null && isar.isOpen) {
      await isar.close();
    }
    _instance = null;
  }

  static Isar get instance {
    final isar = _instance;
    if (isar == null || !isar.isOpen) {
      throw StateError('Isar is not open. Call  IsarService.open() first.');
    }
    return isar;
  }
}
