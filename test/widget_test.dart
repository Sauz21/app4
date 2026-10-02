import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4/main.dart';

void main() {
  testWidgets('Landing page opens a working focus timer', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Start focusing'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your tree'), findsOneWidget);
    final startFocus = find.byKey(const Key('start-selected-focus'));
    await tester.scrollUntilVisible(startFocus, 200);
    await tester.tap(startFocus);
    await tester.pumpAndSettle();
    expect(find.text('Your focus session'), findsOneWidget);
    await tester.tap(find.text('Start session'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('24:58'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('24:58'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('Tasks can be managed from the focus timer', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Start focusing'));
    await tester.pumpAndSettle();
    final startFocus = find.byKey(const Key('start-selected-focus'));
    await tester.scrollUntilVisible(startFocus, 200);
    await tester.tap(startFocus);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session'));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('open-tasks')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-input')),
      'Finish timer demo',
    );
    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pump();
    expect(find.text('Finish timer demo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('close-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pump();
  });

  testWidgets('Landing page fits a phone screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.text('Start focusing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}