import 'dart:async';

import 'package:flutter/material.dart';

import 'session_store.dart';

const _ink = Color(0xFF172B35);
const _teal = Color(0xFF087F70);

/// A tree that can be grown during a focus session.
class FocusTree {
  const FocusTree({
    required this.id,
    required this.name,
    required this.unlockAfter,
    required this.icon,
    required this.foliageColor,
    required this.trunkColor,
    this.accentIcon,
    this.accentColor,
    this.backgroundColor,
    this.showTrunk = true,
  });
  final String id;
  final String name;
  final Duration unlockAfter;
  final IconData icon;
  final Color foliageColor;
  final Color trunkColor;
  final IconData? accentIcon;
  final Color? accentColor;
  final Color? backgroundColor;
  final bool showTrunk;
  bool isUnlocked(Duration focusedTime) => focusedTime >= unlockAfter;
}

/// The trees available in the first release of the picker.
class TreeCatalog {
  static const trees = <FocusTree>[
    FocusTree(id: 'sprout', name: 'Focus Sprout', unlockAfter: Duration.zero, icon: Icons.spa_rounded, foliageColor: Color(0xFF64B48E), trunkColor: Color(0xFF9A6A45)),
    FocusTree(id: 'cedar', name: 'Quiet Cedar', unlockAfter: Duration(minutes: 20), icon: Icons.park_rounded, foliageColor: Color(0xFF2D8B72), trunkColor: Color(0xFF795548)),
    FocusTree(id: 'maple', name: 'Amber Maple', unlockAfter: Duration(minutes: 40), icon: Icons.nature_rounded, foliageColor: Color(0xFFD5844F), trunkColor: Color(0xFF805238), showTrunk: false),
    FocusTree(
      id: 'moon-tree',
      name: 'Moon Pine',
      unlockAfter: Duration(minutes: 60),
      icon: Icons.park_rounded,
      foliageColor: Color(0xFF3D6E80),
      trunkColor: Color(0xFF654A3B),
      accentIcon: Icons.nightlight_round,
    ),
    FocusTree(
      id: 'willow',
      name: 'River Willow',
      unlockAfter: Duration(hours: 2),
      icon: Icons.park_rounded,
      foliageColor: Color(0xFF4D9C89),
      trunkColor: Color(0xFF75553C),
      backgroundColor: Color(0xFFD7F0F1),
    ),
    FocusTree(
      id: 'blossom',
      name: 'Blossom Tree',
      unlockAfter: Duration(hours: 3),
      icon: Icons.local_florist_rounded,
      foliageColor: Color(0xFFE08AA6),
      trunkColor: Color(0xFF865C48),
      showTrunk: false,
    ),
    FocusTree(
      id: 'redwood',
      name: 'Sunset Redwood',
      unlockAfter: Duration(hours: 4),
      icon: Icons.forest_rounded,
      foliageColor: Color(0xFFB65F45),
      trunkColor: Color(0xFF684234),
      accentIcon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFFD26A),
      backgroundColor: Color(0xFFF9E1CC),
      showTrunk: false,
    ),
  ];
}

/// Cumulative time that has elapsed while a focus timer is actively running.
class StudyProgress extends ChangeNotifier {
  StudyProgress({Duration focusedTime = Duration.zero})
    : _focusedTime = focusedTime;

  Duration _focusedTime;
  Duration get focusedTime => _focusedTime;

  void addFocusedTime(Duration duration) {
    if (duration <= Duration.zero) return;
    _focusedTime += duration;
    notifyListeners();
  }

  /// Seeds progress once from saved sessions so unlocks survive app restarts.
  // ponytail: only finished sessions are saved, so partial time from an unfinished session is lost on restart.
  void restoreFrom(Stream<int> savedMinutes) {
    savedMinutes.first.then(
      (minutes) => addFocusedTime(Duration(minutes: minutes)),
      onError: (Object _) {},
    );
  }
}

class TreePicker extends StatefulWidget {
  const TreePicker({super.key, this.progress});
  static final StudyProgress _appProgress = StudyProgress()
    ..restoreFrom(totalMinutes());
  final StudyProgress? progress;
  @override
  State<TreePicker> createState() => _TreePickerState();
}

