import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/task/task_data.dart';
import 'package:my_app/screens/task/task_deadline_notification_form.dart';
import 'package:my_app/services/simple_notification_service.dart';

void main() {
  group('NotificationService.deadlineReminderTimes', () {
    test(
      'returns daily 9am reminders from three days before through deadline',
      () {
        expect(
          NotificationService.deadlineReminderTimes(
            '2026-11-20',
            now: DateTime(2026, 11, 16, 8),
          ),
          [
            DateTime(2026, 11, 17, 9),
            DateTime(2026, 11, 18, 9),
            DateTime(2026, 11, 19, 9),
            DateTime(2026, 11, 20, 9),
          ],
        );
      },
    );

    test('omits reminder times that have already passed', () {
      expect(
        NotificationService.deadlineReminderTimes(
          '2026-11-20',
          now: DateTime(2026, 11, 17, 10),
        ),
        [
          DateTime(2026, 11, 18, 9),
          DateTime(2026, 11, 19, 9),
          DateTime(2026, 11, 20, 9),
        ],
      );
    });

    test('returns no reminders for an invalid deadline', () {
      expect(
        NotificationService.deadlineReminderTimes(
          'not-a-date',
          now: DateTime(2026, 11, 16),
        ),
        isEmpty,
      );
    });

    test('notifies only on selected days when repetition is disabled', () {
      expect(
        NotificationService.deadlineReminderTimes(
          '2026-11-20',
          now: DateTime(2026, 11, 16, 8),
          daysBeforeDeadline: [1, 3],
          frequency: TaskReminderFrequency.none,
        ),
        [DateTime(2026, 11, 17, 9), DateTime(2026, 11, 19, 9)],
      );
    });

    test('repeats weekly from the selected start date until the deadline', () {
      expect(
        NotificationService.deadlineReminderTimes(
          '2026-11-20',
          now: DateTime(2026, 11, 1),
          daysBeforeDeadline: [14],
          frequency: TaskReminderFrequency.weekly,
        ),
        [
          DateTime(2026, 11, 6, 9),
          DateTime(2026, 11, 13, 9),
          DateTime(2026, 11, 20, 9),
        ],
      );
    });

    test('monthly repetition preserves the original day at month ends', () {
      expect(
        NotificationService.deadlineReminderTimes(
          '2027-03-31',
          now: DateTime(2027, 1, 1),
          daysBeforeDeadline: [59],
          frequency: TaskReminderFrequency.monthly,
        ),
        [
          DateTime(2027, 1, 31, 9),
          DateTime(2027, 2, 28, 9),
          DateTime(2027, 3, 31, 9),
        ],
      );
    });

    test('uses the selected notification time', () {
      expect(
        NotificationService.deadlineReminderTimes(
          '2026-11-20',
          now: DateTime(2026, 11, 18),
          daysBeforeDeadline: [1],
          frequency: TaskReminderFrequency.none,
          reminderHour: 18,
          reminderMinute: 45,
        ),
        [DateTime(2026, 11, 19, 18, 45)],
      );
    });
  });

  testWidgets('reminder form updates selected days and repetition', (
    tester,
  ) async {
    var settings = const TaskReminderSettingsValue(
      notifyOneDayBefore: false,
      notifyThreeDaysBefore: true,
      customEnabled: false,
      customDaysBefore: 7,
      frequency: TaskReminderFrequency.daily,
      hour: 9,
      minute: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskDeadlineNotificationForm(
            initialValue: settings,
            onChanged: (value) => settings = value,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(CheckboxListTile, '締切1日前'));
    await tester.pumpAndSettle();
    expect(settings.daysBeforeDeadline, [1, 3]);

    await tester.tap(
      find.byType(DropdownButtonFormField<TaskReminderFrequency>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('毎週').last);
    await tester.pumpAndSettle();
    expect(settings.frequency, TaskReminderFrequency.weekly);

    await tester.tap(find.text('通知時刻'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
