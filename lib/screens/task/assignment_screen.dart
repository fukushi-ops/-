import 'package:flutter/material.dart';

import '../../data/repository/lesson_repository.dart';
import '../../data/repository/task_repository.dart';
import 'add_assignment_screen.dart';
import 'edit_assignument_screen.dart';
import 'task_data.dart';
import 'task_detail_screen.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  int _statusFilter = 0;
  String _subjectFilter = 'すべて';

  List<Task> get _subjectsTasks {
    final tasks = TaskData.tasks.where((task) {
      if (_statusFilter == 1) return !task.isDone;
      if (_statusFilter == 2) return task.isDone;
      return true;
    }).toList();

    if (_subjectFilter != 'すべて') {
      tasks.removeWhere((task) => task.subject.trim() != _subjectFilter);
    }

    tasks.sort((a, b) {
      final aDate = DateTime.tryParse(a.deadline);
      final bDate = DateTime.tryParse(b.deadline);
      if (aDate == null) return bDate == null ? 0 : 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return tasks;
  }

  List<String> get _subjects => [
    'すべて',
    ...TaskData.tasks
        .map((task) => task.subject.trim())
        .where((subject) => subject.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredTasks = _subjectsTasks;
    final subjects = _subjects;
    if (!subjects.contains(_subjectFilter)) _subjectFilter = 'すべて';

    final pendingCount = TaskData.tasks.where((task) => !task.isDone).length;
    final completedCount = TaskData.tasks.length - pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('課題'),
            Text(
              '締切と提出状況をまとめて管理',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'すべて',
                    value: '${TaskData.tasks.length}',
                    icon: Icons.assignment_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '未提出',
                    value: '$pendingCount',
                    icon: Icons.schedule_outlined,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: '提出済み',
                    value: '$completedCount',
                    icon: Icons.check_circle_outline,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'すべて',
                  selected: _statusFilter == 0,
                  onSelected: () => setState(() => _statusFilter = 0),
                ),
                _FilterChip(
                  label: '未提出',
                  selected: _statusFilter == 1,
                  onSelected: () => setState(() => _statusFilter = 1),
                ),
                _FilterChip(
                  label: '提出済み',
                  selected: _statusFilter == 2,
                  onSelected: () => setState(() => _statusFilter = 2),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
            child: Row(
              children: [
                Icon(Icons.book_outlined, size: 18, color: theme.hintColor),
                const SizedBox(width: 8),
                Text(
                  '教科で絞り込む',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final subject = subjects[index];
                return _FilterChip(
                  label: subject,
                  selected: _subjectFilter == subject,
                  onSelected: () => setState(() => _subjectFilter = subject),
                  outlined: true,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _subjectFilter == 'すべて' ? '課題一覧' : '$_subjectFilter の課題',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${filteredTasks.length}件',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredTasks.isEmpty
                ? _EmptyAssignments(
                    subjectFilter: _subjectFilter,
                    statusFilter: _statusFilter,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) =>
                        _buildTaskCard(context, filteredTasks[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('課題を追加'),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final dueDate = DateTime.tryParse(task.deadline);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = dueDate == null
        ? null
        : DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysLeft = dueDay?.difference(today).inDays;
    final isOverdue = !task.isDone && daysLeft != null && daysLeft < 0;
    final isDueToday = !task.isDone && daysLeft == 0;
    final statusColor = task.isDone
        ? Colors.teal
        : isOverdue || isDueToday
        ? Colors.deepOrange
        : theme.colorScheme.primary;
    return Dismissible(
      key: ValueKey(task.id ?? task),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await TaskRepository.delete(task);
          return true;
        } catch (error) {
          if (!messenger.mounted) return false;
          messenger.showSnackBar(
            SnackBar(content: Text('課題の削除に失敗しました。$error')),
          );
          return false;
        }
      },
      onDismissed: (_) => setState(() => TaskData.tasks.remove(task)),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetails(task),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Checkbox(
                  value: task.isDone,
                  activeColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  onChanged: (value) {
                    if (value != null) _updateStatus(task, value);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _SubjectBadge(subject: task.subject),
                          if (task.isDone)
                            const _StatusBadge(
                              label: '提出済み',
                              color: Colors.teal,
                            )
                          else if (isOverdue || isDueToday)
                            _StatusBadge(
                              label: isOverdue ? '期限切れ' : '今日が締切',
                              color: Colors.deepOrange,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone ? theme.hintColor : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.event_outlined,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '締切 ${task.deadline}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!task.isDone &&
                              daysLeft != null &&
                              daysLeft > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              'あと$daysLeft日',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: '課題の操作',
                  onSelected: (action) {
                    if (action == 'edit') _editTask(task);
                    if (action == 'details') _openDetails(task);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'details',
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('詳細'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('編集'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => const AddAssignmentScreen()),
    );
    if (result == null || !mounted) return;

    try {
      final savedTask = await TaskRepository.add(
        termId: LessonRepository.activeTermId,
        task: result,
      );
      if (!mounted) return;
      setState(() {
        TaskData.tasks.add(savedTask);
        TaskData.notifyChanged();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('課題の追加に失敗しました。$error')));
    }
  }

  Future<void> _editTask(Task task) async {
    final editedTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => EditAssignmentScreen(task: task)),
    );
    if (editedTask == null || !mounted) return;

    try {
      await TaskRepository.update(editedTask);
      if (!mounted) return;
      setState(() {
        final index = TaskData.tasks.indexOf(task);
        if (index != -1) TaskData.tasks[index] = editedTask;
        TaskData.notifyChanged();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('課題の更新に失敗しました。$error')));
    }
  }

  Future<void> _openDetails(Task task) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
    if (deleted != true || !mounted) return;
    setState(() {
      TaskData.tasks.remove(task);
      TaskData.notifyChanged();
    });
  }

  Future<void> _updateStatus(Task task, bool isDone) async {
    try {
      await TaskRepository.updateIsDone(task: task, isDone: isDone);
      if (!mounted) return;
      setState(() {
        task.isDone = isDone;
        TaskData.notifyChanged();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('提出状況の更新に失敗しました。$error')));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.outlined = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final color = outlined ? Theme.of(context).colorScheme.secondary : null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        side: outlined && !selected
            ? BorderSide(color: color!.withValues(alpha: 0.35))
            : BorderSide.none,
        selectedColor: (color ?? Theme.of(context).colorScheme.primary)
            .withValues(alpha: 0.14),
        labelStyle: TextStyle(
          color: selected
              ? (color ?? Theme.of(context).colorScheme.primary)
              : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _SubjectBadge extends StatelessWidget {
  const _SubjectBadge({required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        subject,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments({
    required this.subjectFilter,
    required this.statusFilter,
  });

  final String subjectFilter;
  final int statusFilter;

  @override
  Widget build(BuildContext context) {
    final message = TaskData.tasks.isEmpty
        ? '課題がまだありません'
        : subjectFilter != 'すべて'
        ? '$subjectFilter の課題はありません'
        : statusFilter == 1
        ? '未提出の課題はありません'
        : statusFilter == 2
        ? '提出済みの課題はありません'
        : '条件に合う課題はありません';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 52,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '教科や提出状況のフィルターを変更してみてください',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
