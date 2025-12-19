import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';
import '../models/todo.dart';

class TodoFilterWidget extends Component {
  final TodoFilter currentFilter;
  final Function(TodoFilter) onFilterChanged;

  TodoFilterWidget({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  void setup() {
    // Stateless setup
  }

  @override
  Widget render(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SegmentedButton<TodoFilter>(
        segments: const [
          ButtonSegment(
            value: TodoFilter.all,
            label: Text('All'),
          ),
          ButtonSegment(
            value: TodoFilter.active,
            label: Text('Active'),
          ),
          ButtonSegment(
            value: TodoFilter.completed,
            label: Text('Completed'),
          ),
        ],
        selected: {currentFilter},
        onSelectionChanged: (Set<TodoFilter> newSelection) {
          onFilterChanged(newSelection.first);
        },
      ),
    );
  }
}
