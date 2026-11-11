import 'package:isar_community/isar.dart';

import '../../screens/task/task_data.dart';
import '../data_main/isar_models.dart';
import '../data_main/isar_service.dart';

class TaskRepository {
  static Future<List<Task>> load({required int termId}) async {
    final isar = IsarService.instance;
    final entities = await isar.taskEntitys
        .filter()
        .termIdEqualTo(termId)
        .findAll();

    return entities
        .map(
          (entity) => Task(
            id: entity.id,
            title: entity.title,
            subject: entity.subject,
            deadline: entity.deadline,
            isDone: entity.isDone,
            reflectionScore: entity.reflectionScore,
            reflectionDifficulty: entity.reflectionDifficulty,
            reflectionLearned: entity.reflectionLearned,
            reflectionGoodPoint: entity.reflectionGoodPoint,
            reflectionImprovement: entity.reflectionImprovement,
          ),
        )
        .toList();
  }

  static Future<Task> add({required int termId, required Task task}) async {
    final isar = IsarService.instance;
    final entity = TaskEntity()
      ..termId = termId
      ..title = task.title
      ..subject = task.subject
      ..deadline = task.deadline
      ..isDone = task.isDone
      ..reflectionScore = task.reflectionScore
      ..reflectionDifficulty = task.reflectionDifficulty
      ..reflectionLearned = task.reflectionLearned
      ..reflectionGoodPoint = task.reflectionGoodPoint
      ..reflectionImprovement = task.reflectionImprovement;
    await isar.writeTxn(() async {
      await isar.taskEntitys.put(entity);
    });
    return Task(
      id: entity.id,
      title: entity.title,
      subject: entity.subject,
      deadline: entity.deadline,
      isDone: entity.isDone,
      reflectionScore: entity.reflectionScore,
      reflectionDifficulty: entity.reflectionDifficulty,
      reflectionLearned: entity.reflectionLearned,
      reflectionGoodPoint: entity.reflectionGoodPoint,
      reflectionImprovement: entity.reflectionImprovement,
    );
  }

  static Future<void> update(Task task) async {
    final id = task.id;
    if (id == null) {
      throw StateError('更新対象の課題IDがありません。');
    }
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final entity = await isar.taskEntitys.get(id);
      if (entity == null) {
        throw StateError('更新対象の課題が見つかりません。');
      }
      entity
        ..title = task.title
        ..subject = task.subject
        ..deadline = task.deadline
        ..isDone = task.isDone
        ..reflectionScore = task.reflectionScore
        ..reflectionDifficulty = task.reflectionDifficulty
        ..reflectionLearned = task.reflectionLearned
        ..reflectionGoodPoint = task.reflectionGoodPoint
        ..reflectionImprovement = task.reflectionImprovement;
      await isar.taskEntitys.put(entity);
    });
  }

  static Future<void> delete(Task task) async {
    final id = task.id;
    if (id == null) {
      throw StateError("削除対象の課題のIDがありません。");
    }
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final deleted = await isar.taskEntitys.delete(id);
      if (!deleted) {
        throw StateError("削除対象の課題が見つかりません。");
      }

      final artifacts = await isar.taskArtifactEntitys
          .filter()
          .taskIdEqualTo(id)
          .findAll();
      if (artifacts.isNotEmpty) {
        await isar.taskArtifactEntitys.deleteAll(
          artifacts.map((artifact) => artifact.id).toList(),
        );
      }
    });
  }

  static Future<void> updateIsDone({
    required Task task,
    required bool isDone,
  }) async {
    final id = task.id;
    if (id == null) {
      throw StateError("更新対象の課題IDがありません。");
    }
    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final entity = await isar.taskEntitys.get(id);
      if (entity == null) {
        throw StateError("更新対象の課題が見つかりせｎ。");
      }
      entity.isDone = isDone;
      await isar.taskEntitys.put(entity);
    });
  }

  static Future<void> deleteForTask({required int taskId}) async {
    final isar = IsarService.instance;

    await isar.writeTxn(() async {
      final entities = await isar.taskArtifactEntitys
          .filter()
          .taskIdEqualTo(taskId)
          .findAll();

      if (entities.isNotEmpty) {
        await isar.taskArtifactEntitys.deleteAll(
          entities.map((entity) => entity.id).toList(),
        );
      }
    });
  }
}
