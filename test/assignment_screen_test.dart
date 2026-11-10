import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/screens/task/assignment_screen.dart';
import 'package:my_app/screens/task/task_data.dart';

void main() {
  setUp(() {
    TaskData.tasks = [
      Task(
        title: '数学レポート',
        subject: '数学',
        deadline: '2026-11-12',
      ),
      Task(
        title: '数学小テスト',
        subject: '数学',
        deadline: '2026-11-14',
        isDone: true,
      ),
      Task(
        title: '英語課題',
        subject: '英語',
        deadline: '2026-11-13',
      ),
    ];
  });

  tearDown(() {
    TaskData.tasks = [];
  });

  testWidgets('課題を教科と提出状況で絞り込める', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AssignmentScreen()),
    );

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
}
