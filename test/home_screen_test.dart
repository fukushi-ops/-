import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/task/task_data.dart';
import 'package:my_app/data/repository/lesson_repository.dart';

void main() {
  setUp(() {
    LessonRepository.clearHomeRegistrationFlowHiddenCache();
  });

  tearDown(() {
    TaskData.tasks = [];
  });

  testWidgets('登録案内は非表示にしてもボタンから再表示できる', (tester) async {
    Future<void> pumpHome({Key? key}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            key: key,
            userName: 'テスト',
            onSelectTab: (_) {},
            onTermSelected: (_) async {},
            refreshToken: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpHome();
    expect(find.text('登録はこの順番がおすすめです'), findsOneWidget);
    expect(find.text('今週の予定'), findsNothing);

    await tester.tap(find.text('表示しない'));
    await tester.pumpAndSettle();
    expect(find.text('登録はこの順番がおすすめです'), findsNothing);
    expect(find.text('登録のおすすめを表示'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHome(key: const ValueKey('recreated'));
    expect(find.text('登録のおすすめを表示'), findsOneWidget);

    await tester.tap(find.text('登録のおすすめを表示'));
    await tester.pumpAndSettle();
    expect(find.text('登録はこの順番がおすすめです'), findsOneWidget);
  });

  testWidgets('ホームの課題欄には未提出の高優先度課題だけを表示する', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TaskData.tasks = [
      Task(
        title: '締切間近レポート',
        subject: '数学',
        deadline: '2026-11-18',
        priority: 1,
      ),
      Task(
        title: '来週の重要課題',
        subject: '情報',
        deadline: '2026-11-23',
        priority: 1,
      ),
      Task(title: '通常の課題', subject: '英語', deadline: '2026-11-17', priority: 2),
      Task(
        title: '提出済みの重要課題',
        subject: '歴史',
        deadline: '2026-11-17',
        priority: 1,
        isDone: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userName: 'テスト',
          onSelectTab: (_) {},
          onTermSelected: (_) async {},
          refreshToken: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('優先度の高い課題'), findsOneWidget);
    expect(find.text('数学　締切間近レポート'), findsOneWidget);
    expect(find.text('情報　来週の重要課題'), findsOneWidget);
    expect(find.text('英語　通常の課題'), findsNothing);
    expect(find.text('歴史　提出済みの重要課題'), findsNothing);
  });

  testWidgets('今週の課題欄に完了課題と未完了課題を表示する', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final deadline = weekStart.add(const Duration(days: 2)).toIso8601String();
    TaskData.tasks = [
      Task(title: '完了レポート', subject: '数学', deadline: deadline, isDone: true),
      Task(title: '未完了レポート', subject: '英語', deadline: deadline),
      Task(
        title: '来週の課題',
        subject: '情報',
        deadline: weekStart.add(const Duration(days: 8)).toIso8601String(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          userName: 'テスト',
          onSelectTab: (_) {},
          onTermSelected: (_) async {},
          refreshToken: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('完了した課題 (1)'), findsOneWidget);
    expect(find.text('未完了の課題 (1)'), findsOneWidget);
    expect(find.text('完了レポート'), findsOneWidget);
    expect(find.text('未完了レポート'), findsOneWidget);
    expect(find.text('来週の課題'), findsNothing);
  });
}
