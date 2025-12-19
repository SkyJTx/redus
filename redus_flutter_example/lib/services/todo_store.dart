import 'package:redus_flutter/redus_flutter.dart';
import '../models/todo.dart';

/// Global state management for Todos using Redus
class TodoStore {
  // --- State ---
  
  /// List of all todos
  final todos = ref<List<Todo>>([]);
  
  /// Current filter selection
  final filter = ref(TodoFilter.all);
  
  /// Loading state simulation
  final isLoading = ref(false);

  // --- Computed Properties ---

  late final Computed<List<Todo>> filteredTodos;
  late final Computed<int> totalCount;
  late final Computed<int> activeCount;
  late final Computed<int> completedCount;
  late final Computed<bool> hasCompleted;

  TodoStore() {
    // Determine which todos to show based on filter
    filteredTodos = computed(() {
      final list = todos.value;
      switch (filter.value) {
        case TodoFilter.all:
          return list;
        case TodoFilter.active:
          return list.where((t) => !t.isCompleted).toList();
        case TodoFilter.completed:
          return list.where((t) => t.isCompleted).toList();
      }
    });

    // Stats
    totalCount = computed(() => todos.value.length);
    activeCount = computed(() => todos.value.where((t) => !t.isCompleted).length);
    completedCount = computed(() => todos.value.where((t) => t.isCompleted).length);
    hasCompleted = computed(() => completedCount.value > 0);
  }

  // --- Actions ---

  /// Simulate loading data from an API
  Future<void> loadTodos() async {
    isLoading.value = true;
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data
    todos.value = [
      Todo(id: '1', text: 'Learn Flutter', isCompleted: true),
      Todo(id: '2', text: 'Try Redus Package', isCompleted: false),
      Todo(id: '3', text: 'Star the repo on GitHub', isCompleted: false),
    ];
    
    isLoading.value = false;
  }

  /// Add a new todo
  void addTodo(String text) {
    if (text.trim().isEmpty) return;
    
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
    );
    
    // Immutable update pattern (Vue/React style) is supported
    // but we can also modify the list and trigger if we used a specific List wrapper.
    // Here we replace the list properly for reactivity.
    todos.value = [...todos.value, newTodo];
  }

  /// Toggle completion status
  void toggleTodo(String id) {
    todos.value = todos.value.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(isCompleted: !todo.isCompleted);
      }
      return todo;
    }).toList();
  }

  /// Remove a todo
  void removeTodo(String id) {
    todos.value = todos.value.where((todo) => todo.id != id).toList();
  }

  /// Clear all completed todos
  void clearCompleted() {
    todos.value = todos.value.where((todo) => !todo.isCompleted).toList();
  }

  /// Set the current filter
  void setFilter(TodoFilter newFilter) {
    filter.value = newFilter;
  }
}
