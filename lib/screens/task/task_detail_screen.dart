import 'package:flutter/material.dart';

import 'task_data.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('課題詳細')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DetailItem(label: '課題名', value: task.title),
          _DetailItem(label: '科目名', value: task.subject),
          _DetailItem(label: '提出期限', value: task.deadline),
          _DetailItem(label: '提出状況', value: task.isDone ? '提出済み' : '未提出'),
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
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}
