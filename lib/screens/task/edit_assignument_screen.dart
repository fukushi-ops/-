import 'package:flutter/material.dart';

import 'task_data.dart';

class EditAssignmentScreen extends StatefulWidget {
  const EditAssignmentScreen({super.key, required this.task});

  final Task task;

  @override
  State<EditAssignmentScreen> createState() => _EditAssignmentScreenState();
}

class _EditAssignmentScreenState extends State<EditAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _deadlineController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _subjectController = TextEditingController(text: widget.task.subject);
    _deadlineController = TextEditingController(text: widget.task.deadline);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('課題を編集'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: theme.colorScheme.surface.withValues(
                      alpha: 0.75,
                    ),
                    child: Icon(
                      Icons.edit_note,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '課題情報を更新',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '内容を変更して保存してください',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              '基本情報',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '課題名',
                hintText: '例：レポートの提出',
                prefixIcon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '課題名を入力してください' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '教科',
                hintText: '例：情報',
                prefixIcon: Icon(Icons.menu_book_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '教科を入力してください' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deadlineController,
              readOnly: true,
              onTap: _selectDeadline,
              decoration: InputDecoration(
                labelText: '締切日',
                hintText: '日付を選択',
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: IconButton(
                  tooltip: '日付を選択',
                  onPressed: _selectDeadline,
                  icon: const Icon(Icons.calendar_month),
                ),
                helperText: '締切を過ぎた課題は一覧で目立つように表示されます',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '締切日を選択してください';
                }
                if (DateTime.tryParse(value.trim()) == null) {
                  return '有効な日付を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.task.isDone
                        ? Icons.check_circle_outline
                        : Icons.pending_actions,
                    color: widget.task.isDone
                        ? Colors.teal
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '提出状況',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    widget.task.isDone ? '提出済み' : '未提出',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.task.isDone
                          ? Colors.teal
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.lock_outline, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '提出状況は課題一覧または詳細画面から変更できます。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('変更を保存'),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final current = DateTime.tryParse(_deadlineController.text.trim());
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '締切日を選択',
    );
    if (selected == null || !mounted) return;
    _deadlineController.text =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop<Task>(
      context,
      Task(
        id: widget.task.id,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        deadline: _deadlineController.text.trim(),
        isDone: widget.task.isDone,
      ),
    );
  }
}
