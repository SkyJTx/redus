import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('Observe widget', () {
    testWidgets('rebuilds when source changes', (tester) async {
      final count = ref(0);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Observe<int>(
          source: count.call,
          builder: (context, value) {
            buildCount++;
            return Text('Count: $value');
          },
        ),
      ));

      expect(buildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);

      // Update value
      count.value = 42;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('works with computed source', (tester) async {
      final count = ref(1);
      final doubled = computed(() => count.value * 2);

      await tester.pumpWidget(MaterialApp(
        home: Observe<int>(
          source: doubled.call,
          builder: (context, value) => Text('Doubled: $value'),
        ),
      ));

      expect(find.text('Doubled: 2'), findsOneWidget);

      count.value = 5;
      await tester.pump();

      expect(find.text('Doubled: 10'), findsOneWidget);
    });

    testWidgets('works with getter function source', (tester) async {
      final a = ref(10);
      final b = ref(20);

      await tester.pumpWidget(MaterialApp(
        home: Observe<int>(
          source: () => a.value + b.value,
          builder: (context, sum) => Text('Sum: $sum'),
        ),
      ));

      expect(find.text('Sum: 30'), findsOneWidget);

      a.value = 15;
      await tester.pump();

      expect(find.text('Sum: 35'), findsOneWidget);
    });

    testWidgets('only Observe rebuilds, not parent', (tester) async {
      final count = ref(0);
      var parentBuilds = 0;
      var observeBuilds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          parentBuilds++;
          return Column(
            children: [
              const Text('Static parent'),
              Observe<int>(
                source: count.call,
                builder: (context, value) {
                  observeBuilds++;
                  return Text('Count: $value');
                },
              ),
            ],
          );
        }),
      ));

      expect(parentBuilds, 1);
      expect(observeBuilds, 1);

      // Update ref - only Observe should rebuild
      count.value++;
      await tester.pump();

      expect(parentBuilds, 1); // Parent NOT rebuilt
      expect(observeBuilds, 2); // Observe rebuilt
    });
  });

  group('ObserveMultiple widget', () {
    testWidgets('rebuilds when any source changes', (tester) async {
      final firstName = ref('John');
      final lastName = ref('Doe');

      await tester.pumpWidget(MaterialApp(
        home: ObserveMultiple<String>(
          sources: [firstName.call, lastName.call],
          builder: (context, values) => Text('${values[0]} ${values[1]}'),
        ),
      ));

      expect(find.text('John Doe'), findsOneWidget);

      firstName.value = 'Jane';
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);

      lastName.value = 'Smith';
      await tester.pumpAndSettle();

      expect(find.text('Jane Smith'), findsOneWidget);
    });
  });
}
