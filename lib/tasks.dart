import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const _ink = Color(0xFF172B35);
const _teal = Color(0xFF087F70);

/// A single to-do item.
class Task {
  Task(this.title, {this.done = false, this.id});
  final String title;
  final String? id;
  bool done;
}

/// Shared Firestore tasks, or an in-memory list when Firebase isn't initialized.
class TaskStore extends ChangeNotifier {
  TaskStore() {
    if (!_ready) return;
    try {
      _subscription = _collection.orderBy('createdAt').snapshots().listen((
        snapshot,
      ) {
        if (_disposed) return;
        final updated = <Task>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data['title'] is String && data['done'] is bool) {
            updated.add(
              Task(
                data['title'] as String,
                done: data['done'] as bool,
                id: doc.id,
              ),
            );
          }
        }
        tasks
          ..clear()
          ..addAll(updated);
        notifyListeners();
      }, onError: _reportError);
    } catch (error) {
      _reportError(error);
    }
  }

  static final TaskStore shared = TaskStore();

  bool get _ready => Firebase.apps.isNotEmpty;
  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('tasks');
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool _disposed = false;
  String? errorMessage;
  final List<Task> tasks = [];

  void _reportError(Object error) {
    debugPrint('TaskStore: $error');
    if (_disposed) return;
    errorMessage =
        'Could not sync tasks. Check your connection and Firestore rules.';
    notifyListeners();
  }

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
      if (_disposed) return;
      errorMessage = null;
      notifyListeners();
    } catch (error) {
      _reportError(error);
    }
  }

  void add(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    if (_ready) {
      if (trimmed.runes.length > 200) {
        errorMessage = 'Task titles must be 200 characters or fewer.';
        notifyListeners();
        return;
      }
      unawaited(
        _write(() async {
          await _collection.add({
            'title': trimmed,
            'done': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }),
      );
      return;
    }
    tasks.add(Task(trimmed));
    notifyListeners();
  }

  void setDone(Task task, bool done) {
    if (_ready) {
      if (task.id != null) {
        unawaited(
          _write(() => _collection.doc(task.id).update({'done': done})),
        );
      }
      return;
    }
    task.done = done;
    notifyListeners();
  }

  void remove(Task task) {
    if (_ready) {
      if (task.id != null) {
        unawaited(_write(() => _collection.doc(task.id).delete()));
      }
      return;
    }
    tasks.remove(task);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// App bar button that slides the task list in from the right. It's a filled,
/// labeled button that shows how many tasks are still open.
/// Use it in `AppBar(actions: [...])` on a Scaffold that has a [TasksDrawer].
class TasksButton extends StatelessWidget {
  const TasksButton({super.key, this.store});

  /// Defaults to [TaskStore.shared]. Tests pass their own.
  final TaskStore? store;

  @override
  Widget build(BuildContext context) {
    final taskStore = store ?? TaskStore.shared;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: AnimatedBuilder(
        animation: taskStore,
        builder: (context, _) {
          final open = taskStore.tasks.where((t) => !t.done).length;
          return FilledButton.icon(
            key: const Key('open-tasks'),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.checklist_rounded, size: 20),
            label: Text(
              open > 0 ? 'Tasks ($open)' : 'Tasks',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }
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
              if (_store.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    _store.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
