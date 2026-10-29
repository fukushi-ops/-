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
  // 追加された予定を画面が表示されている間、ここに保存します。
  final List<Schedule> schedules = [];

  // カレンダーで現在表示している月の日付です。
  DateTime _focusedDay = DateTime.now();

  // 選択中の日付です。まだ選択されていない場合は null になります。？はnull許容型を意味します。
  DateTime? _selectedDay = DateUtils.dateOnly(DateTime.now());

  CalendarFormat _calendarFormat = CalendarFormat.month;

  // 指定した日付に重なる予定を探して、カレンダーや一覧に渡します。
  List<Schedule> _eventsForDay(DateTime day) {
    // 時刻の違いで同じ日が別の日と判定されないよう、日付だけにそろえます。
    final date = DateUtils.dateOnly(day);

    return schedules.where((schedule) {
      final start = DateUtils.dateOnly(schedule.startDate);
      final end = DateUtils.dateOnly(schedule.endDate);

      // 開始日と終了日も含めて、その期間内にある予定を残します。
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  // 予定の入力画面を開き、入力結果が返ってきたら一覧に追加します。
  Future<void> _addSchedule() async {
    final result = await Navigator.push<Schedule>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddScheduleScreen(initialDate: _selectedDay ?? _focusedDay),
      ),
    );

    // 入力画面で予定が保存されたときだけ、画面を更新します。
    if (result != null) {
      setState(() {
        schedules.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 選択日がない場合は空の一覧にし、ある場合はその日の予定を取得します。
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
          // 月表示のカレンダーです。日付を選ぶ操作と月の切り替えをここで扱います。
          TableCalendar<Schedule>(
            firstDay: DateTime(2000, 1, 1),
            lastDay: DateTime(2100, 12, 31),
            focusedDay: _focusedDay,
            locale: 'ja_JP',
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {
              CalendarFormat.month: '月',
              CalendarFormat.twoWeeks: '2週間',
              CalendarFormat.week: '週',
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },

            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
            ),
            // 選択中の日付を強調表示するための条件を指定します。
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            // 選択中の日付に重なる予定を返す関数を指定します。
            eventLoader: _eventsForDay,
            // 日付を選ぶと、選択日と表示中の日付を更新します。
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            // 別の月へ移動したとき、画面上部の年月表示も更新します。
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          const Divider(),
          // 選択した日の予定を表示し、予定がなければ案内文を表示します。
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
