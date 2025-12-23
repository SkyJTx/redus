// Tests for bind() with watch() in setup() using multiple Ref types.
//
// Verifies that bind() correctly manages indices when fields are accessed
// in different phases (setup vs render) with different types.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('bind() with watch() in setup', () {
    testWidgets('should handle multiple Ref types accessed in different phases',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _WatchWithMultipleRefs()),
      ));

      await tester.pump();

      // Initial state should show "Logs: 0"
      expect(find.text('Logs: 0'), findsOneWidget);
      expect(find.text('Query: '), findsOneWidget);
    });

    testWidgets('watch should trigger callback when Ref value changes',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: _WatchWithMultipleRefs()),
      ));

      await tester.pump();

      // Type in the text field to trigger watch
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // logs count should increase
      expect(find.text('Logs: 1'), findsOneWidget);
      expect(find.text('Query: test'), findsOneWidget);
    });
  });
}

// Test widget: uses watch() in setup() with Ref<String>,
// then accesses Ref<List<String>> in render().
class _WatchWithMultipleRefs extends ReactiveWidget {
  _WatchWithMultipleRefs();

  late final searchQuery = bind(() => ref(''));
  late final logs = bind(() => ref<List<String>>([]));

  @override
  void setup() {
    // watch() accesses searchQuery in its source getter (during setup phase)
    watch(() => searchQuery.value, (newValue, oldValue, onCleanup) {
      if (newValue.isNotEmpty) {
        logs.value = [
          'Changed from "$oldValue" to "$newValue"',
          ...logs.value,
        ].take(5).toList();
      }
    });
  }

  @override
  Widget render(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: (v) => searchQuery.value = v,
        ),
        Text('Query: ${searchQuery.value}'),
        Text('Logs: ${logs.value.length}'),
      ],
    );
  }
}
