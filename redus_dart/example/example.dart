// ignore_for_file: avoid_print

import 'package:redus/reactivity.dart';

/// Example demonstrating Redus reactivity system.
///
/// Run with: `dart run example/example.dart`
void main() {
  // Create reactive values
  final count = ref(0);
  final doubled = computed(() => count.value * 2);

  // React to changes
  watchEffect((_) {
    print('Count: ${count.value}, Doubled: ${doubled.value}');
  });
  // Prints: "Count: 0, Doubled: 0"

  count.value = 5;
  // Prints: "Count: 5, Doubled: 10"

  count.value = 10;
  // Prints: "Count: 10, Doubled: 20"

  // Using effect scopes for cleanup
  final scope = effectScope();

  scope.run(() {
    final name = ref('Redus');

    watchEffect((_) {
      print('Hello, ${name.value}!');
    });

    onScopeDispose(() {
      print('Scope disposed!');
    });

    name.value = 'World';
  });

  // Dispose all effects in the scope
  scope.stop();
  // Prints: "Scope disposed!"
}
