import 'package:flutter/material.dart';
import 'class_screen.dart';
import 'assignment_screen.dart';
import 'sub/class_otherscreen.dart';
import 'karender/calender_screen.dart';
import 'lesson_data.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, required this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = "${now.month}月${now.day}日（${_weekday(now.weekday)}）";
    final today = _weekday(now.weekday);

    print("today = $today");

    // ★ 今日の授業リストを取得
    final lessons = LessonData.lessonsByDay[today]!;

    // ★ 時間順に並べる（startTime を使う）
    lessons.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text(
              'おはよう、${widget.userName}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.black),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // =========================
              // 今日の授業
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalendarScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDEEFF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              '今週の予定 ＞',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.black),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '今日の授業',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Column(
                      children: lessons.map((lesson) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 35,
                                child: Text(
                                  '授業',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '教室: ${lesson.room}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    Text(
                                      '先生: ${lesson.teacher}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    Text(
                                      '時間: ${lesson.time}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // 今日の締切（元のまま）
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '今日の締切',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            '残り5時間',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.black),

                    const SizedBox(height: 10),

                    const Row(
                      children: [
                        Icon(Icons.description, size: 45, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'デザイン基礎　レポート提出',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '5月20日（月）23:59まで',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // 今週の課題（元のまま）
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '今週の課題',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '3 / 5件',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: const LinearProgressIndicator(
                              value: 0.6,
                              minHeight: 18,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.deepPurple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '60%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // 出席率（元のまま）
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3F4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '出席率',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(
                          '全体の出席率',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 65,
                      height: 65,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const CircularProgressIndicator(
                            value: 0.85,
                            strokeWidth: 5,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation(
                              Colors.deepPurple,
                            ),
                          ),
                          const Text(
                            '85%',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassScreen()),
            );
            setState(() {});
          }

          if (index == 2) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AssignmentScreen()),
            );
            setState(() {});
          }

          if (index == 3) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemoScreen()),
            );
            setState(() {});
          }

          if (index == 4) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OtherScreen()),
            );
            setState(() {});
          }
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '時間割',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: '課題'),
          BottomNavigationBarItem(icon: Icon(Icons.sticky_note_2), label: 'メモ'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'その他'),
        ],
      ),
    );
  }
}

class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('メモ'),
      ),
      body: const Center(child: Text('メモ画面', style: TextStyle(fontSize: 20))),
    );
  }
}

String _weekday(int w) {
  const weekdays = ["月", "火", "水", "木", "金", "土", "日"];
  return weekdays[w - 1];
}
