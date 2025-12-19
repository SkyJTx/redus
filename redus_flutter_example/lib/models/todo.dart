/// Todo data model
class Todo {
  final String id;
  final String text;
  final bool isCompleted;

  Todo({
    required this.id,
    required this.text,
    this.isCompleted = false,
  });

  Todo copyWith({
    String? id,
    String? text,
    bool? isCompleted,
  }) {
    return Todo(
      id: id ?? this.id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() => 'Todo(text: $text, completed: $isCompleted)';
}

/// Filter options for the todo list
enum TodoFilter {
  all,
  active,
  completed,
}
