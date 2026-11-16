import 'package:flutter/material.dart';

import '../../data/repository/task_repository.dart';
import '../../services/simple_notification_service.dart';
import 'task_data.dart';
import '../../data/repository/task_artifact_reposirotory.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isUpdatingStatus = false;
  bool _isDeletingTask = false;
  bool _isSavingProgress = false;
  double _draftProgress = 0;

  String? _artifactName;
  String? _artifactDescription;
  String? _artifactLocation;
  String? _artifactLoadError;
  bool _isLoadingArtifact = true;
  bool _isDeletingArtifact = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('課題詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: '課題情報',
            children: [
              _DetailItem(label: '課題名', value: widget.task.title),
              _DetailItem(label: '科目名', value: widget.task.subject),
              _DetailItem(
                label: '提出期限',
                value:
                    '${widget.task.deadline}（${_deadlineStatus(widget.task.deadline)}）',
              ),
              _DetailItem(
                label: '提出状況',
                value: widget.task.isDone ? '提出済み' : '未提出',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUpdatingStatus
                        ? null
                        : _toggleSubmissionStatus,
                    icon: _isUpdatingStatus
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            widget.task.isDone
                                ? Icons.undo
                                : Icons.check_circle_outline,
                          ),
                    label: Text(
                      _isUpdatingStatus
                          ? '保存中...'
                          : widget.task.isDone
                          ? '未提出に戻す'
                          : '提出済みにする',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressSection(context),
          if (widget.task.isDone) ...[
            const SizedBox(height: 16),
            _buildSection(
              title: '成果物',
              children: _isLoadingArtifact
                  ? const [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ]
                  : _artifactLoadError != null
                  ? [
                      ListTile(
                        title: const Text('成果物を読み込めませんでした'),
                        subtitle: Text(_artifactLoadError!),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _loadArtifact,
                          icon: const Icon(Icons.refresh),
                          label: const Text('再試行'),
                        ),
                      ),
                    ]
                  : [
                      if (_artifactName == null)
                        _ArtifactEmptyState(
                          onAdd: _isDeletingArtifact ? null : _editArtifact,
                        )
                      else ...[
                        _ArtifactNameCard(name: _artifactName!),
                        if ((_artifactDescription ?? '').isNotEmpty)
                          _ArtifactDetailRow(
                            icon: Icons.notes_outlined,
                            label: '説明',
                            value: _artifactDescription!,
                          ),
                        if ((_artifactLocation ?? '').isNotEmpty)
                          _ArtifactDetailRow(
                            icon: Icons.folder_open_outlined,
                            label: '保存場所',
                            value: _artifactLocation!,
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isDeletingArtifact
                                    ? null
                                    : _deleteArtifact,
                                icon: _isDeletingArtifact
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.delete_outline),
                                label: const Text('削除'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: _isDeletingArtifact
                                    ? null
                                    : _editArtifact,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('編集'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: '振り返り',
              children: [
                if (widget.task.reflectionScore == null &&
                    (widget.task.reflectionDifficulty ?? '').isEmpty &&
                    (widget.task.reflectionLearned ?? '').isEmpty &&
                    (widget.task.reflectionGoodPoint ?? '').isEmpty &&
                    (widget.task.reflectionImprovement ?? '').isEmpty)
                  _ReflectionEmptyState(onAdd: _editReflection)
                else ...[
                  if (widget.task.reflectionScore != null)
                    _DetailItem(
                      label: '出来栄え',
                      value: '${widget.task.reflectionScore} / 5',
                    ),
                  if ((widget.task.reflectionDifficulty ?? '').isNotEmpty)
                    _DetailItem(
                      label: '難易度',
                      value: _difficultyLabel(widget.task.reflectionDifficulty!),
                    ),
                  if ((widget.task.reflectionLearned ?? '').isNotEmpty)
                    _DetailItem(
                      label: '学んだこと',
                      value: widget.task.reflectionLearned!,
                    ),
                  if ((widget.task.reflectionGoodPoint ?? '').isNotEmpty)
                    _DetailItem(
                      label: 'うまくできたこと',
                      value: widget.task.reflectionGoodPoint!,
                    ),
                  if ((widget.task.reflectionImprovement ?? '').isNotEmpty)
                    _DetailItem(
                      label: '改善点',
                      value: widget.task.reflectionImprovement!,
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _editReflection,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('振り返りを編集'),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isDeletingTask ? null : _deleteTask,
            icon: _isDeletingTask
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(_isDeletingTask ? '削除中...' : '課題を削除'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _draftProgress = widget.task.progress.toDouble();
    if (widget.task.isDone) _loadArtifact();
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);
    final task = widget.task;
    return _buildSection(
      title: '進捗',
      children: [
        Row(
          children: [
            const Expanded(child: Text('優先度')),
            DropdownButton<int>(
              value: task.priority,
              items: const [
                DropdownMenuItem(value: 1, child: Text('高')),
                DropdownMenuItem(value: 2, child: Text('中')),
                DropdownMenuItem(value: 3, child: Text('低')),
              ],
              onChanged: _isSavingProgress
                  ? null
                  : (value) {
                      if (value != null) {
                        _saveTask(task.copyWith(priority: value));
                      }
                    },
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '進捗  ${task.isDone ? 100 : _draftProgress.round()}%',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              task.progressStatus,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: task.isDone ? 100 : _draftProgress.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 10,
          label: '${_draftProgress.round()}%',
          onChanged: task.isDone || _isSavingProgress
              ? null
              : (value) => setState(() => _draftProgress = value),
          onChangeEnd: task.isDone
              ? null
              : (value) => _saveTask(task.copyWith(progress: value.round())),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                '作業チェックリスト',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              tooltip: '項目を追加',
              onPressed: _isSavingProgress ? null : _addChecklistItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (task.checklist.isEmpty)
          Text(
            '作業を分けて登録すると、進み具合を確認できます。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          )
        else
          ...task.checklist.indexed.map((entry) {
            final index = entry.$1;
            final item = entry.$2;
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: item.isDone,
              title: Text(
                item.title,
                style: TextStyle(
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              secondary: IconButton(
                tooltip: '項目を削除',
                onPressed: _isSavingProgress
                    ? null
                    : () => _removeChecklistItem(index),
                icon: const Icon(Icons.close),
              ),
              onChanged: _isSavingProgress
                  ? null
                  : (checked) {
                      final checklist = List<TaskChecklistItem>.from(
                        task.checklist,
                      );
                      checklist[index] = TaskChecklistItem(
                        title: item.title,
                        isDone: checked ?? false,
                      );
                      _saveTask(_taskWithChecklist(task, checklist));
                    },
            );
          }),
        if (_isSavingProgress)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  void _showSnackBar(String message, [BuildContext? targetContext]) {
    final effectiveContext = targetContext ?? context;
    if (!mounted && targetContext == null) return;
    final messenger = ScaffoldMessenger.maybeOf(effectiveContext);
    if (messenger == null) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveTask(Task updatedTask) async {
    if (_isSavingProgress) return;
    setState(() => _isSavingProgress = true);
    try {
      await TaskRepository.update(updatedTask);
      if (!mounted) return;
      setState(() {
        widget.task
          ..priority = updatedTask.priority
          ..progress = updatedTask.progress
          ..checklist = updatedTask.checklist;
        _draftProgress = updatedTask.progress.toDouble();
        _isSavingProgress = false;
      });
      TaskData.notifyChanged();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingProgress = false);
      _showSnackBar('進捗の保存に失敗しました: $error');
    }
  }

  Future<void> _addChecklistItem() async {
    final controller = TextEditingController();
    try {
      final title = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('チェック項目を追加'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: '例：資料を調べる'),
            onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('追加'),
            ),
          ],
        ),
      );
      if (!mounted || title == null || title.isEmpty) return;
      await _saveTask(
        _taskWithChecklist(widget.task, [
          ...widget.task.checklist,
          TaskChecklistItem(title: title),
        ]),
      );
    } finally {
      controller.dispose();
    }
  }

  Task _taskWithChecklist(Task task, List<TaskChecklistItem> checklist) {
    final completedCount = checklist.where((item) => item.isDone).length;
    final progress = checklist.isEmpty
        ? 0
        : (completedCount * 100 / checklist.length).round();
    return task.copyWith(checklist: checklist, progress: progress);
  }

  Future<void> _removeChecklistItem(int index) async {
    final checklist = List<TaskChecklistItem>.from(widget.task.checklist)
      ..removeAt(index);
    await _saveTask(_taskWithChecklist(widget.task, checklist));
  }

  Future<void> _loadArtifact() async {
    setState(() {
      _isLoadingArtifact = true;
      _artifactLoadError = null;
    });

    final taskId = widget.task.id;

    if (taskId == null) {
      setState(() {
        _isLoadingArtifact = false;
        _artifactLoadError = '課題IDがないため、成果物を読み込めません。';
      });
      return;
    }

    try {
      final artifact = await TaskArtifactRepository.loadForTask(taskId: taskId);
      if (!mounted) return;

      setState(() {
        _artifactName = artifact?.name;
        _artifactDescription = artifact?.description;
        _artifactLocation = artifact?.location;
        _isLoadingArtifact = false;
        _artifactLoadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingArtifact = false;
        _artifactLoadError = error.toString();
      });
    }
  }

  Future<void> _toggleSubmissionStatus() async {
    final newStatus = !widget.task.isDone;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await TaskRepository.updateIsDone(task: widget.task, isDone: newStatus);

      if (!mounted) return;

      setState(() {
        widget.task.isDone = newStatus;
        _isUpdatingStatus = false;
      });
      if (newStatus) await _loadArtifact();
      await _updateDeadlineReminder();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isUpdatingStatus = false;
      });

      _showSnackBar('提出状況の更新に失敗しました。$error');
    }
  }

  Future<void> _updateDeadlineReminder() async {
    try {
      await NotificationService.updateTaskDeadlineNotification(widget.task);
    } on Exception catch (error) {
      if (!mounted) return;
      _showSnackBar('提出状況は更新しましたが、締切通知の設定に失敗しました。$error');
    }
  }

  Future<void> _deleteTask() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('課題を削除'),
        content: Text('「${widget.task.title}」を削除しますか？登録済みの成果物も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) return;

    setState(() {
      _isDeletingTask = true;
    });

    try {
      await TaskRepository.delete(widget.task);
      try {
        await NotificationService.cancelTaskDeadlineNotifications(widget.task);
      } on Exception catch (error) {
        if (mounted) {
          _showSnackBar('課題は削除しましたが、締切通知の取消しに失敗しました。$error');
        }
      }
      if (!mounted) return;
      if (Navigator.maybeOf(context) != null) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeletingTask = false;
      });
      _showSnackBar('課題の削除に失敗しました。$error');
    }
  }

  Future<void> _editArtifact() async {
    final nameController = TextEditingController(text: _artifactName ?? '');
    final descriptionController = TextEditingController(
      text: _artifactDescription ?? '',
    );
    final locationController = TextEditingController(
      text: _artifactLocation ?? '',
    );
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<(String, String, String)>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(_artifactName == null ? '成果物を追加' : '成果物を編集'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '成果物名'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? '成果物名を入力してください'
                        : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: '説明'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: '保存場所'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(dialogContext, (
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                  locationController.text.trim(),
                ));
              },
              child: const Text('保存'),
            ),
          ],
        ),
      );

      if (!mounted || result == null) return;

      final taskId = widget.task.id;
      if (taskId == null) {
        _showSnackBar('課題IDがないため、成果物を保存できません。');
        return;
      }

      final artifact = TaskArtifact(
        name: result.$1,
        description: result.$2,
        location: result.$3,
      );

      try {
        await TaskArtifactRepository.saveForTask(
          taskId: taskId,
          artifact: artifact,
        );
        if (!mounted) return;

        setState(() {
          _artifactName = artifact.name;
          _artifactDescription = artifact.description;
          _artifactLocation = artifact.location;
        });
      } catch (error) {
        if (!mounted) return;

        _showSnackBar('成果物の保存に失敗しました。$error');
      }
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      locationController.dispose();
    }
  }

  Future<void> _deleteArtifact() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('成果物を削除'),
        content: const Text('この課題に登録した成果物情報を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) return;

    final taskId = widget.task.id;
    if (taskId == null) {
      _showSnackBar('課題IDがないため、成果物を削除できません。');
      return;
    }

    setState(() {
      _isDeletingArtifact = true;
    });

    try {
      await TaskArtifactRepository.deleteForTask(taskId: taskId);
      if (!mounted) return;

      setState(() {
        _artifactName = null;
        _artifactDescription = null;
        _artifactLocation = null;
        _isDeletingArtifact = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeletingArtifact = false;
      });
      _showSnackBar('成果物の削除に失敗しました。$error');
    }
  }

  Future<void> _editReflection() async {
    final learnedController = TextEditingController(
      text: widget.task.reflectionLearned ?? '',
    );
    final goodPointController = TextEditingController(
      text: widget.task.reflectionGoodPoint ?? '',
    );
    final improvementController = TextEditingController(
      text: widget.task.reflectionImprovement ?? '',
    );
    int? scoreValue = widget.task.reflectionScore;
    final storedDifficulty = widget.task.reflectionDifficulty;
    int? difficultyValue = int.tryParse(storedDifficulty ?? '');
    if (difficultyValue != null &&
        (difficultyValue < 1 || difficultyValue > 5)) {
      difficultyValue = null;
    }

    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<_ReflectionInput?>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('振り返りを記録'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: scoreValue,
                    decoration: const InputDecoration(labelText: '出来栄え'),
                    items: List.generate(5, (index) => index + 1)
                        .map(
                          (score) => DropdownMenuItem(
                            value: score,
                            child: Text('$score / 5'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => scoreValue = value,
                    validator: (value) =>
                        value == null ? '出来栄えを選択してください' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: difficultyValue,
                    decoration: const InputDecoration(labelText: '難易度（1〜5）'),
                    items: List.generate(5, (index) => index + 1)
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text('$level / 5'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => difficultyValue = value,
                  ),
                  TextFormField(
                    controller: learnedController,
                    decoration: const InputDecoration(labelText: '学んだこと'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: goodPointController,
                    decoration: const InputDecoration(labelText: 'うまくできたこと'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: improvementController,
                    decoration: const InputDecoration(labelText: '改善点'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (scoreValue == null || scoreValue! < 1 || scoreValue! > 5) {
                  final messenger = ScaffoldMessenger.maybeOf(dialogContext);
                  messenger?.showSnackBar(
                    const SnackBar(content: Text('出来栄えは1〜5の数字を選択してください。')),
                  );
                  return;
                }
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  _ReflectionInput(
                    score: scoreValue!,
                    difficulty:
                        difficultyValue?.toString() ?? storedDifficulty ?? '',
                    learned: learnedController.text.trim(),
                    goodPoint: goodPointController.text.trim(),
                    improvement: improvementController.text.trim(),
                  ),
                );
              },
              child: const Text('保存'),
            ),
          ],
        ),
      );

      if (!mounted || result == null) return;

      final updatedTask = widget.task.copyWith(
        reflectionScore: result.score,
        reflectionDifficulty: result.difficulty,
        reflectionLearned: result.learned,
        reflectionGoodPoint: result.goodPoint,
        reflectionImprovement: result.improvement,
      );

      try {
        await TaskRepository.update(updatedTask);
        if (!mounted) return;

        setState(() {
          widget.task.reflectionScore = result.score;
          widget.task.reflectionDifficulty = result.difficulty;
          widget.task.reflectionLearned = result.learned;
          widget.task.reflectionGoodPoint = result.goodPoint;
          widget.task.reflectionImprovement = result.improvement;
        });
        TaskData.notifyChanged();
      } catch (error) {
        if (!mounted) return;
        _showSnackBar('振り返りの保存に失敗しました。$error');
      }
    } finally {
      learnedController.dispose();
      goodPointController.dispose();
      improvementController.dispose();
    }
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    final icon = title == '成果物'
        ? Icons.inventory_2_outlined
        : Icons.assignment_outlined;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  String _deadlineStatus(String deadline) {
    final date = DateTime.tryParse(deadline);
    if (date == null) return '日数を計算できません';

    final today = DateTime.now();
    final dueDate = DateTime(date.year, date.month, date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    final daysUntilDeadline = dueDate.difference(todayDate).inDays;

    if (daysUntilDeadline < 0) {
      return '期限切れ（${daysUntilDeadline.abs()}日）';
    }
    if (daysUntilDeadline == 0) {
      return '今日が締切';
    }
    return 'あと$daysUntilDeadline日';
  }

  String _difficultyLabel(String value) {
    final level = int.tryParse(value);
    return level == null ? value : '$level / 5';
  }
}

class _ReflectionInput {
  const _ReflectionInput({
    required this.score,
    required this.difficulty,
    required this.learned,
    required this.goodPoint,
    required this.improvement,
  });

  final int score;
  final String difficulty;
  final String learned;
  final String goodPoint;
  final String improvement;
}

class _ReflectionEmptyState extends StatelessWidget {
  const _ReflectionEmptyState({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.edit_note_outlined,
            size: 38,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            '振り返りはまだ記録されていません',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '出来栄えや難易度（1〜5）、学んだこと、改善点を残しましょう',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('振り返りを追加'),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(dense: true, title: Text(label), subtitle: Text(value));
  }
}

class _ArtifactEmptyState extends StatelessWidget {
  const _ArtifactEmptyState({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 38,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            '成果物はまだ登録されていません',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '提出したファイルや保存場所を記録できます',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('成果物を登録'),
          ),
        ],
      ),
    );
  }
}

class _ArtifactNameCard extends StatelessWidget {
  const _ArtifactNameCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.7),
            child: Icon(
              Icons.description_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '成果物名',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtifactDetailRow extends StatelessWidget {
  const _ArtifactDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: theme.colorScheme.secondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
