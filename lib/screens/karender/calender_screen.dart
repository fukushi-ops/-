import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'add_schedule_screen.dart';
import 'schedule.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<Schedule> schedules = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateUtils.dateOnly(DateTime.now());

  List<Schedule> _eventsForDay(DateTime day) {
    final date = DateUtils.dateOnly(day);

    return schedules.where((schedule) {
      final start = DateUtils.dateOnly(schedule.startDate);
      final end = DateUtils.dateOnly(schedule.endDate);

      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  Future<void> _addSchedule() async {
    final result = await Navigator.push<Schedule>(
      context,
      MaterialPageRoute(builder: (_) => const AddScheduleScreen()),
    );

    if (result != null) {
      setState(() {
        schedules.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay == null
        ? <Schedule>[]
        : _eventsForDay(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_focusedDay.year}年${_focusedDay.month}月カレンダー'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addSchedule),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<Schedule>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _focusedDay,
            locale: 'ja_JP',
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _eventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          const Divider(),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(child: Text('この日の予定はありません'))
                : ListView.builder(
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) {
                      final schedule = selectedEvents[index];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: schedule.color,
                          radius: 8,
                        ),
                        title: Text(schedule.title),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
