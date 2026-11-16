import 'package:isar_community/isar.dart';

import '../data_main/isar_models.dart';
import '../data_main/isar_service.dart';

class SubjectRepository {
  static Future<List<String>> load({required int termId}) async {
    final entities = await IsarService.instance.subjectEntitys
        .filter()
        .termIdEqualTo(termId)
        .findAll();
    return entities.map((subject) => subject.name).toSet().toList()..sort();
  }

  static Future<bool> add({required int termId, required String name}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', '科目名を入力してください。');
    }

    final subjects = await load(termId: termId);
    if (subjects.contains(normalizedName)) return false;

    await ensureRegistered(termId: termId, names: [normalizedName]);
    return true;
  }

  static Future<void> importExisting({required int termId}) async {
    final isar = IsarService.instance;
    final courses = await isar.courseEntitys
        .filter()
        .termIdEqualTo(termId)
        .findAll();
    final tasks = await isar.taskEntitys
        .filter()
        .termIdEqualTo(termId)
        .findAll();

    await ensureRegistered(
      termId: termId,
      names: [
        ...courses.map((course) => course.name),
        ...tasks.map((task) => task.subject),
      ],
    );
  }

  static Future<void> ensureRegistered({
    required int termId,
    required Iterable<String> names,
  }) async {
    final normalizedNames = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    if (normalizedNames.isEmpty) return;

    final isar = IsarService.instance;
    final existing = await isar.subjectEntitys
        .filter()
        .termIdEqualTo(termId)
        .findAll();
    final existingNames = existing.map((subject) => subject.name).toSet();
    final missingNames = normalizedNames.difference(existingNames);
    if (missingNames.isEmpty) return;

    await isar.writeTxn(() async {
      await isar.subjectEntitys.putAll([
        for (final name in missingNames)
          SubjectEntity()
            ..termId = termId
            ..name = name,
      ]);
    });
  }
}
