import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'session_store.dart';

import 'tasks.dart';

const _ink = Color(0xFF172B35);
const _teal = Color(0xFF087F70);

/// Returns the zero-based Focus Sprout growth stage for an active session.
///
/// The six stages occur at 0%, 20%, 40%, 60%, 80%, and 100% elapsed.
int focusSproutGrowthStage({
  required int remainingSeconds,
  required int totalSeconds,
}) {
  if (totalSeconds <= 0) return 5;
  final elapsedSeconds = (totalSeconds - remainingSeconds)
      .clamp(0, totalSeconds)
      .toInt();
  return ((elapsedSeconds * 5) ~/ totalSeconds).clamp(0, 5).toInt();
}

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
  const _TreeArt({
    required this.tree,
    required this.muted,
    this.sproutGrowthStage,
    this.size = 70,
  });
  final FocusTree tree;
  final bool muted;
  final int? sproutGrowthStage;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (tree.id == 'sprout' && !muted) {
      return FocusSproutGrowth(
        stage: sproutGrowthStage ?? 0,
        size: size,
      );
    }
    if (!muted && sproutGrowthStage != null) {
      return TreeGrowthArt(
        tree: tree,
        stage: sproutGrowthStage!,
        size: size,
      );
    }
    return Container(
    width: size, height: size,
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
}

/// The six visual growth stages of the default Focus Sprout.
class FocusSproutGrowth extends StatefulWidget {
  const FocusSproutGrowth({super.key, required this.stage, this.size = 150});

  final int stage;
  final double size;

  @override
  State<FocusSproutGrowth> createState() => _FocusSproutGrowthState();
}

