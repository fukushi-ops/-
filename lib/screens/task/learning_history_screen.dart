import 'package:flutter/material.dart';

import 'task_data.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key});

  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  @override
  void initState() {
    super.initState();
    TaskData.changed.addListener(_handleDataChanged);
  }

  @override
  void dispose() {
    TaskData.changed.removeListener(_handleDataChanged);
    super.dispose();
  }

  void _handleDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, _SubjectSummary> _buildSubjectStats() {
    final result = <String, _SubjectSummary>{};

    for (final task in TaskData.tasks) {
      final subject = task.subject.trim();
      if (subject.isEmpty) continue;

      final summary = result.putIfAbsent(
        subject,
        () => _SubjectSummary(subject: subject),
      );
      summary.totalCount++;
      if (task.isDone) summary.completedCount++;
      if (task.reflectionScore != null) {
        summary.scoreTotal += task.reflectionScore!;
        summary.scoreCount++;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final totalTasks = TaskData.tasks.length;
    final completedTasks = TaskData.tasks.where((task) => task.isDone).length;
    final averageScore = _averageScore(TaskData.tasks);
    final subjectStats = _buildSubjectStats().values.toList()
      ..sort((a, b) => b.totalCount.compareTo(a.totalCount));

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習履歴'),
      ),
      body: subjectStats.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(
                  totalTasks: totalTasks,
                  completedTasks: completedTasks,
                  averageScore: averageScore,
                ),
                const SizedBox(height: 18),
                Text(
                  '科目別集計',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...subjectStats.map((stat) => _SubjectCard(stat: stat)),
                const SizedBox(height: 18),
                Text(
                  '最近の課題',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._recentTasks().map((task) => _RecentTaskCard(task: task)),
              ],
            ),
    );
  }

  double _averageScore(List<Task> tasks) {
    final scoredTasks = tasks.where((task) => task.reflectionScore != null).toList();
    if (scoredTasks.isEmpty) return 0;

    final total = scoredTasks.fold<int>(
      0,
      (sum, task) => sum + (task.reflectionScore ?? 0),
    );
    return total / scoredTasks.length;
  }

  List<Task> _recentTasks() {
    final tasks = List<Task>.from(TaskData.tasks);
    tasks.sort((a, b) {
      final aDate = DateTime.tryParse(a.deadline);
      final bDate = DateTime.tryParse(b.deadline);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return tasks.take(5).toList();
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalTasks,
    required this.completedTasks,
    required this.averageScore,
  });

  final int totalTasks;
  final int completedTasks;
  final double averageScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: '総課題数',
            value: '$totalTasks',
            icon: Icons.assignment_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: '提出済み',
            value: '$completedTasks',
            icon: Icons.check_circle_outline,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: '平均評価',
            value: averageScore == 0 ? '未記録' : averageScore.toStringAsFixed(1),
            icon: Icons.star_border_rounded,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.stat});

  final _SubjectSummary stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = TaskData.tasks.isEmpty
        ? 1
        : TaskData.tasks
            .map((task) => task.subject.trim())
            .where((value) => value.isNotEmpty)
            .fold<int>(
              0,
              (maxValue, subject) {
                final count = TaskData.tasks
                    .where((task) => task.subject.trim() == subject)
                    .length;
                return count > maxValue ? count : maxValue;
              },
            );
    final ratio = maxCount == 0 ? 0.0 : stat.totalCount / maxCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.subject,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${stat.completedCount}/${stat.totalCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '課題数: ${stat.totalCount}',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '平均評価: ${stat.averageScore == 0 ? '未記録' : stat.averageScore.toStringAsFixed(1)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTaskCard extends StatelessWidget {
  const _RecentTaskCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = DateTime.tryParse(task.deadline);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (task.isDone)
                const Icon(Icons.check_circle, color: Colors.teal)
              else
                const Icon(Icons.schedule_outlined, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            task.subject,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 16, color: theme.hintColor),
              const SizedBox(width: 6),
              Text(dueDate == null ? task.deadline : '締切 ${task.deadline}'),
              const Spacer(),
              if (task.reflectionScore != null)
                Text(
                  '評価 ${task.reflectionScore} / 5',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text('まだ課題がありません'),
            const SizedBox(height: 6),
            const Text('課題を登録すると学習履歴が表示されます。'),
          ],
        ),
      ),
    );
  }
}

class _SubjectSummary {
  _SubjectSummary({required this.subject});

  final String subject;
  int totalCount = 0;
  int completedCount = 0;
  int scoreCount = 0;
  int scoreTotal = 0;

  double get averageScore {
    if (scoreCount == 0) return 0;
    return scoreTotal / scoreCount;
  }
}
