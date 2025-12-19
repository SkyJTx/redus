import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';
import '../services/todo_store.dart';
import '../widgets/todo_item.dart';
import '../widgets/todo_input.dart';
import '../widgets/todo_filter.dart';

class TodoScreen extends Component {
  TodoScreen({super.key});

  late final TodoStore store;

  @override
  void setup() {
    // Inject store
    store = get<TodoStore>();

    // Load initial data
    onMounted(() {
      store.loadTodos();
    });

    // Side effect: Log changes (demonstrating watch)
    // Using getter function syntax for explicit type inference
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
    if (store.isLoading.value) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Redus Todo'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '${store.activeCount.value} active',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter
          TodoFilterWidget(currentFilter: store.filter.value, onFilterChanged: store.setFilter),

          // Input
          TodoInput(onSubmit: store.addTodo),

          const Divider(),

          // List
          Expanded(
            child: store.filteredTodos.value.isEmpty
                ? Center(
                    child: Text(
                      'No todos found',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: store.filteredTodos.value.length,
                    itemBuilder: (context, index) {
                      final todo = store.filteredTodos.value[index];
                      return TodoItem(
                        // Key is important for correct list updates in Flutter
                        key: ValueKey(todo.id),
                        todo: todo,
                        onToggle: () => store.toggleTodo(todo.id),
                        onDelete: () => store.removeTodo(todo.id),
                      );
                    },
                  ),
          ),

          if (store.hasCompleted.value)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: store.clearCompleted,
                child: const Text('Clear Completed'),
              ),
            ),
        ],
      ),
    );
  }
}
