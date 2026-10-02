import 'package:app4/tasks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tasks remember an optional document ID', () {
    expect(Task('Local').id, isNull);
    final task = Task('Saved', id: 'document-id', done: true);
    expect(task.id, 'document-id');
    expect(task.done, isTrue);
  });

  test('Keyless stores retain synchronous in-memory behavior', () {
    final store = TaskStore();
    addTearDown(store.dispose);
    var notifications = 0;
    store.addListener(() => notifications++);
    store.add('   ');
    expect(notifications, 0);
    store.add('  Read notes  ');
    final task = store.tasks.single;
    expect(task.title, 'Read notes');
    expect(task.id, isNull);
    store.setDone(task, true);
    expect(task.done, isTrue);
    store.remove(task);
    expect(store.tasks, isEmpty);
    expect(notifications, 3);
    expect(store.errorMessage, isNull);
  });
}
