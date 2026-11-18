import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../screens/task/task_data.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static const _maxReminderDays = maxTaskReminderDaysBeforeDeadline;
  static const _defaultReminderHour = 9;
  static const _legacyReminderIdBase = 10000;
  static const _legacyReminderIdSlots = 4;
  static const _reminderIdBase = 1000000000;
  static const _reminderIdSlots = _maxReminderDays + 1;
  static bool _timeZoneInitialized = false;

  static Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await notifications.initialize(settings: settings);

    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> syncTaskDeadlineNotifications(List<Task> tasks) async {
    if (!Platform.isAndroid) {
      return;
    }

    for (final task in tasks) {
      await updateTaskDeadlineNotification(task);
    }
  }

  static Future<void> updateTaskDeadlineNotification(Task task) async {
    if (!Platform.isAndroid) {
      return;
    }

    final taskId = task.id;
    if (taskId == null) {
      throw StateError('通知を設定する課題のIDがありません。');
    }

    final times = task.isDone
        ? const <DateTime>[]
        : deadlineReminderTimes(
            task.deadline,
            now: DateTime.now(),
            daysBeforeDeadline: task.deadlineReminderDaysBefore,
            frequency: task.deadlineReminderFrequency,
            reminderHour: task.deadlineReminderHour,
            reminderMinute: task.deadlineReminderMinute,
          );
    if (times.isNotEmpty) {
      await _initializeTimeZone();
    }

    await cancelTaskDeadlineNotifications(task);

    if (times.isEmpty) {
      return;
    }

    final parsedDeadline = DateTime.parse(task.deadline.trim());
    final dueDay = DateTime(
      parsedDeadline.year,
      parsedDeadline.month,
      parsedDeadline.day,
    );

    for (final scheduledAt in times) {
      final reminderDay = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
      );
      final daysBeforeDeadline = dueDay.difference(reminderDay).inDays;
      final daysLeft = daysBeforeDeadline;
      final body = daysLeft == 0
          ? '${task.subject}「${task.title}」は今日が締切です。'
          : '${task.subject}「${task.title}」の締切まであと$daysLeft日です。';

      await notifications.zonedSchedule(
        id: _notificationId(taskId, daysBeforeDeadline),
        title: '課題の締切が近づいています',
        body: body,
        scheduledDate: timezone.TZDateTime(
          timezone.local,
          scheduledAt.year,
          scheduledAt.month,
          scheduledAt.day,
          scheduledAt.hour,
          scheduledAt.minute,
        ),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_deadline_channel',
            '課題の締切通知',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancelTaskDeadlineNotifications(Task task) async {
    if (!Platform.isAndroid) {
      return;
    }

    final taskId = task.id;
    if (taskId == null) {
      throw StateError('通知を解除する課題のIDがありません。');
    }

    final firstNewId = _notificationId(taskId, 0);
    final lastNewId = _notificationId(taskId, _maxReminderDays);
    final legacyIds = List<int>.generate(
      _legacyReminderIdSlots,
      (daysBeforeDeadline) => _legacyNotificationId(taskId, daysBeforeDeadline),
    ).toSet();
    final pendingNotifications = await notifications
        .pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if ((notification.id >= firstNewId && notification.id <= lastNewId) ||
          legacyIds.contains(notification.id)) {
        await notifications.cancel(id: notification.id);
      }
    }
  }

  static List<DateTime> deadlineReminderTimes(
    String deadline, {
    required DateTime now,
    List<int> daysBeforeDeadline = const [3],
    TaskReminderFrequency frequency = TaskReminderFrequency.daily,
    int reminderHour = _defaultReminderHour,
    int reminderMinute = 0,
  }) {
    final parsedDeadline = DateTime.tryParse(deadline.trim());
    if (parsedDeadline == null) {
      return const [];
    }
    if (reminderHour < 0 || reminderHour > 23) {
      throw RangeError.range(reminderHour, 0, 23, 'reminderHour');
    }
    if (reminderMinute < 0 || reminderMinute > 59) {
      throw RangeError.range(reminderMinute, 0, 59, 'reminderMinute');
    }

    final dueDay = DateTime(
      parsedDeadline.year,
      parsedDeadline.month,
      parsedDeadline.day,
    );
    final reminders = <DateTime>{};

    for (final days in daysBeforeDeadline.toSet()) {
      if (days < 1 || days > _maxReminderDays) {
        throw RangeError.range(days, 1, _maxReminderDays, 'daysBeforeDeadline');
      }
      var reminderDay = dueDay.subtract(Duration(days: days));
      final monthlyAnchorDay = reminderDay.day;
      while (!reminderDay.isAfter(dueDay)) {
        final reminderTime = DateTime(
          reminderDay.year,
          reminderDay.month,
          reminderDay.day,
          reminderHour,
          reminderMinute,
        );
        if (reminderTime.isAfter(now)) reminders.add(reminderTime);

        reminderDay = switch (frequency) {
          TaskReminderFrequency.none => dueDay.add(const Duration(days: 1)),
          TaskReminderFrequency.daily => reminderDay.add(
            const Duration(days: 1),
          ),
          TaskReminderFrequency.weekly => reminderDay.add(
            const Duration(days: 7),
          ),
          TaskReminderFrequency.monthly => _addOneMonth(
            reminderDay,
            monthlyAnchorDay,
          ),
        };
      }
    }

    return reminders.toList()..sort();
  }

  static Future<void> _initializeTimeZone() async {
    if (_timeZoneInitialized) {
      return;
    }

    timezone_data.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    final location = switch (localTimeZone.identifier) {
      'GMT' || 'UTC' => timezone.UTC,
      final identifier => timezone.getLocation(identifier),
    };
    timezone.setLocalLocation(location);
    _timeZoneInitialized = true;
  }

  static int _notificationId(int taskId, int daysBeforeDeadline) {
    if (taskId < 0 ||
        daysBeforeDeadline < 0 ||
        daysBeforeDeadline > _maxReminderDays) {
      throw RangeError('課題通知IDの範囲が正しくありません。');
    }

    final id = _reminderIdBase + taskId * _reminderIdSlots + daysBeforeDeadline;
    if (id > 0x7fffffff) {
      throw RangeError('課題通知IDが上限を超えています。');
    }
    return id;
  }

  static int _legacyNotificationId(int taskId, int daysBeforeDeadline) {
    final id =
        _legacyReminderIdBase +
        taskId * _legacyReminderIdSlots +
        daysBeforeDeadline;
    if (taskId < 0 || id > 0x7fffffff) {
      throw RangeError('課題通知IDの範囲が正しくありません。');
    }
    return id;
  }

  static DateTime _addOneMonth(DateTime date, int dayOfMonth) {
    final nextMonth = DateTime(date.year, date.month + 1);
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    return DateTime(
      nextMonth.year,
      nextMonth.month,
      dayOfMonth > lastDay ? lastDay : dayOfMonth,
    );
  }

  static Future<void> showTestNotification() async {
    if (!Platform.isAndroid) {
      return;
    }

    await notifications.show(
      id: 0,
      title: 'テスト通知',
      body: '通知が表示されました',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'テスト通知',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
