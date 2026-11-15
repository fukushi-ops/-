import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/task/assignment_screen.dart';
import 'package:my_app/screens/task/task_data.dart';
import 'package:my_app/screens/task/task_detail_screen.dart';

void main() {
  setUp(() {
    TaskData.tasks = [
      Task(title: '数学レポート', subject: '数学', deadline: '2026-11-12'),
      Task(
        title: '数学小テスト',
        subject: '数学',
        deadline: '2026-11-14',
        isDone: true,
      ),
      Task(title: '英語課題', subject: '英語', deadline: '2026-11-13'),
    ];
  });

  tearDown(() {
    TaskData.tasks = [];
  });

  testWidgets('課題詳細画面を表示できる', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TaskDetailScreen(
          task: Task(
            id: 1,
            title: '数学レポート',
            subject: '数学',
            deadline: '2026-11-30',
            priority: 2,
            progress: 40,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('課題詳細'), findsOneWidget);
    expect(find.text('数学レポート'), findsOneWidget);
  });

  testWidgets('課題を教科と提出状況で絞り込める', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));

    expect(find.text('数学レポート'), findsOneWidget);
    expect(find.text('数学小テスト'), findsOneWidget);
    expect(find.text('英語課題'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '数学'));
    await tester.pumpAndSettle();

    expect(find.text('数学 の課題'), findsOneWidget);
    expect(find.text('数学レポート'), findsOneWidget);
    expect(find.text('数学小テスト'), findsOneWidget);
    expect(find.text('英語課題'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '未提出'));
    await tester.pumpAndSettle();

    expect(find.text('数学レポート'), findsOneWidget);
    expect(find.text('数学小テスト'), findsNothing);
    expect(find.text('英語課題'), findsNothing);
  });

  testWidgets('キーワードと評価・難易度を組み合わせて検索できる', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TaskData.tasks = [
      Task(
        title: 'データ整理',
        subject: '情報',
        deadline: '2026-11-20',
        reflectionScore: 2,
        reflectionDifficulty: '難しい',
        reflectionLearned: '保存方法を学んだ',
      ),
      Task(
        title: '画面制作',
        subject: '情報',
        deadline: '2026-11-21',
        reflectionScore: 4,
        reflectionDifficulty: '難しい',
      ),
      Task(
        title: '基礎練習',
        subject: '情報',
        deadline: '2026-11-22',
        reflectionScore: 2,
        reflectionDifficulty: '簡単',
      ),
    ];

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));

    await tester.enterText(find.byType(TextField), '保存方法');
    await tester.pumpAndSettle();
    expect(find.text('データ整理'), findsOneWidget);
    expect(find.text('画面制作'), findsNothing);
    expect(find.text('基礎練習'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '条件'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('指定なし').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3以下').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('難しい').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('この条件で絞り込む'));
    await tester.pumpAndSettle();

    expect(find.text('データ整理'), findsOneWidget);
    expect(find.text('画面制作'), findsNothing);
    expect(find.text('基礎練習'), findsNothing);
  });

  testWidgets('締切が近い課題を優先し、同じ時期なら手動優先度順に並べる', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateUtils.dateOnly(DateTime.now());
    final laterDeadline = today.add(const Duration(days: 20));
    TaskData.tasks = [
      Task(
        title: '優先度低',
        subject: '情報',
        deadline: laterDeadline.toIso8601String(),
        priority: 3,
      ),
      Task(
        title: '優先度高',
        subject: '情報',
        deadline: laterDeadline.toIso8601String(),
        priority: 1,
      ),
      Task(
        title: '締切間近',
        subject: '情報',
        deadline: today.add(const Duration(days: 2)).toIso8601String(),
        priority: 3,
      ),
    ];

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));

    final urgentPosition = tester.getTopLeft(find.text('締切間近')).dy;
    final highPriorityPosition = tester.getTopLeft(find.text('優先度高').last).dy;
    final lowPriorityPosition = tester.getTopLeft(find.text('優先度低').last).dy;
    expect(urgentPosition, lessThan(highPriorityPosition));
    expect(highPriorityPosition, lessThan(lowPriorityPosition));
  });
}
