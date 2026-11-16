import 'package:flutter_test/flutter_test.dart';
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
  });
}
