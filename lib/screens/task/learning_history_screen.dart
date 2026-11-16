import 'package:flutter/material.dart';

import '../../widgets/active_term_action.dart';
import 'task_data.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({super.key, this.onTermSelected});

  final Future<void> Function(int termId)? onTermSelected;

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
    final trendTasks = _scoredTasksByDeadline();

    return Scaffold(
      appBar: AppBar(
        title: const Text('学習履歴'),
        actions: [
          if (widget.onTermSelected != null)
            ActiveTermAction(onTermSelected: widget.onTermSelected!),
        ],
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
                _SectionTitle(title: '自己評価の推移'),
                const SizedBox(height: 4),
                Text(
                  '課題の締切日順に表示しています。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 12),
                _ScoreTrendChart(tasks: trendTasks),
                const SizedBox(height: 18),
                _SectionTitle(title: '科目別集計'),
                const SizedBox(height: 12),
                ...subjectStats.map((stat) => _SubjectCard(stat: stat)),
              ],
            ),
    );
  }

  double _averageScore(List<Task> tasks) {
    final scoredTasks = tasks
        .where((task) => task.reflectionScore != null)
        .toList();
    if (scoredTasks.isEmpty) return 0;

    final total = scoredTasks.fold<int>(
      0,
      (sum, task) => sum + (task.reflectionScore ?? 0),
    );
    return total / scoredTasks.length;
  }

  List<Task> _scoredTasksByDeadline() {
    final tasks = TaskData.tasks
        .where((task) => task.reflectionScore != null)
        .toList();
    tasks.sort((a, b) {
      final aDate = DateTime.tryParse(a.deadline);
      final bDate = DateTime.tryParse(b.deadline);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return tasks;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _ScoreTrendChart extends StatelessWidget {
  const _ScoreTrendChart({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          '自己評価を記録すると、ここに推移が表示されます。',
          textAlign: TextAlign.center,
        ),
      );
    }

    final chartWidth = (tasks.length * 64.0 + 44)
        .clamp(320.0, double.infinity)
        .toDouble();
    final scores = tasks
        .map((task) => task.reflectionScore!)
        .toList(growable: false);
    final labels = tasks
        .map((task) {
          final deadline = DateTime.tryParse(task.deadline);
          return deadline == null
              ? '日付なし'
              : '${deadline.month}/${deadline.day}';
        })
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          height: 190,
          child: CustomPaint(
            painter: _ScoreTrendPainter(
              scores: scores,
              labels: labels,
              lineColor: theme.colorScheme.primary,
              gridColor: theme.dividerColor.withValues(alpha: 0.5),
              labelColor: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreTrendPainter extends CustomPainter {
  _ScoreTrendPainter({
    required this.scores,
    required this.labels,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<int> scores;
  final List<String> labels;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 32.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var score = 1; score <= 5; score++) {
      final y = top + (5 - score) / 4 * chartHeight;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
      _drawLabel(
        canvas,
        '$score',
        Offset(0, y - 7),
        maxWidth: left - 6,
        alignment: TextAlign.right,
      );
    }

    final points = <Offset>[];
    for (var index = 0; index < scores.length; index++) {
      final x = scores.length == 1
          ? left + chartWidth / 2
          : left + index / (scores.length - 1) * chartWidth;
      final y = top + (5 - scores[index].clamp(1, 5)) / 4 * chartHeight;
      points.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final pointPaint = Paint()..color = lineColor;
    for (var index = 0; index < points.length; index++) {
      canvas.drawCircle(points[index], 5, pointPaint);
      _drawLabel(
        canvas,
        labels[index],
        Offset(points[index].dx - 24, size.height - bottom + 8),
        maxWidth: 48,
        alignment: TextAlign.center,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
    required TextAlign alignment,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
      textAlign: alignment,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ScoreTrendPainter oldDelegate) {
    return oldDelegate.scores != scores ||
        oldDelegate.labels != labels ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelColor != labelColor;
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
              .fold<int>(0, (maxValue, subject) {
                final count = TaskData.tasks
                    .where((task) => task.subject.trim() == subject)
                    .length;
                return count > maxValue ? count : maxValue;
              });
    final ratio = maxCount == 0 ? 0.0 : stat.totalCount / maxCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
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
              Text('課題数: ${stat.totalCount}', style: theme.textTheme.bodySmall),
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
