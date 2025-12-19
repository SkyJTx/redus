import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';
import '../models/todo.dart';

class TodoItem extends Component {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  void setup() {
    // No local state needed for this component, 
    // it's a pure UI component driven by props.
    // 
    // However, we can use onMounted to demonstrate lifecycle on list items
    /*
    onMounted(() {
      print('Item mounted: ${todo.text}');
    });
    */
  }

  @override
  Widget render(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.isCompleted,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        todo.text,
        style: TextStyle(
          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          color: todo.isCompleted ? Colors.grey : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.redAccent),
        onPressed: onDelete,
      ),
    );
  }
}
