import 'package:flutter/material.dart';

import '../../data/repository/task_repository.dart';
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
    _loadArtifact();
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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('提出状況の更新に失敗しました。$error')));
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
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isDeletingTask = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('課題の削除に失敗しました。$error')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('課題IDがないため、成果物を保存できません。')));
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('成果物の保存に失敗しました。$error')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('課題IDがないため、成果物を削除できません。')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('成果物の削除に失敗しました。$error')));
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
