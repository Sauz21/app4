import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4/home_shell.dart';
import 'package:app4/tasks.dart';

void main() {
  const emptyMessage = 'No tasks yet. Add your first one above.';

  testWidgets('Tasks can be added, checked off and deleted', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TasksPage()));
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
    await tester.pumpWidget(const MaterialApp(home: TasksPage()));
    await tester.enterText(find.byKey(const Key('task-input')), '   ');
    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pump();
    expect(find.text(emptyMessage), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('Tabs switch between focus page and tasks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeShell(focus: Text('focus page'))),
    );
    expect(find.text('focus page'), findsOneWidget);
    expect(find.byKey(const Key('task-input')), findsNothing);

    await tester.tap(find.byKey(const Key('tab-tasks')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-input')), findsOneWidget);
    expect(find.text('focus page'), findsNothing);
  });
}
