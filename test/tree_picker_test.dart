import 'package:app4/tree_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Focus Sprout has six growth stages at 20% intervals', () {
    const totalSeconds = 100;

    expect(
      focusSproutGrowthStage(
        remainingSeconds: totalSeconds,
        totalSeconds: totalSeconds,
      ),
      0,
    );
    expect(
      focusSproutGrowthStage(remainingSeconds: 81, totalSeconds: totalSeconds),
      0,
    );
    expect(
      focusSproutGrowthStage(remainingSeconds: 80, totalSeconds: totalSeconds),
      1,
    );
    expect(
      focusSproutGrowthStage(remainingSeconds: 60, totalSeconds: totalSeconds),
      2,
    );
    expect(
      focusSproutGrowthStage(remainingSeconds: 40, totalSeconds: totalSeconds),
      3,
    );
    expect(
      focusSproutGrowthStage(remainingSeconds: 20, totalSeconds: totalSeconds),
      4,
    );
    expect(
      focusSproutGrowthStage(remainingSeconds: 0, totalSeconds: totalSeconds),
      5,
    );
  });

  testWidgets('Focus Sprout renders the requested growth stage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FocusSproutGrowth(stage: 5)),
    );

    expect(find.byKey(const Key('focus-sprout-stage-6')), findsOneWidget);
    expect(find.byIcon(Icons.forest_rounded), findsOneWidget);
  });

  testWidgets('branching stage uses layered leaves and bounces on growth', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FocusSproutGrowth(stage: 3)),
    );
    await tester.pumpWidget(
      const MaterialApp(home: FocusSproutGrowth(stage: 4)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('focus-sprout-stage-5')), findsOneWidget);
    expect(find.byKey(const Key('layered-leaf-tree')), findsOneWidget);
    expect(find.byType(ScaleTransition), findsOneWidget);
  });

  testWidgets('each unlockable tree has a distinct final growth visual', (
    tester,
  ) async {
    for (final tree in TreeCatalog.trees.skip(1)) {
      await tester.pumpWidget(
        MaterialApp(home: TreeGrowthArt(tree: tree, stage: 5)),
      );
      expect(find.byKey(Key('${tree.id}-growth-stage-6')), findsOneWidget);
      if (tree.id == 'willow') {
        expect(find.byKey(const Key('willow-layered-canopy')), findsOneWidget);
      }
    }
  });

  testWidgets('natural branching art replaces diagram icons and forests lose trunks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: TreeGrowthArt(tree: TreeCatalog.trees[1], stage: 4)),
    );
    expect(find.byKey(const Key('natural-branching-tree')), findsOneWidget);
    expect(find.byIcon(Icons.account_tree_rounded), findsNothing);

    await tester.pumpWidget(
      MaterialApp(home: TreeGrowthArt(tree: TreeCatalog.trees[3], stage: 5)),
    );
    expect(find.byKey(const Key('moon-tree-growth-trunk')), findsNothing);
  });

  test('tree unlock thresholds follow the focus-time milestones', () {
    final cedar = TreeCatalog.trees[1];
    final maple = TreeCatalog.trees[2];
    final moonTree = TreeCatalog.trees[3];
    final willow = TreeCatalog.trees[4];
    final blossom = TreeCatalog.trees[5];
    final redwood = TreeCatalog.trees[6];

    expect(moonTree.name, 'Moon Pine');
    expect(cedar.isUnlocked(const Duration(minutes: 19, seconds: 59)), isFalse);
    expect(cedar.isUnlocked(const Duration(minutes: 20)), isTrue);
    expect(maple.isUnlocked(const Duration(minutes: 40)), isTrue);
    expect(
      moonTree.isUnlocked(const Duration(minutes: 59, seconds: 59)),
      isFalse,
    );
    expect(moonTree.isUnlocked(const Duration(minutes: 60)), isTrue);
    expect(willow.isUnlocked(const Duration(hours: 1, minutes: 59)), isFalse);
    expect(willow.isUnlocked(const Duration(hours: 2)), isTrue);
    expect(blossom.isUnlocked(const Duration(hours: 3)), isTrue);
    expect(redwood.isUnlocked(const Duration(hours: 3, minutes: 59)), isFalse);
    expect(redwood.isUnlocked(const Duration(hours: 4)), isTrue);
  });

  testWidgets(
    'picker disables locked trees and enables them from active progress',
    (tester) async {
      final progress = StudyProgress();
      await tester.pumpWidget(
        MaterialApp(home: TreePicker(progress: progress)),
      );

      expect(find.text('Focus Sprout'), findsOneWidget);
      expect(find.text('Quiet Cedar'), findsOneWidget);
      final cedarCard = find.byKey(const Key('tree-selector-cedar'));
      await tester.scrollUntilVisible(cedarCard, 200);
      expect(
        find.descendant(
          of: cedarCard,
          matching: find.byIcon(Icons.lock_rounded),
        ),
        findsOneWidget,
      );

      progress.addFocusedTime(const Duration(minutes: 20));
      await tester.pump();

      expect(
        find.descendant(
          of: cedarCard,
          matching: find.byIcon(Icons.lock_rounded),
        ),
        findsNothing,
      );
      await tester.tap(cedarCard);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('start-selected-focus')),
        200,
      );
      expect(find.text('Start with Quiet Cedar'), findsOneWidget);
    },
  );

  testWidgets('focus sessions only add progress while the timer is running', (
    tester,
  ) async {
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

  testWidgets('custom duration controls countdown, reset, and restart', (
    tester,
  ) async {
    final progress = StudyProgress();
    await tester.pumpWidget(
      MaterialApp(
        home: FocusSession(tree: TreeCatalog.trees.first, progress: progress),
      ),
    );

    await tester.tap(find.text('Study duration: 25 min'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('1:00'), findsOneWidget);

    Future<void> tapTimerControl(String label) async {
      final control = find.text(label);
      await tester.ensureVisible(control);
      await tester.tap(control);
    }

    await tapTimerControl('Start session');
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0:58'), findsOneWidget);
    final durationButton = find.widgetWithText(
      TextButton,
      'Study duration: 1 min',
    );
    expect(tester.widget<TextButton>(durationButton).onPressed, isNull);
    await tapTimerControl('Pause');
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('0:58'), findsOneWidget);
    await tapTimerControl('Reset');
    await tester.pump();
    expect(find.text('1:00'), findsOneWidget);

    await tapTimerControl('Start session');
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('Nice work. Take a breath.'), findsOneWidget);
    expect(progress.focusedTime, const Duration(seconds: 62));
    await tester.pump(const Duration(seconds: 2));
    expect(progress.focusedTime, const Duration(seconds: 62));
    await tapTimerControl('Start session');
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('0:59'), findsOneWidget);
    await tapTimerControl('Pause');
  });

  testWidgets(
    'duration validates input and cancel preserves the timer on a phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: FocusSession(
            tree: TreeCatalog.trees.first,
            progress: StudyProgress(),
          ),
        ),
      );
      await tester.tap(find.text('Study duration: 25 min'));
      await tester.pumpAndSettle();
      for (final value in ['', '0', '-1', '241', '1.5', 'abc']) {
        await tester.enterText(find.byType(TextFormField), value);
        await tester.tap(find.text('Set duration'));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a whole number from 1 to 240.'),
          findsOneWidget,
        );
      }
      await tester.enterText(find.byType(TextFormField), '45');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('progress restores saved minutes from Firestore', () async {
    final progress = StudyProgress()..restoreFrom(Stream.value(30));
    await Future<void>.delayed(Duration.zero);
    expect(progress.focusedTime, const Duration(minutes: 30));
  });
}