class _FocusSproutGrowthState extends State<FocusSproutGrowth>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );
  late final Animation<double> _bounce = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 1.12),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.12, end: 0.97),
      weight: 31,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.97, end: 1),
      weight: 27,
    ),
  ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant FocusSproutGrowth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.clamp(0, 5) != widget.stage.clamp(0, 5)) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeStage = widget.stage.clamp(0, 5).toInt();
    const foliage = <Color>[
      Color(0xFF8BCB99),
      Color(0xFF72BD87),
      Color(0xFF55AC78),
      Color(0xFF3C9B6A),
      Color(0xFF27875C),
      Color(0xFF087F70),
    ];
    const backgrounds = <Color>[
      Color(0xFFEEF7EA),
      Color(0xFFE5F3E7),
      Color(0xFFD9F0E0),
      Color(0xFFCEEBDA),
      Color(0xFFC3E6D4),
      Color(0xFFB7E1CF),
    ];
    const icons = <IconData>[
      Icons.grass_rounded,
      Icons.spa_rounded,
      Icons.energy_savings_leaf_rounded,
      Icons.park_rounded,
      Icons.park_rounded,
      Icons.forest_rounded,
    ];
    final iconSize =
        <double>[0.30, 0.42, 0.54, 0.65, 0.77, 0.88][safeStage] *
        widget.size;

    return ScaleTransition(
      scale: _bounce,
      child: Semantics(
        label: 'Focus Sprout growth stage ${safeStage + 1} of 6',
        child: Container(
          key: Key('focus-sprout-stage-${safeStage + 1}'),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: backgrounds[safeStage],
            borderRadius: BorderRadius.circular(widget.size * 0.26),
            border: Border.all(
              color: foliage[safeStage].withValues(alpha: 0.28),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (safeStage == 4)
                _LayeredLeafTree(size: widget.size, foliage: foliage[safeStage])
              else
                Icon(
                  icons[safeStage],
                  size: iconSize,
                  color: foliage[safeStage],
                ),
              if (safeStage >= 3 && safeStage != 4 && safeStage != 5)
                Positioned(
                  bottom: widget.size * 0.16,
                  child: Container(
                    key: const Key('focus-sprout-growth-trunk'),
                    width: widget.size * 0.09,
                    height: widget.size * (safeStage == 5 ? 0.25 : 0.19),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B6040),
                      borderRadius: BorderRadius.circular(widget.size * 0.05),
                    ),
                  ),
                ),
              if (safeStage == 5)
                Positioned(
                  top: widget.size * 0.12,
                  right: widget.size * 0.12,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: widget.size * 0.14,
                    color: const Color(0xFFF2BE5C),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six-stage growth art for every non-default tree.
class TreeGrowthArt extends StatefulWidget {
  const TreeGrowthArt({
    super.key,
    required this.tree,
    required this.stage,
    this.size = 150,
  });

  final FocusTree tree;
  final int stage;
  final double size;

  @override
  State<TreeGrowthArt> createState() => _TreeGrowthArtState();
}

class _TreeGrowthArtState extends State<TreeGrowthArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );
  late final Animation<double> _bounce = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 1.10),
      weight: 42,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.10, end: 0.98),
      weight: 31,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.98, end: 1),
      weight: 27,
    ),
  ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

  @override
  void didUpdateWidget(covariant TreeGrowthArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.clamp(0, 5) != widget.stage.clamp(0, 5)) {
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = widget.stage.clamp(0, 5).toInt();
    final style = _growthStyleFor(widget.tree);
    final usesNaturalBranches =
        stage == 4 && style.usesNaturalBranchingStage && widget.tree.id != 'willow';
    final hasMultipleTrees = style.multipleTreeStages.contains(stage);
    final foliage = Color.lerp(
      const Color(0xFFFFFFFF),
      widget.tree.foliageColor,
      0.48 + stage * 0.10,
    )!;
    final backdropSeed = widget.tree.backgroundColor ?? widget.tree.foliageColor;
    final background = Color.lerp(
      const Color(0xFFFFFFFF),
      backdropSeed,
      0.12 + stage * 0.045,
    )!;
    final iconSize = <double>[0.30, 0.42, 0.54, 0.65, 0.77, 0.88][stage] *
        widget.size;

    return ScaleTransition(
      scale: _bounce,
      child: Semantics(
        label: '${widget.tree.name} growth stage ${stage + 1} of 6',
        child: Container(
          key: Key('${widget.tree.id}-growth-stage-${stage + 1}'),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(widget.size * 0.26),
            border: Border.all(color: foliage.withValues(alpha: 0.28)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.tree.id == 'willow' && stage >= 4)
                _WillowCanopy(size: widget.size, foliage: foliage)
              else if (usesNaturalBranches)
                _NaturalBranchingTree(
                  size: widget.size,
                  foliage: foliage,
                  trunkColor: widget.tree.trunkColor,
                )
              else
                Icon(style.icons[stage], size: iconSize, color: foliage),
              if (stage >= 3 &&
                  !usesNaturalBranches &&
                  !(widget.tree.id == 'willow' && stage >= 4) &&
                  !hasMultipleTrees)
                Positioned(
                  bottom: widget.size * 0.16,
                  child: Container(
                    key: Key('${widget.tree.id}-growth-trunk'),
                    width: widget.size * 0.09,
                    height: widget.size * (stage == 5 ? 0.25 : 0.19),
                    decoration: BoxDecoration(
                      color: widget.tree.trunkColor,
                      borderRadius: BorderRadius.circular(widget.size * 0.05),
                    ),
                  ),
                ),
              if (stage == 5 && style.finalAccent != null)
                Positioned(
                  top: widget.size * 0.12,
                  right: widget.size * 0.12,
                  child: Icon(
                    style.finalAccent,
                    size: widget.size * 0.14,
                    color: style.accentColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreeGrowthStyle {
  const _TreeGrowthStyle({
    required this.icons,
    this.finalAccent,
    this.accentColor = const Color(0xFFF2BE5C),
    this.usesNaturalBranchingStage = true,
    this.multipleTreeStages = const {},
  });

  final List<IconData> icons;
  final IconData? finalAccent;
  final Color accentColor;
  final bool usesNaturalBranchingStage;
  final Set<int> multipleTreeStages;
}

_TreeGrowthStyle _growthStyleFor(FocusTree tree) {
  const seedlingStages = <IconData>[
    Icons.grass_rounded,
    Icons.spa_rounded,
    Icons.energy_savings_leaf_rounded,
  ];
  return switch (tree.id) {
    'cedar' => const _TreeGrowthStyle(
      icons: [
        ...seedlingStages,
        Icons.park_rounded,
        Icons.nature_rounded,
        Icons.forest_rounded,
      ],
      finalAccent: Icons.park_rounded,
      accentColor: Color(0xFFBCE5D5),
      multipleTreeStages: {5},
    ),
    'maple' => const _TreeGrowthStyle(
      icons: [
        ...seedlingStages,
        Icons.eco_rounded,
        Icons.park_rounded,
        Icons.park_rounded,
      ],
      finalAccent: Icons.energy_savings_leaf_rounded,
      accentColor: Color(0xFFF2C36C),
    ),
    'moon-tree' => const _TreeGrowthStyle(
      icons: [
        ...seedlingStages,
        Icons.park_rounded,
        Icons.park_rounded,
        Icons.forest_rounded,
      ],
      finalAccent: Icons.nightlight_round,
      accentColor: Color(0xFFF1D87B),
      multipleTreeStages: {5},
    ),
    'willow' => const _TreeGrowthStyle(
      icons: [
        ...seedlingStages,
        Icons.park_rounded,
        Icons.park_rounded,
        Icons.park_rounded,
      ],
      finalAccent: Icons.auto_awesome_rounded,
      accentColor: Color(0xFF8ACCD0),
      usesNaturalBranchingStage: false,
    ),
    'blossom' => const _TreeGrowthStyle(
      icons: [
        ...seedlingStages,
        Icons.local_florist_rounded,
        Icons.filter_vintage_rounded,
        Icons.local_florist_rounded,
      ],
      finalAccent: Icons.auto_awesome_rounded,
      accentColor: Color(0xFFF7C3D4),
      usesNaturalBranchingStage: false,
      multipleTreeStages: {4, 5},
    ),
    'redwood' => const _TreeGrowthStyle(
      icons: [
        ...seedlingStages,
        Icons.park_rounded,
        Icons.forest_rounded,
        Icons.forest_rounded,
      ],
      finalAccent: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFFFD16C),
      usesNaturalBranchingStage: false,
      multipleTreeStages: {4, 5},
    ),
    _ => const _TreeGrowthStyle(
      icons: [
        ...seedlingStages,
        Icons.park_rounded,
        Icons.park_rounded,
        Icons.forest_rounded,
      ],
    ),
  };
}

/// A leaf-and-branch canopy used for stage five instead of a diagram icon.
class _NaturalBranchingTree extends StatelessWidget {
  const _NaturalBranchingTree({
    required this.size,
    required this.foliage,
    required this.trunkColor,
  });

  final double size;
  final Color foliage;
  final Color trunkColor;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('natural-branching-tree'),
    width: size * 0.80,
    height: size * 0.84,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: size * 0.10,
          height: size * 0.46,
          decoration: BoxDecoration(
            color: trunkColor,
            borderRadius: BorderRadius.circular(size * 0.05),
          ),
        ),
        Positioned(
          bottom: size * 0.36,
          child: Transform.rotate(
            angle: -0.48,
            child: Container(
              width: size * 0.08,
              height: size * 0.32,
              color: trunkColor,
            ),
          ),
        ),
        Positioned(
          bottom: size * 0.36,
          child: Transform.rotate(
            angle: 0.48,
            child: Container(
              width: size * 0.08,
              height: size * 0.32,
              color: trunkColor,
            ),
          ),
        ),
        _leafCluster(top: size * 0.08, left: size * 0.18, diameter: size * 0.42),
        _leafCluster(top: size * 0.22, left: 0, diameter: size * 0.36),
        _leafCluster(top: size * 0.22, right: 0, diameter: size * 0.36),
      ],
    ),
  );

  Widget _leafCluster({
    required double top,
    double? left,
    double? right,
    required double diameter,
  }) => Positioned(
    top: top,
    left: left,
    right: right,
    child: Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: foliage,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
    ),
  );
}

