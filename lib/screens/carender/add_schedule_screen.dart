import 'package:flutter/material.dart';

import 'schedule.dart';

/// 予定名・期間・色を入力し、作成した予定を前の画面へ返す画面。
class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key, required this.initialDate});

  /// カレンダー画面で選ばれた日付。開始日と終了日の初期値に使う。
  final DateTime initialDate;

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

/// 予定の入力値を管理し、画面表示や日付選択を行う。
class _AddScheduleScreenState extends State<AddScheduleScreen> {
  /// 入力された予定名を取得するためのコントローラー。
  final titleController = TextEditingController();

  /// 予定の開始日と終了日。時刻は切り捨て、日付だけを保持する。
  late DateTime startDate;
  late DateTime endDate;

  /// 選択中の予定の色。
  Color selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    // 前の画面で選ばれた日を、開始日と終了日の初期値にする。
    startDate = DateUtils.dateOnly(widget.initialDate);
    endDate = startDate;
  }

  @override
  void dispose() {
    // 画面を閉じるときに入力コントローラーを解放する。
    titleController.dispose();
    super.dispose();
  }

  /// 日付選択ダイアログを開き、選ばれた日を開始日に設定する。
  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );

    if (selected == null) return;

    setState(() {
      startDate = DateUtils.dateOnly(selected);
      // 終了日が開始日より前にならないよう、必要なら同じ日に合わせる。
      if (endDate.isBefore(startDate)) {
        endDate = startDate;
      }
    });
  }

  /// 開始日以降の日付を選び、予定の終了日に設定する。
  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2100, 12, 31),
    );

    if (selected == null) return;

    setState(() {
      endDate = DateUtils.dateOnly(selected);
    });
  }

  /// 日付を画面表示用の「年/月/日」形式にする。
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    // 予定名・開始日・終了日・色を入力する画面を組み立てる。
    return Scaffold(
      appBar: AppBar(title: const Text('予定を追加')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '予定名（例：冬休み）'),
            ),
            const SizedBox(height: 16),
            const Text('開始日'),
            TextButton(
              onPressed: _selectStartDate,
              child: Text(_formatDate(startDate)),
            ),
            const SizedBox(height: 16),
            const Text('終了日'),
            TextButton(
              onPressed: _selectEndDate,
              child: Text(_formatDate(endDate)),
            ),
            const SizedBox(height: 16),
            const Text('色を選択'),
            Row(
              children: [
                _colorBox(Colors.blue),
                _colorBox(Colors.pink),
                _colorBox(Colors.yellow),
                _colorBox(Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('予定名を入力してください')),
                    );
                    return;
                  }

                  // 入力内容を予定データにまとめ、前の画面へ返す。
                  Navigator.pop(
                    context,
                    Schedule(
                      title: title,
                      startDate: startDate,
                      endDate: endDate,
                      color: selectedColor,
                    ),
                  );
                },
                child: const Text('追加'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 色を選ぶボタンを作り、選択中の色には枠線を表示する。
  Widget _colorBox(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: const EdgeInsets.all(4),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
