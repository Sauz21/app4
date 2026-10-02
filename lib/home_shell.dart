import 'package:flutter/material.dart';

import 'tasks.dart';

/// Bottom navigation with a Focus tab (the landing page) and a Tasks tab.
/// The focus page is passed in so this file doesn't depend on main.dart.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.focus});
  final Widget focus;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [widget.focus, const TasksPage()],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        NavigationDestination(
          key: Key('tab-focus'),
          icon: Icon(Icons.timer_outlined),
          selectedIcon: Icon(Icons.timer),
          label: 'Focus',
        ),
        NavigationDestination(
          key: Key('tab-tasks'),
          icon: Icon(Icons.checklist_rounded),
          label: 'Tasks',
        ),
      ],
    ),
  );
}
