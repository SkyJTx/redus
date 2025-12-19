import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';

class TodoInput extends Component {
  final Function(String) onSubmit;

  TodoInput({
    super.key, 
    required this.onSubmit,
  });

  late final TextEditingController controller;
  late final Ref<String> inputValue;
  late final Computed<bool> isValid;

  @override
  void setup() {
    controller = TextEditingController();
    
    // Local reactive state
    inputValue = ref('');
    
    // Derived state: validation
    isValid = computed(() => inputValue.value.trim().isNotEmpty);

    // Sync controller with ref
    controller.addListener(() {
      inputValue.value = controller.text;
    });

    onUnmounted(() {
      controller.dispose();
    });
  }
  
  void _submit() {
    if (isValid.value) {
      onSubmit(inputValue.value);
      controller.clear();
      // Ref updates automatically via listener
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
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isValid.value ? _submit : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
