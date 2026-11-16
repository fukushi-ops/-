import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'lesson_data.dart';

class TimetableOcrService {
  static const _weekdays = ['月', '火', '水', '木', '金', '土', '日'];

  static Future<List<LessonImport>> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.japanese);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return _parseLines([
        for (final block in result.blocks)
          for (final line in block.lines)
            _OcrLine(line.text.trim(), line.boundingBox),
      ]);
    } finally {
      await recognizer.close();
    }
  }

  static List<LessonImport> _parseLines(List<_OcrLine> lines) {
    final headers = <String, _OcrLine>{};
    final weekdayPattern = RegExp(r'^[（(]?\s*([月火水木金土日])(?:曜日)?\s*[)）]?$');

    for (final line in lines) {
      final match = weekdayPattern.firstMatch(line.text.replaceAll(' ', ''));
      if (match != null) {
        headers.putIfAbsent(match.group(1)!, () => line);
      }
    }

    final sortedHeaders = headers.entries.toList()
      ..sort((a, b) => a.value.centerX.compareTo(b.value.centerX));
    if (sortedHeaders.length < 2) {
      throw const FormatException('曜日の見出しを読み取れませんでした。曜日が横並びの時間割画像を選んでください。');
    }

    final headerBottom = sortedHeaders
        .map((entry) => entry.value.bounds.bottom)
        .reduce(math.max);
    final periods = <({int number, double centerY})>[];
    final periodPattern = RegExp(r'^\s*([1-9])\s*限(?:目)?\s*$');
    for (final line in lines) {
      final match = periodPattern.firstMatch(line.text);
      if (match != null) {
        periods.add((
          number: int.parse(match.group(1)!),
          centerY: line.centerY,
        ));
      }
    }
    periods.sort((a, b) => a.centerY.compareTo(b.centerY));

    final cellLines = <({String weekday, _OcrLine line})>[];
    for (final line in lines) {
      if (line.bounds.top <= headerBottom ||
          periodPattern.hasMatch(line.text) ||
          weekdayPattern.hasMatch(line.text.replaceAll(' ', ''))) {
        continue;
      }

      for (var index = 0; index < sortedHeaders.length; index++) {
        final centerX = sortedHeaders[index].value.centerX;
        final left = index == 0
            ? double.negativeInfinity
            : (sortedHeaders[index - 1].value.centerX + centerX) / 2;
        final right = index == sortedHeaders.length - 1
            ? double.infinity
            : (centerX + sortedHeaders[index + 1].value.centerX) / 2;
        if (line.centerX >= left && line.centerX < right) {
          cellLines.add((weekday: sortedHeaders[index].key, line: line));
          break;
        }
      }
    }

    if (cellLines.isEmpty) {
      throw const FormatException('時間割の授業名を読み取れませんでした。画像の文字が鮮明か確認してください。');
    }

    final rowCenters = periods.isNotEmpty
        ? periods.map((period) => period.centerY).toList()
        : _clusterRows(cellLines.map((cell) => cell.line).toList());
    final cells = <(String, int), List<String>>{};
    for (final cell in cellLines) {
      final rowIndex = _nearestRow(cell.line.centerY, rowCenters);
      cells.putIfAbsent((cell.weekday, rowIndex), () => []).add(cell.line.text);
    }

    final imports = <LessonImport>[];
    for (final entry in cells.entries) {
      final (weekday, rowIndex) = entry.key;
      final period = periods.isNotEmpty
          ? periods[rowIndex].number
          : rowIndex + 1;
      final name = entry.value.join(' / ').trim();
      if (name.isEmpty) continue;

      imports.add(
        LessonImport(
          weekday: weekday,
          lesson: Lesson(
            name: name,
            teacher: '',
            room: '',
            time: '$period限目',
            startTime: period * 100,
          ),
        ),
      );
    }

    imports.sort((a, b) {
      final dayOrder =
          _weekdays.indexOf(a.weekday) - _weekdays.indexOf(b.weekday);
      return dayOrder != 0
          ? dayOrder
          : a.lesson.startTime.compareTo(b.lesson.startTime);
    });
    return imports;
  }

  static List<double> _clusterRows(List<_OcrLine> lines) {
    final sorted = lines.toList()
      ..sort((a, b) => a.centerY.compareTo(b.centerY));
    final heights = sorted.map((line) => line.bounds.height).toList()..sort();
    final medianHeight = heights[heights.length ~/ 2];
    final threshold = math.max(14.0, medianHeight * 1.6);
    final rows = <double>[];
    var count = 0;

    for (final line in sorted) {
      if (rows.isEmpty || line.centerY - rows.last > threshold) {
        rows.add(line.centerY);
        count = 1;
      } else {
        rows[rows.length - 1] =
            (rows.last * count + line.centerY) / (count + 1);
        count++;
      }
    }
    return rows;
  }

  static int _nearestRow(double centerY, List<double> rowCenters) {
    var nearest = 0;
    var distance = double.infinity;
    for (var index = 0; index < rowCenters.length; index++) {
      final candidate = (centerY - rowCenters[index]).abs();
      if (candidate < distance) {
        nearest = index;
        distance = candidate;
      }
    }
    return nearest;
  }
}

class _OcrLine {
  const _OcrLine(this.text, this.bounds);

  final String text;
  final Rect bounds;

  double get centerX => bounds.center.dx;
  double get centerY => bounds.center.dy;
}
