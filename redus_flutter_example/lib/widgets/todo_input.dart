import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';

/// Store for TodoInput local state, bound via bind()
class _TodoInputStore {
  final controller = TextEditingController();
  final inputValue = ref('');

  late final isValid = computed(() => inputValue.value.trim().isNotEmpty);

  _TodoInputStore() {
    // Sync controller with ref
    controller.addListener(() {
      inputValue.value = controller.text;
    });
  }

  void dispose() {
    controller.dispose();
  }
}

class TodoInput extends ReactiveWidget {
  final Function(String) onSubmit;

  TodoInput({super.key, required this.onSubmit});

  // State stored on Element via bind() - persists across parent rebuilds
  late final store = bind(() => _TodoInputStore());

  @override
  void setup() {
    onUnmounted(() {
      store.dispose();
    });
  }

  void _submit() {
    if (store.isValid.value) {
      onSubmit(store.inputValue.value);
      store.controller.clear();
    }
  }

  @override
  Widget render(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: store.controller,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          // Using Observe to watch isValid and update button state
          Observe<bool>(
            source: store.isValid.call,
            builder: (context, isValid) => IconButton.filled(
              onPressed: isValid ? _submit : null,
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
