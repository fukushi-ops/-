import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/home_screen.dart';
import 'package:my_app/screens/task/task_data.dart';

void main() {
  tearDown(() {
    TaskData.tasks = [];
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
}
