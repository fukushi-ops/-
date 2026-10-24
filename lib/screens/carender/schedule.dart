import 'package:flutter/material.dart';

class Schedule {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;

  Schedule({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.color,
  }) : assert(!endDate.isBefore(startDate));
}
