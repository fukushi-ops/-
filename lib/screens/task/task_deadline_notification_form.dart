import 'package:flutter/material.dart';

import 'task_data.dart';

class TaskReminderSettingsValue {
  const TaskReminderSettingsValue({
    required this.notifyOneDayBefore,
    required this.notifyThreeDaysBefore,
    required this.customEnabled,
    required this.customDaysBefore,
    required this.frequency,
    required this.hour,
    required this.minute,
  });

  final bool notifyOneDayBefore;
  final bool notifyThreeDaysBefore;
  final bool customEnabled;
  final int? customDaysBefore;
  final TaskReminderFrequency frequency;
  final int hour;
  final int minute;

  bool get isValid =>
      !customEnabled ||
      (customDaysBefore != null &&
          customDaysBefore! >= 1 &&
          customDaysBefore! <= maxTaskReminderDaysBeforeDeadline);

  List<int> get daysBeforeDeadline {
    final days = <int>[
      if (notifyOneDayBefore) 1,
      if (notifyThreeDaysBefore) 3,
      if (customEnabled && isValid) customDaysBefore!,
    ];
    return days.toSet().toList()..sort();
  }

  factory TaskReminderSettingsValue.fromTask(Task task) {
    final customDays = task.deadlineReminderDaysBefore
        .where((days) => days != 1 && days != 3)
        .toList();
    final firstCustomDays = customDays.isEmpty ? null : customDays.first;
    return TaskReminderSettingsValue(
      notifyOneDayBefore: task.deadlineReminderDaysBefore.contains(1),
      notifyThreeDaysBefore: task.deadlineReminderDaysBefore.contains(3),
      customEnabled: firstCustomDays != null,
      customDaysBefore: firstCustomDays ?? 7,
      frequency: task.deadlineReminderFrequency,
      hour: task.deadlineReminderHour,
      minute: task.deadlineReminderMinute,
    );
  }
}

class TaskDeadlineNotificationForm extends StatefulWidget {
  const TaskDeadlineNotificationForm({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final TaskReminderSettingsValue initialValue;
  final ValueChanged<TaskReminderSettingsValue> onChanged;

  @override
  State<TaskDeadlineNotificationForm> createState() =>
      _TaskDeadlineNotificationFormState();
}

class _TaskDeadlineNotificationFormState
    extends State<TaskDeadlineNotificationForm> {
  late bool _notifyOneDayBefore;
  late bool _notifyThreeDaysBefore;
  late bool _customEnabled;
  late TaskReminderFrequency _frequency;
  late int _hour;
  late int _minute;
  late final TextEditingController _customDaysController;
  int? _customDaysBefore;

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialValue;
    _notifyOneDayBefore = initialValue.notifyOneDayBefore;
    _notifyThreeDaysBefore = initialValue.notifyThreeDaysBefore;
    _customEnabled = initialValue.customEnabled;
    _frequency = initialValue.frequency;
    _hour = initialValue.hour;
    _minute = initialValue.minute;
    _customDaysBefore = initialValue.customDaysBefore;
    _customDaysController = TextEditingController(
      text: initialValue.customDaysBefore?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _customDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '締切通知',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('締切1日前'),
              value: _notifyOneDayBefore,
              onChanged: (value) {
                setState(() => _notifyOneDayBefore = value ?? false);
                _notifyChanged();
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('締切3日前'),
              value: _notifyThreeDaysBefore,
              onChanged: (value) {
                setState(() => _notifyThreeDaysBefore = value ?? false);
                _notifyChanged();
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('カスタム日数'),
              value: _customEnabled,
              onChanged: (value) {
                setState(() {
                  _customEnabled = value ?? false;
                  if (_customEnabled && _customDaysBefore == null) {
                    _customDaysBefore = 7;
                    _customDaysController.text = '7';
                  }
                });
                _notifyChanged();
              },
            ),
            if (_customEnabled)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _customDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '締切の何日前',
                    suffixText: '日前',
                    helperText: '1〜365日の範囲で入力してください',
                    errorText:
                        _customDaysBefore == null ||
                            _customDaysBefore! < 1 ||
                            _customDaysBefore! >
                                maxTaskReminderDaysBeforeDeadline
                        ? '1〜365の数字を入力してください'
                        : null,
                  ),
                  onChanged: (value) {
                    _customDaysBefore = int.tryParse(value);
                    _notifyChanged();
                  },
                ),
              ),
            DropdownButtonFormField<TaskReminderFrequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(
                labelText: '繰り返し',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskReminderFrequency.none,
                  child: Text('なし'),
                ),
                DropdownMenuItem(
                  value: TaskReminderFrequency.daily,
                  child: Text('毎日'),
                ),
                DropdownMenuItem(
                  value: TaskReminderFrequency.weekly,
                  child: Text('毎週'),
                ),
                DropdownMenuItem(
                  value: TaskReminderFrequency.monthly,
                  child: Text('毎月'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _frequency = value);
                _notifyChanged();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('通知時刻'),
              trailing: Text(
                TimeOfDay(hour: _hour, minute: _minute).format(context),
              ),
              onTap: _selectTime,
            ),
            const SizedBox(height: 8),
            Text(
              '選んだ日を起点に、締切日まで'
              '${TimeOfDay(hour: _hour, minute: _minute).format(context)}に通知します。'
              '「なし」は選んだ日だけ通知し、通知日をすべて外すと通知されません。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _notifyChanged() {
    widget.onChanged(
      TaskReminderSettingsValue(
        notifyOneDayBefore: _notifyOneDayBefore,
        notifyThreeDaysBefore: _notifyThreeDaysBefore,
        customEnabled: _customEnabled,
        customDaysBefore: _customDaysBefore,
        frequency: _frequency,
        hour: _hour,
        minute: _minute,
      ),
    );
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _hour = selected.hour;
      _minute = selected.minute;
    });
    _notifyChanged();
  }
}
