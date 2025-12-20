import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';
import '../services/todo_store.dart';
import '../widgets/todo_item.dart';
import '../widgets/todo_input.dart';
import '../widgets/todo_filter.dart';

class TodoScreen extends ReactiveWidget {
  TodoScreen({super.key});

  // Store bound to Element - persists across parent rebuilds
  late final store = bind(() => get<TodoStore>());

  @override
  void setup() {
    // Load initial data
    onMounted(() {
      store.loadTodos();
    });

    // Side effect: Log changes (demonstrating watch)
    watch(() => store.todos.value, (todos, prevTodos, _) {
      if (prevTodos != null) {
        final diff = todos.length - prevTodos.length;
        if (diff > 0) debugPrint('Added $diff todo(s)');
        if (diff < 0) debugPrint('Removed ${-diff} todo(s)');
      }
    });

    // Log filter changes
    watch(() => store.filter.value, (newFilter, _, onCleanup) {
      debugPrint('Filter changed to: $newFilter');
    });
  }

  @override
  Widget render(BuildContext context) {
    // Using Observe to watch isLoading state
    return Observe<bool>(
      source: store.isLoading.call,
      builder: (context, isLoading) {
        if (isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Redus Todo'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  // Using Observe to watch activeCount
                  child: Observe<int>(
                    source: store.activeCount.call,
                    builder: (context, count) => Text(
                      '$count active',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter - uses ObserveEffect to auto-track filter changes
              ObserveEffect(
                builder: (context) => TodoFilterWidget(
                  currentFilter: store.filter.value,
                  onFilterChanged: store.setFilter,
                ),
              ),

              // Input
              TodoInput(onSubmit: store.addTodo),

              const Divider(),

              // List - uses ObserveEffect to auto-track filteredTodos
              Expanded(
                child: ObserveEffect(
                  builder: (context) {
                    final todos = store.filteredTodos.value;

                    if (todos.isEmpty) {
                      return Center(
                        child: Text(
                          'No todos found',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return TodoItem(
                          key: ValueKey(todo.id),
                          todo: todo,
                          onToggle: () => store.toggleTodo(todo.id),
                          onDelete: () => store.removeTodo(todo.id),
                        );
                      },
                    );
                  },
                ),
              ),

              // Clear completed button - uses Observe to watch hasCompleted
              Observe<bool>(
                source: store.hasCompleted.call,
                builder: (context, hasCompleted) {
                  if (!hasCompleted) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: store.clearCompleted,
                      child: const Text('Clear Completed'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