class _WillowCanopy extends StatelessWidget {
  const _WillowCanopy({required this.size, required this.foliage});

  final double size;
  final Color foliage;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('willow-layered-canopy'),
    width: size * 0.82,
    height: size * 0.84,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: size * 0.10,
          height: size * 0.52,
          decoration: BoxDecoration(
            color: const Color(0xFF75553C),
            borderRadius: BorderRadius.circular(size * 0.05),
          ),
        ),
        for (final offset in <double>[0.04, 0.22, 0.40, 0.58])
          Positioned(
            top: size * 0.10 + (offset == 0.22 || offset == 0.58 ? size * 0.05 : 0),
            left: size * offset,
            child: Container(
              width: size * 0.22,
              height: size * 0.48,
              decoration: BoxDecoration(
                color: foliage.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(size * 0.18),
              ),
            ),
          ),
        Positioned(
          top: 0,
          child: Container(
            width: size * 0.46,
            height: size * 0.30,
            decoration: BoxDecoration(color: foliage, shape: BoxShape.circle),
          ),
        ),
      ],
    ),
  );
}

class _LayeredLeafTree extends StatelessWidget {
  const _LayeredLeafTree({required this.size, required this.foliage});

  final double size;
  final Color foliage;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('layered-leaf-tree'),
    width: size * 0.78,
    height: size * 0.82,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: size * 0.11,
          height: size * 0.43,
          decoration: BoxDecoration(
            color: const Color(0xFF8B6040),
            borderRadius: BorderRadius.circular(size * 0.06),
          ),
        ),
        _leafLayer(top: size * 0.25, left: size * 0.02, diameter: size * 0.35),
        _leafLayer(top: size * 0.20, right: size * 0.02, diameter: size * 0.36),
        _leafLayer(top: size * 0.03, diameter: size * 0.43),
      ],
    ),
  );

  Widget _leafLayer({
    required double top,
    double? left,
    double? right,
    required double diameter,
  }) => Positioned(
    top: top,
    left: left,
    right: right,
    child: Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: foliage,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
    ),
  );
}

