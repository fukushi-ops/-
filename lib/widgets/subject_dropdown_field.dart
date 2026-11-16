import 'package:flutter/material.dart';

import '../data/repository/subject_repository.dart';
import '../screens/subject/subject_registration_screen.dart';

class SubjectDropdownField extends StatefulWidget {
  const SubjectDropdownField({
    super.key,
    required this.termId,
    required this.onChanged,
    this.initialValue,
    this.validator,
    this.label = '科目',
  });

  final int termId;
  final String? initialValue;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;
  final String label;

  @override
  State<SubjectDropdownField> createState() => _SubjectDropdownFieldState();
}

class _SubjectDropdownFieldState extends State<SubjectDropdownField> {
  late Future<List<String>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = SubjectRepository.load(termId: widget.termId);
  }

  Future<void> _registerSubject() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SubjectRegistrationScreen(termId: widget.termId),
      ),
    );
    if (!mounted) return;
    setState(() {
      _subjectsFuture = SubjectRepository.load(termId: widget.termId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _subjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('科目の読み込みに失敗しました: ${snapshot.error}');
        }
        final subjects = snapshot.data!;
        if (subjects.isEmpty) {
          return InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _registerSubject,
                icon: const Icon(Icons.add),
                label: const Text('先に科目を登録'),
              ),
            ),
          );
        }

        final initialValue = subjects.contains(widget.initialValue)
            ? widget.initialValue
            : null;
        return DropdownButtonFormField<String>(
          initialValue: initialValue,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.menu_book_outlined),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final subject in subjects)
              DropdownMenuItem(value: subject, child: Text(subject)),
          ],
          onChanged: widget.onChanged,
          validator:
              widget.validator ??
              (value) => value == null ? '科目を選択してください' : null,
        );
      },
    );
  }
}
