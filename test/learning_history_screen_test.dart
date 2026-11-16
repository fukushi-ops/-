import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/main_screen.dart';
import 'package:my_app/screens/task/learning_history_screen.dart';
import 'package:my_app/screens/task/task_data.dart';

void main() {
  tearDown(() {
    TaskData.tasks = [];
  });

  testWidgets('自己評価の推移と科目別集計を表示し、課題履歴は表示しない', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TaskData.tasks = List.generate(
      7,
      (index) => Task(
        title: '課題$index',
        subject: '数学',
        deadline: '2026-11-${(index + 1).toString().padLeft(2, '0')}',
        isDone: true,
        reflectionScore: index % 5 + 1,
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: LearningHistoryScreen()));

    expect(find.text('自己評価の推移'), findsOneWidget);
    expect(find.text('科目別集計'), findsOneWidget);
    expect(find.text('課題履歴（7件）'), findsNothing);
    for (var index = 0; index < 7; index++) {
      expect(find.text('課題$index'), findsNothing);
    }
    expect(find.text('課題の締切日順に表示しています。'), findsOneWidget);
  });

  testWidgets('評価が未記録の場合はグラフの案内を表示する', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TaskData.tasks = [
      Task(title: '未評価の課題', subject: '国語', deadline: '2026-11-20'),
    ];

    await tester.pumpWidget(const MaterialApp(home: LearningHistoryScreen()));

    expect(find.text('自己評価を記録すると、ここに推移が表示されます。'), findsOneWidget);
  });

  testWidgets('課題を削除すると学習分析にも反映される', (tester) async {
    final task = Task(title: '削除する課題', subject: '国語', deadline: '2026-11-20');
    TaskData.tasks = [task];

    await tester.pumpWidget(const MaterialApp(home: LearningHistoryScreen()));
    expect(find.text('国語'), findsOneWidget);

    TaskData.removeTask(task);
    await tester.pumpAndSettle();

    expect(find.text('まだ課題がありません'), findsOneWidget);
    expect(find.text('国語'), findsNothing);
  });

  testWidgets('メイン画面から分析画面を開いて別タブへ移動できる', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TaskData.tasks = [
      Task(
        title: '振り返り済み',
        subject: '情報',
        deadline: '2026-11-20',
        reflectionScore: 4,
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(home: MainScreen(userName: 'テスト')),
    );
    await tester.tap(find.text('分析'));
    await tester.pumpAndSettle();
    expect(find.text('学習履歴'), findsOneWidget);
    expect(find.text('課題履歴（1件）'), findsNothing);

    await tester.tap(find.text('課題').last);
    await tester.pumpAndSettle();
    expect(find.text('課題一覧'), findsOneWidget);
  });
}
