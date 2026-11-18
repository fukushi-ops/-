import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/class/lesson_data.dart';
import 'package:my_app/screens/task/task_data.dart';
import 'package:my_app/services/home_widget_service.dart';

void main() {
  test('widget assignment data omits submitted and invalid-date tasks', () {
    final encoded = HomeWidgetService.encodeTasks([
      Task(title: '後の課題', subject: '', deadline: '2030-05-03'),
      Task(title: '提出済み', subject: '', deadline: '2030-05-01', isDone: true),
      Task(title: '先の課題', subject: '', deadline: '2030-05-01'),
      Task(title: '日付なし', subject: '', deadline: '締切未設定'),
    ]);

    expect(jsonDecode(encoded), [
      {'title': '先の課題', 'deadline': '2030-05-01'},
      {'title': '後の課題', 'deadline': '2030-05-03'},
    ]);
  });

  test('widget timetable data sorts each weekday by start time', () {
    final encoded = HomeWidgetService.encodeLessons({
      '月': [
        Lesson(
          name: '6限',
          teacher: '',
          room: '',
          time: '14:00',
          startTime: 1400,
        ),
        Lesson(
          name: '5限',
          teacher: '',
          room: '',
          time: '13:00',
          startTime: 1300,
        ),
        Lesson(
          name: '4限',
          teacher: '',
          room: '',
          time: '12:00',
          startTime: 1200,
        ),
        Lesson(
          name: '3限',
          teacher: '',
          room: '',
          time: '11:00',
          startTime: 1100,
        ),
        Lesson(
          name: '2限',
          teacher: '',
          room: '',
          time: '10:00',
          startTime: 1000,
        ),
        Lesson(name: '1限', teacher: '', room: '', time: '9:00', startTime: 900),
      ],
    });

    expect(jsonDecode(encoded), {
      '月': [
        {'name': '1限', 'time': '9:00'},
        {'name': '2限', 'time': '10:00'},
        {'name': '3限', 'time': '11:00'},
        {'name': '4限', 'time': '12:00'},
        {'name': '5限', 'time': '13:00'},
        {'name': '6限', 'time': '14:00'},
      ],
    });
  });
}
