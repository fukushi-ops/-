import 'package:flutter/material.dart';

import '../data/repository/lesson_repository.dart';
import '../screens/term/term_management_screen.dart';

class ActiveTermAction extends StatelessWidget {
  const ActiveTermAction({super.key, required this.onTermSelected});

  final Future<void> Function(int termId) onTermSelected;

  Future<void> _openTermManager(BuildContext context) async {
    final selectedTermId = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => TermManagementScreen(
          currentTermId: LessonRepository.activeTermId,
        ),
      ),
    );
    if (selectedTermId == null || !context.mounted) return;

    try {
      await onTermSelected(selectedTermId);
    } on Exception catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('期間の切り替えに失敗しました: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final termName = LessonRepository.activeTermName ?? '期間';
    return Tooltip(
      message: '学年・学期を切り替える',
      child: TextButton.icon(
        onPressed: () => _openTermManager(context),
        icon: const Icon(Icons.event_repeat),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 112),
          child: Text(termName, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