class FocusSession extends StatefulWidget {
  const FocusSession({super.key, required this.tree, required this.progress});
  final FocusTree tree;
  final StudyProgress progress;
  @override
  State<FocusSession> createState() => _FocusSessionState();
}

class _FocusSessionState extends State<FocusSession>
    with SingleTickerProviderStateMixin {
  int sessionMinutes = 25;
  int seconds = 25 * 60;
  Timer? timer;
  late final AnimationController _confettiController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool get running => timer?.isActive ?? false;

  Future<void> chooseDuration() async {
    final formKey = GlobalKey<FormState>();
    var minutes = sessionMinutes;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        void applyDuration() {
          if (!formKey.currentState!.validate()) return;
          formKey.currentState!.save();
          Navigator.of(context).pop(minutes);
        }

        return AlertDialog(
          title: const Text('Study duration'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (seconds != sessionMinutes * 60 && seconds > 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Changing duration resets this session timer.'),
                  ),
                TextFormField(
                  initialValue: '$sessionMinutes',
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Minutes',
                    helperText: 'Choose 1–240 minutes',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final number = int.tryParse(value?.trim() ?? '');
                    return number == null || number < 1 || number > 240
                        ? 'Enter a whole number from 1 to 240.'
                        : null;
                  },
                  onSaved: (value) => minutes = int.parse(value!.trim()),
                  onFieldSubmitted: (_) => applyDuration(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: applyDuration,
              child: const Text('Set duration'),
            ),
          ],
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() {
      timer?.cancel();
      _confettiController.reset();
      sessionMinutes = selected;
      seconds = sessionMinutes * 60;
    });
  }

  void toggle() {
    if (running) {
      setState(() => timer?.cancel());
      return;
    }
    if (seconds == 0) {
      seconds = sessionMinutes * 60;
      _confettiController.reset();
    }
    setState(() {
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          seconds--;
          widget.progress.addFocusedTime(const Duration(seconds: 1));
          if (seconds == 0) {
            timer?.cancel();
            _confettiController.forward(from: 0);
            saveSession(sessionMinutes);
          }
        });
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Your focus session'),
      actions: const [TasksButton()],
    ),
    endDrawer: const TasksDrawer(),
    body: SafeArea(
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TreeArt(
                tree: widget.tree,
                muted: false,
                sproutGrowthStage: focusSproutGrowthStage(
                  remainingSeconds: seconds,
                  totalSeconds: sessionMinutes * 60,
                ),
                size: 150,
              ),
              const SizedBox(height: 16),
              Text(
                widget.tree.name,
                style: const TextStyle(
                  color: _teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                seconds == 0
                    ? 'Nice work. Take a breath.'
                    : 'One thing at a time.',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: running ? null : chooseDuration,
                icon: const Icon(Icons.timer_outlined),
                label: Text('Study duration: $sessionMinutes min'),
              ),
              const SizedBox(height: 12),
              Text(
                '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: toggle,
                icon: Icon(running ? Icons.pause : Icons.play_arrow),
                label: Text(running ? 'Pause' : 'Start session'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  timer?.cancel();
                  _confettiController.reset();
                  seconds = sessionMinutes * 60;
                }),
                child: const Text('Reset'),
              ),
            ],
            ),
          ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) => CustomPaint(
                  key: const Key('screen-confetti-fall'),
                  painter: _FallingConfettiPainter(_confettiController.value),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FallingConfettiPainter extends CustomPainter {
  const _FallingConfettiPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    const colors = <Color>[
      Color(0xFFFFD16C),
      Color(0xFFE08AA6),
      Color(0xFF64B48E),
      Color(0xFF74C8D7),
      Color(0xFFF38B5D),
    ];
    for (var index = 0; index < 34; index++) {
      final position = Offset(
        size.width * (index / 33) +
            math.sin(progress * math.pi * 2 + index) * 20,
        -28 - (index % 6) * 16 +
            progress * (size.height * 0.84 + (index % 5) * size.height * 0.16),
      );
      final paint = Paint()..color = colors[index % colors.length];
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(index * 0.71 + progress * math.pi * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

String _durationLabel(Duration duration) {
  if (duration.inMinutes >= 60 && duration.inMinutes % 60 == 0) return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
  return '${duration.inMinutes} min';
}
