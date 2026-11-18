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

  testWidgets('未提出の課題詳細では作業メモを表示せず、成果物と振り返りを隠す', (tester) async {
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
    expect(find.text('作業メモ'), findsNothing);
    expect(find.text('成果物'), findsNothing);
    expect(find.text('振り返り'), findsNothing);
    expect(find.text('提出済みにする'), findsOneWidget);
  });

  testWidgets('提出済みの課題詳細で成果物・振り返りを表示し、難易度を数字で選べる', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: TaskDetailScreen(
          task: Task(
            title: '数学レポート',
            subject: '数学',
            deadline: '2026-11-30',
            isDone: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('成果物'), findsOneWidget);
    expect(find.text('振り返り'), findsOneWidget);
    expect(find.text('未提出に戻す'), findsNothing);
    await tester.tap(find.text('振り返りを追加'));
    await tester.pumpAndSettle();

    expect(find.text('難易度（1〜5）'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsWidgets);
    expect(find.text('5 / 5'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('subjectFilterButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, '数学'));
    await tester.pumpAndSettle();

    expect(find.text('数学 の課題'), findsOneWidget);
    expect(find.text('数学レポート'), findsOneWidget);
    expect(find.text('数学小テスト'), findsOneWidget);
    expect(find.text('英語課題'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('statusFilter_1')).last);
    await tester.pumpAndSettle();

    expect(find.text('数学レポート'), findsOneWidget);
    expect(find.text('数学小テスト'), findsNothing);
    expect(find.text('英語課題'), findsNothing);
  });

  testWidgets('課題がない場合は追加アクションを表示する', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TaskData.tasks = [];

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));
    await tester.pumpAndSettle();

    expect(find.text('課題がまだありません'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '課題を追加'), findsOneWidget);
  });

  testWidgets('検索結果がない場合は絞り込みをリセットできる', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));
    await tester.enterText(find.byType(TextField), '該当なし');
    await tester.pumpAndSettle();

    expect(find.text('条件に合う課題はありません'), findsOneWidget);
    await tester.tap(find.text('絞り込みをリセット'));
    await tester.pumpAndSettle();

    expect(find.text('数学レポート'), findsOneWidget);
    expect(find.text('英語課題'), findsOneWidget);
  });

  testWidgets('未提出は締切・進捗を強調し、提出済みはコンパクトに表示する', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateUtils.dateOnly(DateTime.now());
    final deadline = today.add(const Duration(days: 6));
    TaskData.tasks = [
      Task(
        title: '進捗確認',
        subject: '情報',
        deadline: deadline.toIso8601String(),
        priority: 1,
        progress: 50,
      ),
      Task(
        title: '完了済み',
        subject: '非表示科目',
        deadline: deadline.toIso8601String(),
        isDone: true,
        progress: 100,
      ),
    ];

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));
    await tester.pumpAndSettle();

    final pendingCard = find.byKey(const ValueKey('taskCard-進捗確認'));
    final completedCard = find.byKey(const ValueKey('taskCard-完了済み'));
    expect(find.text('あと6日'), findsOneWidget);
    expect(find.text('締切 ${deadline.month}/${deadline.day}'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(
      find.descendant(of: completedCard, matching: find.text('非表示科目')),
      findsNothing,
    );
    expect(
      tester.getSize(completedCard).height,
      lessThan(tester.getSize(pendingCard).height / 2),
    );
    final progressBar = tester.widget<LinearProgressIndicator>(
      find.descendant(
        of: pendingCard,
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(progressBar.minHeight, 8);
    expect(progressBar.valueColor?.value, Colors.amber.shade800);
  });

  testWidgets('スマホ幅では課題追加をアイコンのみのFABで表示する', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));

    expect(find.byTooltip('課題を追加'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('課題を追加'), findsNothing);
  });

  testWidgets('キーボード表示中に画面がオーバーフローしない', (tester) async {
    tester.view.physicalSize = const Size(480, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const MaterialApp(home: AssignmentScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('課題を追加'), findsNothing);
    expect(tester.takeException(), isNull);
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
        reflectionDifficulty: '2',
        reflectionLearned: '保存方法を学んだ',
      ),
      Task(
        title: '画面制作',
        subject: '情報',
        deadline: '2026-11-21',
        reflectionScore: 4,
        reflectionDifficulty: '5',
      ),
      Task(
        title: '基礎練習',
        subject: '情報',
        deadline: '2026-11-22',
        reflectionScore: 2,
        reflectionDifficulty: '3',
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
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    expect(find.text('5以下'), findsOneWidget);
    expect(find.text('4以下'), findsOneWidget);
    expect(find.text('3以下'), findsNWidgets(2));
    expect(find.text('2以下'), findsOneWidget);
    expect(find.text('1以下'), findsOneWidget);
    await tester.tap(find.text('2以下').last);
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
