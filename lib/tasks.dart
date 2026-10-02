import 'package:flutter/material.dart';

const _ink = Color(0xFF172B35);
const _teal = Color(0xFF087F70);

/// A single to-do item.
class Task {
  Task(this.title, {this.done = false});
  final String title;
  bool done;
}

/// The task list, kept in memory so it survives between focus sessions
/// (but resets when the app restarts).
// Saving tasks to Firestore would need Kenny to update the rules, which only
// allow 'minutes' and 'finishedAt' on sessions.
class TaskStore extends ChangeNotifier {
  static final TaskStore shared = TaskStore();

  final List<Task> tasks = [];

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    tasks.add(Task(trimmed));
    notifyListeners();
  }

  void setDone(Task task, bool done) {
    task.done = done;
    notifyListeners();
  }

  void remove(Task task) {
    tasks.remove(task);
    notifyListeners();
  }
}

/// App bar button that slides the task list in from the right.
/// Use it in `AppBar(actions: [...])` on a Scaffold that has a [TasksDrawer].
class TasksButton extends StatelessWidget {
  const TasksButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('open-tasks'),
    tooltip: 'Tasks',
    icon: const Icon(Icons.checklist_rounded),
    onPressed: () => Scaffold.of(context).openEndDrawer(),
  );
}

/// Side panel with the task list. Use as `Scaffold(endDrawer: TasksDrawer())`.
/// Swipe it away, tap outside it, or use the close button to collapse it.
class TasksDrawer extends StatefulWidget {
  const TasksDrawer({super.key, this.store});

  /// Defaults to [TaskStore.shared]. Tests pass their own.
  final TaskStore? store;

  @override
  State<TasksDrawer> createState() => _TasksDrawerState();
}

class _TasksDrawerState extends State<TasksDrawer> {
  final _controller = TextEditingController();
  late final TaskStore _store = widget.store ?? TaskStore.shared;

  void _add() {
    _store.add(_controller.text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Drawer(
    width: 340,
    child: SafeArea(
      child: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          final tasks = _store.tasks;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('close-tasks'),
                      tooltip: 'Close tasks',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Scaffold.of(context).closeEndDrawer(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('task-input'),
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        decoration: const InputDecoration(
                          hintText: 'Add a task',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('add-task'),
                      tooltip: 'Add task',
                      style: IconButton.styleFrom(backgroundColor: _teal),
                      icon: const Icon(Icons.add),
                      onPressed: _add,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No tasks yet. Add your first one above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, i) {
                          final task = tasks[i];
                          return Padding(
                            key: ObjectKey(task),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: task.done
                                    ? const Color(0xFFE9EEF0)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD8E1E5),
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.only(
                                  left: 4,
                                  right: 0,
                                ),
                                leading: Checkbox(
                                  value: task.done,
                                  activeColor: _teal,
                                  onChanged: (v) =>
                                      _store.setDone(task, v ?? false),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: task.done ? Colors.blueGrey : _ink,
                                    decoration: task.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Delete task',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _store.remove(task),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
