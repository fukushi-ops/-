import 'package:flutter/material.dart';
import 'schedule.dart';
import 'add_schedule_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<Schedule> schedules = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("1月カレンダー"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddScheduleScreen()),
              );

              if (result != null) {
                setState(() => schedules.add(result));
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Row(
            children: const [
              _DayHeader("月"),
              _DayHeader("火"),
              _DayHeader("水"),
              _DayHeader("木"),
              _DayHeader("金"),
              _DayHeader("土"),
              _DayHeader("日"),
            ],
          ),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: 31,
              itemBuilder: (context, index) {
                final day = index + 1;

                final todays = schedules.where(
                  (s) => day >= s.startDay && day <= s.endDay,
                );

                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$day"),
                      ...todays.map(
                        (s) => Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 18,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              s.title,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.grey.shade200,
        child: Center(child: Text(text)),
      ),
    );
  }
}
