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

/// Shown after you pick a tree and before the focus timer. Add, check off and
/// delete tasks, then continue to the timer built by [next].
class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.next, this.store});

  /// Builds the screen to show when the person taps "Start timer".
  final WidgetBuilder next;

  /// Defaults to [TaskStore.shared]. Tests pass their own.
  final TaskStore? store;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _controller = TextEditingController();
  late final TaskStore _store = widget.store ?? TaskStore.shared;

  void _add() {
    _store.add(_controller.text);
    _controller.clear();
  }

  void _startTimer() => Navigator.of(
    context,
  ).pushReplacement(MaterialPageRoute<void>(builder: widget.next));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your tasks')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: AnimatedBuilder(
            animation: _store,
            builder: (context, _) {
              final tasks = _store.tasks;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'What will you work on?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          key: const Key('add-task'),
                          onPressed: _add,
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add task'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: tasks.isEmpty
                        ? const Center(
                            child: Text(
                              'No tasks yet. Add one, or start the timer.',
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                            itemCount: tasks.length,
                            itemBuilder: (context, i) {
                              final task = tasks[i];
                              return Padding(
                                key: ObjectKey(task),
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: task.done
                                        ? const Color(0xFFE9EEF0)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFD8E1E5),
                                    ),
                                  ),
                                  child: ListTile(
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
                                        color: task.done
                                            ? Colors.blueGrey
                                            : _ink,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('start-timer'),
                        onPressed: _startTimer,
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start timer'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
