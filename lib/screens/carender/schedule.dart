import 'package:flutter/material.dart';

class Schedule {
  final int? id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;

  Schedule({
    this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.color,
  }) : assert(!endDate.isBefore(startDate));
}
