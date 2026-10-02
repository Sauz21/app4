import 'package:app4/tree_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tree unlock thresholds follow the focus-time milestones', () {
    final cedar = TreeCatalog.trees[1];
    final maple = TreeCatalog.trees[2];
    final pine = TreeCatalog.trees[3];

    expect(cedar.isUnlocked(const Duration(minutes: 19, seconds: 59)), isFalse);
    expect(cedar.isUnlocked(const Duration(minutes: 20)), isTrue);
    expect(maple.isUnlocked(const Duration(minutes: 40)), isTrue);
    expect(pine.isUnlocked(const Duration(minutes: 59, seconds: 59)), isFalse);
    expect(pine.isUnlocked(const Duration(minutes: 60)), isTrue);
  });

  testWidgets('picker disables locked trees and enables them from active progress', (tester) async {
    final progress = StudyProgress();
    await tester.pumpWidget(MaterialApp(home: TreePicker(progress: progress)));

    expect(find.text('Focus Sprout'), findsOneWidget);
    expect(find.text('Quiet Cedar'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));

    progress.addFocusedTime(const Duration(minutes: 20));
    await tester.pump();

    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('tree-selector-cedar')));
    await tester.pump();
    expect(find.text('Start with Quiet Cedar'), findsOneWidget);
  });

  testWidgets('focus sessions only add progress while the timer is running', (tester) async {
    final progress = StudyProgress();
    await tester.pumpWidget(
      MaterialApp(
        home: FocusSession(tree: TreeCatalog.trees.first, progress: progress),
      ),
    );

    await tester.tap(find.text('Start session'));
    await tester.pump(const Duration(seconds: 2));
    expect(progress.focusedTime, const Duration(seconds: 2));

    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 2));
    expect(progress.focusedTime, const Duration(seconds: 2));
  });
}
