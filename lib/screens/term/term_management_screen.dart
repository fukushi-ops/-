import 'package:flutter/material.dart';

import '../../data/data_main/isar_models.dart';
import '../../data/repository/lesson_repository.dart';

class TermManagementScreen extends StatefulWidget {
  const TermManagementScreen({super.key, required this.currentTermId});

  final int currentTermId;

  @override
  State<TermManagementScreen> createState() => _TermManagementScreenState();
}

class _TermManagementScreenState extends State<TermManagementScreen> {
  late Future<List<AcademicTerm>> _termsFuture;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _termsFuture = LessonRepository.loadTerms();
  }

  int get _currentSchoolYear {
    final now = DateTime.now();
    return now.month >= 4 ? now.year : now.year - 1;
  }

  Future<String?> _askForTermName() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('期間を作成'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: '期間名',
              hintText: '例：1年後期',
            ),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('次へ'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<bool?> _askHowToHandleExistingData(String termName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('現在のデータについて'),
        content: Text(
          '現在の期間「${LessonRepository.activeTermName}」の時間割・科目・課題を'
          '「$termName」に移動しますか？\n\n'
          '移動すると、現在の期間にはデータが残りません。分析画面も新しい期間の課題を表示します。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('現在の期間に残す'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('まとめて移動'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTerm() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);
    try {
      final termName = await _askForTermName();
      if (!mounted || termName == null) return;
      if (termName.isEmpty) {
        _showMessage('期間名を入力してください。');
        return;
      }

      final schoolYear = _currentSchoolYear;
      if (await LessonRepository.termExists(
        schoolYear: schoolYear,
        termName: termName,
      )) {
        if (mounted) _showMessage('同じ年度に同じ期間名がすでにあります。');
        return;
      }

      final hasData = await LessonRepository.hasTermData(
        termId: widget.currentTermId,
      );
      final moveExistingData = hasData
          ? await _askHowToHandleExistingData(termName)
          : false;
      if (!mounted || moveExistingData == null) return;

      final term = await LessonRepository.createTerm(
        schoolYear: schoolYear,
        termName: termName,
        moveExistingData: moveExistingData,
      );
      if (!mounted) return;
      Navigator.pop<int>(context, term.id);
    } on Exception catch (error) {
      if (mounted) _showMessage('期間を作成できませんでした: $error');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学年・学期の切り替え')),
      body: FutureBuilder<List<AcademicTerm>>(
        future: _termsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('期間を読み込めませんでした: ${snapshot.error}'),
              ),
            );
          }
          final terms = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '時間割・科目・課題を期間ごとに管理できます。期間名は自由に設定できます。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final term in terms)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      term.id == widget.currentTermId
                          ? Icons.check_circle
                          : Icons.calendar_month_outlined,
                      color: term.id == widget.currentTermId
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(term.termName),
                    subtitle: Text('${term.schoolYear}年度'),
                    trailing: term.id == widget.currentTermId
                        ? const Text('使用中')
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop<int>(context, term.id),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _createTerm,
        icon: const Icon(Icons.add),
        label: const Text('期間を追加'),
      ),
    );
  }
}
