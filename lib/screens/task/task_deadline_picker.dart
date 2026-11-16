import 'package:flutter/material.dart';

Future<DateTime?> selectTaskDeadline(
  BuildContext context, {
  DateTime? initialDate,
}) {
  final firstDate = DateTime(2000);
  final lastDate = DateTime(2100);
  final today = DateUtils.dateOnly(DateTime.now());
  var initial = DateUtils.dateOnly(initialDate ?? today);
  if (initial.isBefore(firstDate)) initial = firstDate;
  if (initial.isAfter(lastDate)) initial = lastDate;

  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: '締切日を選択',
  );
}

String formatTaskDeadline(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
