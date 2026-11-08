import 'package:isar_community/isar.dart';
import 'package:flutter/material.dart';

import '../../screens/carender/schedule.dart';
import '../data_main/isar_models.dart';
import '../data_main/isar_service.dart';

class CalendarRepository {
  static Future<List<Schedule>> load() async {
    final isar = IsarService.instance;
    final events = await isar.calendarEventEntitys.where().findAll();

    return events
        .map(
          (event) => Schedule(
            id: event.id,
            title: event.title,
            startDate: event.startDate,
            endDate: event.endDate,
            color: Color(event.colorValue),
          ),
        )
        .toList();
  }

  static Future<Schedule> add(Schedule schedule) async {
    final isar = IsarService.instance;
    final event = CalendarEventEntity()
      ..title = schedule.title
      ..startDate = schedule.startDate
      ..endDate = schedule.endDate
      ..colorValue = schedule.color.toARGB32();

    await isar.writeTxn(() async {
      await isar.calendarEventEntitys.put(event);
    });

    return Schedule(
      id: event.id,
      title: event.title,
      startDate: event.startDate,
      endDate: event.endDate,
      color: Color(event.colorValue),
    );
  }

  static Future<void> delete(Schedule schedule) async {
    final id = schedule.id;
    if (id == null) {
      throw StateError('削除対象の予定IDがありません。');
    }

    final isar = IsarService.instance;
    await isar.writeTxn(() async {
      final deleted = await isar.calendarEventEntitys.delete(id);
      if (!deleted) {
        throw StateError('削除対象の予定が見つかりません。');
      }
    });
  }
}
