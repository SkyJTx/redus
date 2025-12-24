import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('ObserveEffect widget', () {
    testWidgets('auto-tracks dependencies and rebuilds', (tester) async {
      final count = ref(0);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: ObserveEffect(
          builder: (context) {
            buildCount++;
            return Text('Count: ${count.value}');
          },
        ),
      ));

      expect(buildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);

      // Update value - should trigger rebuild
      count.value = 42;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('tracks multiple dependencies', (tester) async {
      final a = ref(1);
      final b = ref(2);

      await tester.pumpWidget(MaterialApp(
        home: ObserveEffect(
          builder: (context) => Text('Sum: ${a.value + b.value}'),
        ),
      ));

      expect(find.text('Sum: 3'), findsOneWidget);

      a.value = 10;
      await tester.pump();
      expect(find.text('Sum: 12'), findsOneWidget);

      b.value = 20;
      await tester.pump();
      expect(find.text('Sum: 30'), findsOneWidget);
    });

    testWidgets('only ObserveEffect rebuilds, not parent', (tester) async {
      final count = ref(0);
      var parentBuilds = 0;
      var effectBuilds = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          parentBuilds++;
          return Column(
            children: [
              const Text('Static parent'),
              ObserveEffect(
                builder: (context) {
                  effectBuilds++;
                  return Text('Count: ${count.value}');
                },
              ),
            ],
          );
        }),
      ));

      expect(parentBuilds, 1);
      expect(effectBuilds, 1);

      // Update ref - only ObserveEffect should rebuild
      count.value++;
      await tester.pump();

      expect(parentBuilds, 1); // Parent NOT rebuilt
      expect(effectBuilds, 2); // ObserveEffect rebuilt
    });
  });
}
