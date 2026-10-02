import 'package:flutter/material.dart';

const _ink = Color(0xFF172B35);
const _teal = Color(0xFF087F70);

/// A single to-do item.
class Task {
  Task(this.title, {this.done = false});
  final String title;
  bool done;
}

/// Simple in-memory task list: add, check off, delete.
// Tasks reset when the app restarts. Saving them to Firestore would need Kenny
// to update the rules, which only allow 'minutes' and 'finishedAt' on sessions.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _controller = TextEditingController();
  final _tasks = <Task>[];

  void _add() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() => _tasks.add(Task(title)));
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tasks')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('task-input'),
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        decoration: const InputDecoration(
                          hintText: 'What do you want to get done?',
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
                child: _tasks.isEmpty
                    ? const Center(
                        child: Text(
                          'No tasks yet. Add your first one above.',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: _tasks.length,
                        itemBuilder: (context, i) {
                          final task = _tasks[i];
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
                                      setState(() => task.done = v ?? false),
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
                                  onPressed: () =>
                                      setState(() => _tasks.remove(task)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