class _TreePickerState extends State<TreePicker> {
  late final StudyProgress _progress =
      widget.progress ?? TreePicker._appProgress;
  late FocusTree _selectedTree = TreeCatalog.trees.first;

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    return Scaffold(
    appBar: AppBar(title: const Text('Choose your tree')),
    body: SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('Pick a tree to grow', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _ink)),
                const SizedBox(height: 8),
                Text('Keep the timer running to unlock more companions. ${_durationLabel(progress.focusedTime)} focused so far.', style: const TextStyle(color: Colors.blueGrey, height: 1.5)),
                const SizedBox(height: 24),
                ...TreeCatalog.trees.map((tree) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TreeOptionCard(tree: tree, focusedTime: progress.focusedTime, selected: tree.id == _selectedTree.id, onSelected: () => setState(() => _selectedTree = tree)),
                )),
                const SizedBox(height: 10),
                FilledButton.icon(
                  key: const Key('start-selected-focus'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FocusSession(tree: _selectedTree, progress: progress))),
                  style: FilledButton.styleFrom(backgroundColor: _teal, padding: const EdgeInsets.symmetric(vertical: 18)),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start with ${_selectedTree.name}'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class TreeOptionCard extends StatelessWidget {
  const TreeOptionCard({super.key, required this.tree, required this.focusedTime, required this.selected, required this.onSelected});
  final FocusTree tree;
  final Duration focusedTime;
  final bool selected;
  final VoidCallback onSelected;
  @override
  Widget build(BuildContext context) {
    final unlocked = tree.isUnlocked(focusedTime);
    final remaining = tree.unlockAfter - focusedTime;
    return Semantics(
      button: unlocked,
      enabled: unlocked,
      label: unlocked ? 'Select ${tree.name}' : '${tree.name} locked',
      child: InkWell(
        key: Key('tree-selector-${tree.id}'), onTap: unlocked ? onSelected : null, borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: unlocked ? Colors.white : const Color(0xFFE9EEF0), borderRadius: BorderRadius.circular(20), border: Border.all(color: selected && unlocked ? _teal : const Color(0xFFD8E1E5), width: selected && unlocked ? 2 : 1)),
          child: Row(children: [
            _TreeArt(tree: tree, muted: !unlocked), const SizedBox(width: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tree.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: unlocked ? _ink : Colors.blueGrey)),
              const SizedBox(height: 5),
              Text(unlocked ? (selected ? 'Selected for your next session' : 'Ready to grow') : 'Unlock after ${_durationLabel(tree.unlockAfter)} of active focus${remaining > Duration.zero ? ' (${_durationLabel(remaining)} to go)' : ''}', style: const TextStyle(color: Colors.blueGrey)),
            ])),
            Icon(unlocked ? (selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded) : Icons.lock_rounded, color: unlocked && selected ? _teal : Colors.blueGrey),
          ]),
        ),
      ),
    );
  }
}

class _TreeArt extends StatelessWidget {
  const _TreeArt({required this.tree, required this.muted});
  final FocusTree tree;
  final bool muted;
  @override
  Widget build(BuildContext context) => Container(
    width: 70, height: 70,
    decoration: BoxDecoration(
      color:
          muted
              ? Colors.blueGrey.withValues(alpha: 0.15)
              : (tree.backgroundColor ?? tree.foliageColor).withValues(
                alpha: tree.backgroundColor == null ? 0.15 : 0.8,
              ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(alignment: Alignment.center, children: [
      Icon(tree.icon, size: 49, color: muted ? Colors.blueGrey : tree.foliageColor),
      if (tree.showTrunk)
        Positioned(
          bottom: 10,
          child: Container(
            width: 8,
            height: 13,
            color: muted ? Colors.blueGrey : tree.trunkColor,
          ),
        ),
      if (tree.accentIcon != null)
        Positioned(
          top: 8,
          right: 8,
          child: Icon(
            tree.accentIcon,
            size: 18,
            color:
                muted
                    ? Colors.blueGrey
                    : tree.accentColor ?? const Color(0xFFF4D77B),
          ),
        ),
    ]),
  );
}

class FocusSession extends StatefulWidget {
  const FocusSession({super.key, required this.tree, required this.progress});
  final FocusTree tree;
  final StudyProgress progress;
  @override
  State<FocusSession> createState() => _FocusSessionState();
}

class _FocusSessionState extends State<FocusSession> {
  int seconds = 25 * 60;
  Timer? timer;
  bool get running => timer?.isActive ?? false;
  void toggle() {
    if (running) {
      setState(() => timer?.cancel());
      return;
    }
    if (seconds == 0) seconds = 25 * 60;
    setState(() {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          seconds--;
          widget.progress.addFocusedTime(const Duration(seconds: 1));
          if (seconds == 0) {
            timer?.cancel();
            saveSession(25);
          }
        });
      });
    });
  }
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your focus session')),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _TreeArt(tree: widget.tree, muted: false), const SizedBox(height: 16),
        Text(widget.tree.name, style: const TextStyle(color: _teal, fontWeight: FontWeight.w700)), const SizedBox(height: 16),
        Text(seconds == 0 ? 'Nice work. Take a breath.' : 'One thing at a time.', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)), const SizedBox(height: 24),
        Text('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w300)), const SizedBox(height: 24),
        FilledButton.icon(onPressed: toggle, icon: Icon(running ? Icons.pause : Icons.play_arrow), label: Text(running ? 'Pause' : 'Start session')),
        const SizedBox(height: 12),
        TextButton(onPressed: () => setState(() { timer?.cancel(); seconds = 25 * 60; }), child: const Text('Reset')),
      ]),
    )),
  );
}

String _durationLabel(Duration duration) {
  if (duration.inMinutes >= 60 && duration.inMinutes % 60 == 0) return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
  return '${duration.inMinutes} min';
}
