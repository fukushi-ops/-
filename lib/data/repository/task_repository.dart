import 'dart:convert';

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
            priority: entity.priority >= 1 && entity.priority <= 3
                ? entity.priority
                : 2,
            progress: entity.progress.clamp(0, 100),
            workMemo: entity.workMemo,
            checklist: _decodeChecklist(entity.checklistJson),
            deadlineReminderDaysBefore: _decodeReminderDays(
              entity.deadlineReminderDaysJson,
            ),
            deadlineReminderFrequency: _decodeReminderFrequency(
              entity.deadlineReminderFrequency,
            ),
            deadlineReminderHour: entity.deadlineReminderHour ?? 9,
            deadlineReminderMinute: entity.deadlineReminderMinute ?? 0,
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
      ..priority = task.priority
      ..progress = task.progress
      ..workMemo = task.workMemo
      ..checklistJson = _encodeChecklist(task.checklist)
      ..deadlineReminderDaysJson = _encodeReminderDays(
        task.deadlineReminderDaysBefore,
      )
      ..deadlineReminderFrequency = task.deadlineReminderFrequency.name
      ..deadlineReminderHour = task.deadlineReminderHour
      ..deadlineReminderMinute = task.deadlineReminderMinute
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
      priority: entity.priority,
      progress: entity.progress,
      workMemo: entity.workMemo,
      checklist: _decodeChecklist(entity.checklistJson),
      deadlineReminderDaysBefore: _decodeReminderDays(
        entity.deadlineReminderDaysJson,
      ),
      deadlineReminderFrequency: _decodeReminderFrequency(
        entity.deadlineReminderFrequency,
      ),
      deadlineReminderHour: entity.deadlineReminderHour ?? 9,
      deadlineReminderMinute: entity.deadlineReminderMinute ?? 0,
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
        ..priority = task.priority
        ..progress = task.progress
        ..workMemo = task.workMemo
        ..checklistJson = _encodeChecklist(task.checklist)
        ..deadlineReminderDaysJson = _encodeReminderDays(
          task.deadlineReminderDaysBefore,
        )
        ..deadlineReminderFrequency = task.deadlineReminderFrequency.name
        ..deadlineReminderHour = task.deadlineReminderHour
        ..deadlineReminderMinute = task.deadlineReminderMinute
        ..reflectionScore = task.reflectionScore
        ..reflectionDifficulty = task.reflectionDifficulty
        ..reflectionLearned = task.reflectionLearned
        ..reflectionGoodPoint = task.reflectionGoodPoint
        ..reflectionImprovement = task.reflectionImprovement;
      await isar.taskEntitys.put(entity);
    });
  }

  static String _encodeChecklist(List<TaskChecklistItem> checklist) =>
      jsonEncode(
        checklist
            .map((item) => {'title': item.title, 'isDone': item.isDone})
            .toList(),
      );

  static List<TaskChecklistItem> _decodeChecklist(String encoded) {
    if (encoded.isEmpty) return [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('課題のチェックリスト形式が正しくありません。');
    }
    return decoded.map((item) {
      if (item is! Map || item['title'] is! String || item['isDone'] is! bool) {
        throw const FormatException('課題のチェックリスト項目が正しくありません。');
      }
      return TaskChecklistItem(
        title: item['title'] as String,
        isDone: item['isDone'] as bool,
      );
    }).toList();
  }

  static String _encodeReminderDays(List<int> days) => jsonEncode(days);

  static List<int> _decodeReminderDays(String encoded) {
    if (encoded.isEmpty) return const [3];
    final decoded = jsonDecode(encoded);
    if (decoded is! List ||
        decoded.any(
          (day) =>
              day is! int || day < 1 || day > maxTaskReminderDaysBeforeDeadline,
        )) {
      throw const FormatException('課題通知日の形式が正しくありません。');
    }
    return decoded.cast<int>().toSet().toList()..sort();
  }

  static TaskReminderFrequency _decodeReminderFrequency(String encoded) {
    if (encoded.isEmpty) return TaskReminderFrequency.daily;
    for (final frequency in TaskReminderFrequency.values) {
      if (frequency.name == encoded) return frequency;
    }
    throw const FormatException('課題通知の繰り返し設定が正しくありません。');
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
