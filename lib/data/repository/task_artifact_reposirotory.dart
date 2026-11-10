import 'package:isar_community/isar.dart';

import '../../screens/task/task_data.dart';
import '../data_main/isar_models.dart';
import '../data_main/isar_service.dart';

class TaskArtifactRepository {
  static Future<TaskArtifact?> loadForTask({required int taskId}) async {
    final isar = IsarService.instance;
    final entity = await isar.taskArtifactEntitys
        .filter()
        .taskIdEqualTo(taskId)
        .findFirst();

    if (entity == null) return null;

    return TaskArtifact(
      name: entity.name,
      description: entity.description,
      location: entity.location,
    );
  }

  static Future<void> saveForTask({
    required int taskId,
    required TaskArtifact artifact,
  }) async {
    final isar = IsarService.instance;

    await isar.writeTxn(() async {
      var entity = await isar.taskArtifactEntitys
          .filter()
          .taskIdEqualTo(taskId)
          .findFirst();

      if (entity == null) {
        entity = TaskArtifactEntity()..taskId = taskId;
      }

      entity
        ..name = artifact.name
        ..description = artifact.description
        ..location = artifact.location;

      await isar.taskArtifactEntitys.put(entity);
    });
  }

  static Future<void> deleteForTask({required int taskId}) async {
    final isar = IsarService.instance;

    await isar.writeTxn(() async {
      final entities = await isar.taskArtifactEntitys
          .filter()
          .taskIdEqualTo(taskId)
          .findAll();

      await isar.taskArtifactEntitys.deleteAll(
        entities.map((entity) => entity.id).toList(),
      );
    });
  }
}
