import 'package:flutter/material.dart';

import '../data/repository/lesson_repository.dart';
import '../data/repository/subject_repository.dart';
import '../services/simple_notification_service.dart';
import '../widgets/active_term_action.dart';
import 'carender/calender_screen.dart';
import 'class/lesson_data.dart';
import 'task/task_data.dart';
import 'subject/subject_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final ValueChanged<int> onSelectTab;
  final Future<void> Function(int termId) onTermSelected;
  final int refreshToken;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.onSelectTab,
    required this.onTermSelected,
    required this.refreshToken,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<String>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _refreshSubjects();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _refreshSubjects();
    }
  }

  void _refreshSubjects() {
    final termId = LessonRepository.maybeActiveTermId;
    _subjectsFuture = termId == null
        ? Future.value(const <String>[])
        : SubjectRepository.load(termId: termId);
  }

  Future<void> _openSubjectRegistration() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            SubjectRegistrationScreen(termId: LessonRepository.activeTermId),
      ),
    );
    if (!mounted) return;
    setState(_refreshSubjects);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = "${now.month}月${now.day}日（${_weekday(now.weekday)}）";
    final today = _weekday(now.weekday);
    final highPriorityTasks = TaskData.tasks
        .where((task) => !task.isDone && task.priority == 1)
        .toList()
      ..sort((a, b) {
        final aDeadline = DateTime.tryParse(a.deadline.trim());
        final bDeadline = DateTime.tryParse(b.deadline.trim());
        if (aDeadline == null) return bDeadline == null ? 0 : 1;
        if (bDeadline == null) return -1;
        return aDeadline.compareTo(bDeadline);
      });

    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final weeklyTasks = TaskData.tasks.where((task) {
      final deadline = DateTime.tryParse(task.deadline.trim());

      return deadline != null &&
          !deadline.isBefore(weekStart) &&
          deadline.isBefore(weekEnd);
    }).toList();

    final completedWeeklyTasks = weeklyTasks
        .where((task) => task.isDone)
        .length;

    final weeklyProgress = weeklyTasks.isEmpty
        ? 0.0
        : completedWeeklyTasks / weeklyTasks.length;

    final lessons = List<Lesson>.from(
      LessonData.lessonsByDay[today] ?? const <Lesson>[],
    )..sort((a, b) => a.startTime.compareTo(b.startTime));

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
          ActiveTermAction(onTermSelected: widget.onTermSelected),
          IconButton(
            onPressed: () async {
              await NotificationService.initialize();
              await NotificationService.showTestNotification();
            },
            icon: const Icon(Icons.notifications_none, color: Colors.black),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              FutureBuilder<List<String>>(
                future: _subjectsFuture,
                builder: (context, snapshot) {
                  final lessonCount = LessonData.lessonsByDay.values.fold<int>(
                    0,
                    (total, lessons) => total + lessons.length,
                  );
                  return Column(
                    children: [
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '科目の登録状況を読み込めませんでした: ${snapshot.error}',
                          ),
                        ),
                      _RegistrationFlowCard(
                        subjectCount: snapshot.data?.length,
                        lessonCount: lessonCount,
                        taskCount: TaskData.tasks.length,
                        onRegisterSubjects: _openSubjectRegistration,
                        onOpenTimetable: () => widget.onSelectTab(1),
                        onOpenAssignments: () => widget.onSelectTab(2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '今日の授業  ${lessons.length}件',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalendarScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('今週の予定'),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFDDEEFF),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (lessons.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 34,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            const Text('今日は授業がありません'),
                          ],
                        ),
                      )
                    else
                      ...lessons.indexed.map((entry) {
                        final index = entry.$1;
                        final lesson = entry.$2;
                        final color = Theme.of(context).colorScheme.primary;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              left: BorderSide(color: color, width: 5),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '時限目',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    0,
                                    14,
                                    12,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 7),
                                      _HomeLessonDetail(
                                        icon: Icons.access_time,
                                        text: lesson.time,
                                      ),
                                      const SizedBox(height: 4),
                                      _HomeLessonDetail(
                                        icon: Icons.meeting_room_outlined,
                                        text: lesson.room,
                                      ),
                                      const SizedBox(height: 4),
                                      _HomeLessonDetail(
                                        icon: Icons.person_outline,
                                        text: lesson.teacher,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 優先度の高い課題
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
                          '優先度の高い課題',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.black),

                    const SizedBox(height: 10),

                    if (highPriorityTasks.isEmpty)
                      const Text('未提出の高優先度課題はありません')
                    else
                      ...highPriorityTasks.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.description,
                                size: 45,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${task.subject}　${task.title}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${task.deadline} 締切',
                                      style: const TextStyle(
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
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 今週の課題
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
                    Row(
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
                          '$completedWeeklyTasks / ${weeklyTasks.length}件',
                          style: const TextStyle(
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
                            child: LinearProgressIndicator(
                              value: weeklyProgress,
                              minHeight: 18,
                              backgroundColor: Colors.white,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.deepPurple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(weeklyProgress * 100).round()}%',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistrationFlowCard extends StatelessWidget {
  const _RegistrationFlowCard({
    required this.subjectCount,
    required this.lessonCount,
    required this.taskCount,
    required this.onRegisterSubjects,
    required this.onOpenTimetable,
    required this.onOpenAssignments,
  });

  final int? subjectCount;
  final int lessonCount;
  final int taskCount;
  final VoidCallback onRegisterSubjects;
  final VoidCallback onOpenTimetable;
  final VoidCallback onOpenAssignments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '登録はこの順番がおすすめです',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _RegistrationStep(
              number: '1',
              title: '科目を登録',
              subtitle: subjectCount == null
                  ? '登録状況を確認中...'
                  : subjectCount == 0
                  ? '授業や課題で使う科目を追加します'
                  : '$subjectCount科目登録済み',
              onTap: onRegisterSubjects,
            ),
            _RegistrationStep(
              number: '2',
              title: '時間割を作成',
              subtitle: lessonCount == 0
                  ? '登録した科目を曜日・時限に設定します'
                  : '$lessonCountコマ登録済み',
              onTap: onOpenTimetable,
            ),
            _RegistrationStep(
              number: '3',
              title: '課題を登録',
              subtitle: taskCount == 0
                  ? '科目を選んで課題と締切を追加します'
                  : '$taskCount件登録済み',
              onTap: onOpenAssignments,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationStep extends StatelessWidget {
  const _RegistrationStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String number;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(radius: 16, child: Text(number)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _HomeLessonDetail extends StatelessWidget {
  const _HomeLessonDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

String _weekday(int w) {
  const weekdays = ["月", "火", "水", "木", "金", "土", "日"];
  return weekdays[w - 1];
}
