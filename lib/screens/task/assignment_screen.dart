import 'package:flutter/material.dart';

import '../../data/repository/lesson_repository.dart';
import '../../data/repository/task_repository.dart';
import '../../services/simple_notification_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  int _statusFilter = 0;
  String _subjectFilter = 'すべて';
  int _maxScoreFilter = 0;
  String _difficultyFilter = 'すべて';
  String _deadlineFilter = 'すべて';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Task> get _subjectsTasks {
    final tasks = TaskData.tasks.where(_matchesFilters).toList();

    tasks.sort((a, b) {
      final urgencyCompare = _urgencyRank(a).compareTo(_urgencyRank(b));
      if (urgencyCompare != 0) return urgencyCompare;
      final priorityCompare = a.priority.compareTo(b.priority);
      if (priorityCompare != 0) return priorityCompare;
      final aDate = DateTime.tryParse(a.deadline);
      final bDate = DateTime.tryParse(b.deadline);
      if (aDate == null) return bDate == null ? 0 : 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });
    return tasks;
  }

  int _urgencyRank(Task task) {
    if (task.isDone) return 4;
    final deadline = DateTime.tryParse(task.deadline);
    if (deadline == null) return 3;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysLeft = dueDay.difference(today).inDays;
    if (daysLeft <= 0) return 0;
    if (daysLeft <= 3) return 1;
    if (daysLeft <= 7) return 2;
    return 3;
  }

  bool _matchesFilters(Task task) {
    if (_statusFilter == 1 && task.isDone) return false;
    if (_statusFilter == 2 && !task.isDone) return false;
    if (_subjectFilter != 'すべて' && task.subject.trim() != _subjectFilter) {
      return false;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      final searchableText = [
        task.title,
        task.subject,
        task.reflectionDifficulty ?? '',
        task.reflectionLearned ?? '',
        task.reflectionGoodPoint ?? '',
        task.reflectionImprovement ?? '',
      ].join('\n').toLowerCase();
      if (!searchableText.contains(query)) return false;
    }

    if (_maxScoreFilter > 0 &&
        (task.reflectionScore == null ||
            task.reflectionScore! > _maxScoreFilter)) {
      return false;
    }
    if (_difficultyFilter != 'すべて' &&
        task.reflectionDifficulty?.trim() != _difficultyFilter) {
      return false;
    }

    if (_deadlineFilter != 'すべて') {
      final deadline = DateTime.tryParse(task.deadline);
      if (_deadlineFilter == '期限未設定') {
        if (deadline != null) return false;
      } else {
        if (task.isDone || deadline == null) return false;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dueDay = DateTime(deadline.year, deadline.month, deadline.day);
        if (_deadlineFilter == '期限切れ') {
          if (!dueDay.isBefore(today)) return false;
        } else if (_deadlineFilter == '7日以内') {
          if (dueDay.isBefore(today) ||
              dueDay.isAfter(today.add(const Duration(days: 7)))) {
            return false;
          }
        }
      }
    }
    return true;
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

  List<String> get _difficulties => [
    'すべて',
    ...TaskData.tasks
        .map((task) => task.reflectionDifficulty?.trim() ?? '')
        .where((difficulty) => difficulty.isNotEmpty)
        .toSet()
        .toList()
      ..sort(),
  ];

  int get _activeFilterCount =>
      (_maxScoreFilter > 0 ? 1 : 0) +
      (_difficultyFilter != 'すべて' ? 1 : 0) +
      (_deadlineFilter != 'すべて' ? 1 : 0);

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
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: '課題名・科目・振り返りを検索',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '検索をクリア',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openAdvancedFilters,
                    icon: const Icon(Icons.tune),
                    label: Text(
                      _activeFilterCount == 0 ? '条件' : '条件 $_activeFilterCount',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
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
          ),
          SliverToBoxAdapter(
            child: Padding(
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
          ),
          SliverToBoxAdapter(
            child: SizedBox(
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
          ),
          SliverToBoxAdapter(
            child: Padding(
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
          ),
          if (filteredTasks.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyAssignments(
                subjectFilter: _subjectFilter,
                statusFilter: _statusFilter,
                hasAdditionalFilters:
                    _searchController.text.trim().isNotEmpty ||
                    _activeFilterCount > 0,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildTaskCard(context, filteredTasks[index]),
                  childCount: filteredTasks.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : FloatingActionButton.extended(
              heroTag: 'addTaskFab',
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('課題を追加'),
            ),
    );
  }

  Future<void> _openAdvancedFilters() async {
    var maxScore = _maxScoreFilter;
    var difficulty = _difficultyFilter;
    var deadline = _deadlineFilter;
    final difficulties = _difficulties;
    final result = await showModalBottomSheet<(int, String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '条件を指定して絞り込む',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: maxScore,
                  decoration: const InputDecoration(
                    labelText: '自己評価',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('指定なし')),
                    ...List.generate(5, (index) => 5 - index).map(
                      (score) => DropdownMenuItem(
                        value: score,
                        child: Text('$score以下'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => maxScore = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: difficulties.contains(difficulty)
                      ? difficulty
                      : 'すべて',
                  decoration: const InputDecoration(
                    labelText: '難易度',
                    border: OutlineInputBorder(),
                  ),
                  items: difficulties
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value == 'すべて' ? '指定なし' : value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setSheetState(() => difficulty = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: deadline,
                  decoration: const InputDecoration(
                    labelText: '締切',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'すべて', child: Text('指定なし')),
                    DropdownMenuItem(value: '期限切れ', child: Text('期限切れ（未提出）')),
                    DropdownMenuItem(value: '7日以内', child: Text('7日以内（未提出）')),
                    DropdownMenuItem(value: '期限未設定', child: Text('期限未設定')),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => deadline = value);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setSheetState(() {
                        maxScore = 0;
                        difficulty = 'すべて';
                        deadline = 'すべて';
                      }),
                      child: const Text('条件をリセット'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, (
                        maxScore,
                        difficulty,
                        deadline,
                      )),
                      child: const Text('この条件で絞り込む'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _maxScoreFilter = result.$1;
      _difficultyFilter = result.$2;
      _deadlineFilter = result.$3;
    });
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
        final messenger = ScaffoldMessenger.maybeOf(context);
        try {
          await TaskRepository.delete(task);
          try {
            await NotificationService.cancelTaskDeadlineNotifications(task);
          } on Exception catch (error) {
            messenger?.showSnackBar(
              SnackBar(content: Text('課題は削除しましたが、締切通知の取消しに失敗しました。$error')),
            );
          }
          return true;
        } catch (error) {
          messenger?.showSnackBar(
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
                          _StatusBadge(
                            label: '優先度${_priorityLabel(task.priority)}',
                            color: _priorityColor(task.priority),
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
                      if (task.progress > 0 && !task.isDone) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: task.progress.clamp(0, 100) / 100,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '進捗 ${task.progress.clamp(0, 100)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
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

  String _priorityLabel(int priority) => switch (priority) {
    1 => '高',
    3 => '低',
    _ => '中',
  };

  Color _priorityColor(int priority) => switch (priority) {
    1 => Colors.deepOrange,
    3 => Colors.blueGrey,
    _ => Colors.indigo,
  };

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
      await _updateDeadlineReminder(savedTask);
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
      await _updateDeadlineReminder(editedTask);
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
      await _updateDeadlineReminder(task);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('提出状況の更新に失敗しました。$error')));
    }
  }

  Future<void> _updateDeadlineReminder(Task task) async {
    try {
      await NotificationService.updateTaskDeadlineNotification(task);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('課題は保存しましたが、締切通知の設定に失敗しました。$error')),
      );
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
    required this.hasAdditionalFilters,
  });

  final String subjectFilter;
  final int statusFilter;
  final bool hasAdditionalFilters;

  @override
  Widget build(BuildContext context) {
    final message = TaskData.tasks.isEmpty
        ? '課題がまだありません'
        : hasAdditionalFilters
        ? '条件に合う課題はありません'
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
              '検索語や絞り込み条件を変更してみてください',
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
