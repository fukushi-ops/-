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

  String? _artifactName;
  String? _artifactDescription;
  String? _artifactLocation;

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
            children: [
              _DetailItem(label: '成果物名', value: _artifactName ?? '未登録'),
              _DetailItem(label: '説明', value: _artifactDescription ?? '未登録'),
              _DetailItem(label: '保存場所', value: _artifactLocation ?? '未登録'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _editArtifact,
                  icon: Icon(_artifactName == null ? Icons.add : Icons.edit),
                  label: Text(_artifactName == null ? '成果物を追加' : '編集'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.delete_outline),
            label: const Text('課題を削除'),
          ),
        ],
      ),
    );
  }

  bool _isLoadingArtifact = true;

  @override
  void initState() {
    super.initState();
    _loadArtifact();
  }

  Future<void> _loadArtifact() async {
    final taskId = widget.task.id;

    if (taskId == null) {
      setState(() => _isLoadingArtifact = false);
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
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoadingArtifact = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('成果物の読み込みに失敗しました。$error')));
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

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
