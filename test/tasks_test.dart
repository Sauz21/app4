import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app4/tasks.dart';

void main() {
  const emptyMessage = 'No tasks yet. Add your first one above.';

  Widget app(TaskStore store) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Timer'), actions: const [TasksButton()]),
      endDrawer: TasksDrawer(store: store),
      body: const Text('timer body'),
    ),
  );

  Future<void> openTasks(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('open-tasks')));
    await tester.pumpAndSettle();
  }

  testWidgets('Tasks panel opens and closes', (tester) async {
    await tester.pumpWidget(app(TaskStore()));
    expect(find.byKey(const Key('task-input')), findsNothing);

    await openTasks(tester);
    expect(find.byKey(const Key('task-input')), findsOneWidget);
    expect(find.text(emptyMessage), findsOneWidget);

    await tester.tap(find.byKey(const Key('close-tasks')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-input')), findsNothing);
    expect(find.text('timer body'), findsOneWidget);
  });

  testWidgets('Tasks can be added, checked off and deleted', (tester) async {
    await tester.pumpWidget(app(TaskStore()));
    await openTasks(tester);

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
    await openTasks(tester);
    await tester.enterText(find.byKey(const Key('task-input')), '   ');
    await tester.tap(find.byKey(const Key('add-task')));
    await tester.pump();
    expect(find.text(emptyMessage), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('Tasks are kept when the panel is reopened', (tester) async {
    await tester.pumpWidget(app(TaskStore()..add('Read notes')));
    await openTasks(tester);
    expect(find.text('Read notes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('close-tasks')));
    await tester.pumpAndSettle();
    await openTasks(tester);
    expect(find.text('Read notes'), findsOneWidget);
  });
}
