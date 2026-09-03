import 'package:flutter/material.dart';

class Schedule {
  final String title;
  final int startDay;
  final int endDay;
  final Color color;

  Schedule({
    required this.title,
    required this.startDay,
    required this.endDay,
    required this.color,
  });
}
