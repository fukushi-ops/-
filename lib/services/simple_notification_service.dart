import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../screens/task/task_data.dart';

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static const _reminderDays = 3;
  static const _reminderHour = 9;
  static const _reminderIdBase = 10000;
  static const _reminderIdSlots = _reminderDays + 1;
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
        : deadlineReminderTimes(task.deadline, now: DateTime.now());
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
          _reminderHour,
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

    for (
      var daysBeforeDeadline = 0;
      daysBeforeDeadline <= _reminderDays;
      daysBeforeDeadline++
    ) {
      await notifications.cancel(
        id: _notificationId(taskId, daysBeforeDeadline),
      );
    }
  }

  static List<DateTime> deadlineReminderTimes(
    String deadline, {
    required DateTime now,
  }) {
    final parsedDeadline = DateTime.tryParse(deadline.trim());
    if (parsedDeadline == null) {
      return const [];
    }

    final dueDay = DateTime(
      parsedDeadline.year,
      parsedDeadline.month,
      parsedDeadline.day,
    );
    final reminders = <DateTime>[];

    for (
      var daysBeforeDeadline = _reminderDays;
      daysBeforeDeadline >= 0;
      daysBeforeDeadline--
    ) {
      final reminderDay = dueDay.subtract(Duration(days: daysBeforeDeadline));
      final reminderTime = DateTime(
        reminderDay.year,
        reminderDay.month,
        reminderDay.day,
        _reminderHour,
      );
      if (reminderTime.isAfter(now)) {
        reminders.add(reminderTime);
      }
    }

    return reminders;
  }

  static Future<void> _initializeTimeZone() async {
    if (_timeZoneInitialized) {
      return;
    }

    timezone_data.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimeZone.identifier));
    _timeZoneInitialized = true;
  }

  static int _notificationId(int taskId, int daysBeforeDeadline) {
    if (taskId < 0 ||
        daysBeforeDeadline < 0 ||
        daysBeforeDeadline > _reminderDays) {
      throw RangeError('課題通知IDの範囲が正しくありません。');
    }

    final id = _reminderIdBase + taskId * _reminderIdSlots + daysBeforeDeadline;
    if (id > 0x7fffffff) {
      throw RangeError('課題通知IDが上限を超えています。');
    }
    return id;
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
