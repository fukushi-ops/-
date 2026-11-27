import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/class/timetable_ocr_service.dart';

void main() {
  test('period labels and time column do not become lessons', () {
    final lines = <({String text, Rect bounds})>[];
    const weekdayCenters = [111.0, 164.0, 217.0, 270.0, 323.0];
    const rowCenters = [150.0, 200.0, 250.0, 300.0, 400.0, 450.0];
    const weekdays = ['月', '火', '水', '木', '金'];

    for (var index = 0; index < weekdays.length; index++) {
      lines.add((
        text: weekdays[index],
        bounds: Rect.fromCenter(
          center: Offset(weekdayCenters[index], 78),
          width: 18,
          height: 16,
        ),
      ));
    }

    for (var index = 0; index < rowCenters.length; index++) {
      final centerY = rowCenters[index];
      lines
        ..add((
          text: '${index + 1}',
          bounds: Rect.fromCenter(
            center: Offset(24, centerY),
            width: 12,
            height: 16,
          ),
        ))
        ..add((
          text: '8:55',
          bounds: Rect.fromCenter(
            center: Offset(60, centerY),
            width: 30,
            height: 12,
          ),
        ));
    }

    lines
      ..add((
        text: '国語',
        bounds: Rect.fromCenter(
          center: const Offset(111, 150),
          width: 24,
          height: 16,
        ),
      ))
      ..add((
        text: '体育',
        bounds: Rect.fromCenter(
          center: const Offset(164, 150),
          width: 24,
          height: 16,
        ),
      ))
      ..add((
        text: '算数',
        bounds: Rect.fromCenter(
          center: const Offset(323, 400),
          width: 24,
          height: 16,
        ),
      ))
      ..add((
        text: '給食・そうじ・昼休み',
        bounds: Rect.fromCenter(
          center: const Offset(217, 350),
          width: 100,
          height: 16,
        ),
      ))
      ..add((
        text: '持ち物を確認しましょう',
        bounds: Rect.fromCenter(
          center: const Offset(217, 500),
          width: 100,
          height: 16,
        ),
      ));

    final lessons = TimetableOcrService.parseLinesForTesting(lines);

    expect(
      lessons
          .map(
            (item) =>
                (item.weekday, item.lesson.name, item.lesson.periodNumber),
          )
          .toList(),
      [('月', '国語', 1), ('火', '体育', 1), ('金', '算数', 5)],
    );
  });
}
