import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

import '../helpers/test_widgets.dart';

void main() {
  group('.watch(context) fine-grained reactivity', () {
    testWidgets('Ref.watch rebuilds widget when value changes', (tester) async {
      final count = ref(0);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildCount++;
          return Text('Count: ${count.watch(context)}');
        }),
      ));

      expect(buildCount, 1);
      expect(find.text('Count: 0'), findsOneWidget);

      // Update value
      count.value = 42;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 42'), findsOneWidget);
    });

    testWidgets('Computed.watch rebuilds widget when value changes',
        (tester) async {
      final count = ref(1);
      final doubled = computed(() => count.value * 2);
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          buildCount++;
          return Text('Doubled: ${doubled.watch(context)}');
        }),
      ));

      expect(buildCount, 1);
      expect(find.text('Doubled: 2'), findsOneWidget);

      count.value = 5;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Doubled: 10'), findsOneWidget);
    });

    testWidgets('only watching widget rebuilds, not parent', (tester) async {
      final count = ref(0);
      var parentBuilds = 0;
      var childBuilds = 0;

      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            parentBuilds++;
            return Column(
              children: [
                const Text('Static parent'),
                Builder(builder: (ctx) {
                  childBuilds++;
                  return Text('Count: ${count.watch(ctx)}');
                }),
              ],
            );
          },
        ),
      ));

      expect(parentBuilds, 1);
      expect(childBuilds, 1);

      // Update ref - only child should rebuild
      count.value++;
      await tester.pump();

      expect(parentBuilds, 1); // Parent NOT rebuilt
      expect(childBuilds, 2); // Child rebuilt
    });

    testWidgets('multiple watches on same value work correctly',
        (tester) async {
      final name = ref('Alice');
      var build1 = 0;
      var build2 = 0;

      await tester.pumpWidget(MaterialApp(
        home: Column(
          children: [
            Builder(builder: (ctx) {
              build1++;
              return Text('Hello ${name.watch(ctx)}');
            }),
            Builder(builder: (ctx) {
              build2++;
              return Text('Goodbye ${name.watch(ctx)}');
            }),
          ],
        ),
      ));

      expect(build1, 1);
      expect(build2, 1);

      name.value = 'Bob';
      await tester.pump();

      expect(build1, 2);
      expect(build2, 2);
      expect(find.text('Hello Bob'), findsOneWidget);
      expect(find.text('Goodbye Bob'), findsOneWidget);
    });

    testWidgets('watch works in StatelessWidget', (tester) async {
      final count = ref(10);

      await tester.pumpWidget(MaterialApp(
        home: WatchingStatelessWidget(count: count),
      ));

      expect(find.text('Value: 10'), findsOneWidget);

      count.value = 20;
      await tester.pump();

      expect(find.text('Value: 20'), findsOneWidget);
    });
  });
}
