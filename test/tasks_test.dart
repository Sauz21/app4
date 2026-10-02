import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4/tasks.dart';

void main() {
  const emptyMessage = 'No tasks yet. Add one, or start the timer.';

  Widget app(TaskStore store) => MaterialApp(
    home: TasksPage(store: store, next: (_) => const Text('timer screen')),
  );

  testWidgets('Tasks can be added, checked off and deleted', (tester) async {
    await tester.pumpWidget(app(TaskStore()));
    expect(find.text(emptyMessage), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('task-input')),
      'Study chapter 4',
    );
    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pump();
    expect(find.text('Study chapter 4'), findsOneWidget);
    expect(find.text(emptyMessage), findsNothing);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    expect(find.text('Study chapter 4'), findsNothing);
    expect(find.text(emptyMessage), findsOneWidget);
  });

  testWidgets('Blank tasks are ignored', (tester) async {
    await tester.pumpWidget(app(TaskStore()));
    await tester.enterText(find.byKey(const Key('task-input')), '   ');
    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pump();
    expect(find.text(emptyMessage), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('Start timer continues to the next screen', (tester) async {
    await tester.pumpWidget(app(TaskStore()));
    expect(find.text('timer screen'), findsNothing);

    await tester.tap(find.byKey(const Key('start-timer')));
    await tester.pumpAndSettle();
    expect(find.text('timer screen'), findsOneWidget);
    expect(find.byKey(const Key('task-input')), findsNothing);
  });

  testWidgets('Tasks are kept when the page is reopened', (tester) async {
    final store = TaskStore()..add('Read notes');
    await tester.pumpWidget(app(store));
    expect(find.text('Read notes'), findsOneWidget);
  });
}
