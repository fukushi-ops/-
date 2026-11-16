import 'package:flutter/material.dart';

import '../../data/repository/subject_repository.dart';

class SubjectRegistrationScreen extends StatefulWidget {
  const SubjectRegistrationScreen({super.key, required this.termId});

  final int termId;

  @override
  State<SubjectRegistrationScreen> createState() =>
      _SubjectRegistrationScreenState();
}

class _SubjectRegistrationScreenState extends State<SubjectRegistrationScreen> {
  final _nameController = TextEditingController();
  late Future<List<String>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = SubjectRepository.load(termId: widget.termId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addSubject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('科目名を入力してください。')));
      return;
    }

    try {
      final added = await SubjectRepository.add(
        termId: widget.termId,
        name: name,
      );
      if (!mounted) return;
      _nameController.clear();
      setState(() {
        _subjectsFuture = SubjectRepository.load(termId: widget.termId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(added ? '「$name」を登録しました。' : '「$name」はすでに登録されています。'),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('科目の登録に失敗しました: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('科目登録')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '先に科目を登録すると、授業や課題の登録時に選択できます。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _addSubject(),
            decoration: const InputDecoration(
              labelText: '科目名',
              hintText: '例：数学',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _addSubject,
            icon: const Icon(Icons.add),
            label: const Text('科目を登録'),
          ),
          const SizedBox(height: 24),
          Text(
            '登録済みの科目',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<String>>(
            future: _subjectsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('科目の読み込みに失敗しました: ${snapshot.error}');
              }
              final subjects = snapshot.data!;
              if (subjects.isEmpty) {
                return const Text('まだ科目が登録されていません。');
              }
              return Card(
                child: Column(
                  children: [
                    for (final subject in subjects)
                      ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(subject),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
