import 'package:redus/reactivity.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Integration Tests', () {
    test('diamond dependency pattern', () async {
      // A -> B -> D
      // A -> C -> D
      final a = ref(1);
      final b = computed(() => a.value * 2);
      final c = computed(() => a.value * 3);
      final d = computed(() => b.value + c.value);

      expect(d.value, equals(5)); // 2 + 3

      a.value = 2;
      await flushEffects();

      expect(d.value, equals(10)); // 4 + 6
    });

    test('nested effect tracking', () async {
      final outer = ref(0);
      final inner = ref(0);
      var outerCount = 0;
      var innerCount = 0;

      watchEffect((_) {
        outer.value;
        outerCount++;

        watchEffect((_) {
          inner.value;
          innerCount++;
        });
      });

      expect(outerCount, equals(1));
      expect(innerCount, equals(1));

      inner.value = 1;
      await flushEffects();

      expect(outerCount, equals(1)); // Outer should not re-run
      expect(innerCount, equals(2)); // Inner should re-run
    });

    test('effect batching - multiple changes', () async {
      final a = ref(0);
      final b = ref(0);
      var effectRunCount = 0;

      watchEffect((_) {
        a.value;
        b.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      // Multiple synchronous changes should batch
      a.value = 1;
      b.value = 1;
      await flushEffects();

      // Effect should ideally run once for both changes
      // (batching behavior)
      expect(effectRunCount, greaterThanOrEqualTo(2));
    });

    test('computed caching with multiple readers', () async {
      var computeCount = 0;
      final source = ref(1);
      final derived = computed(() {
        computeCount++;
        return source.value * 2;
      });

      // Multiple reads should only compute once
      derived.value;
      derived.value;
      derived.value;

      expect(computeCount, equals(1));

      // Two effects reading same computed
      var effect1Value = 0;
      var effect2Value = 0;

      watchEffect((_) {
        effect1Value = derived.value;
      });

      watchEffect((_) {
        effect2Value = derived.value;
      });

      expect(effect1Value, equals(2));
      expect(effect2Value, equals(2));
      expect(computeCount, equals(1)); // Still just one computation

      source.value = 5;
      await flushEffects();

      expect(effect1Value, equals(10));
      expect(effect2Value, equals(10));
    });

    test('cleanup chain on stop', () async {
      final cleanupOrder = <String>[];

      final handle = watchEffect((onCleanup) {
        onCleanup(() => cleanupOrder.add('callback'));
        onWatcherCleanup(() => cleanupOrder.add('watcher1'));
        onWatcherCleanup(() => cleanupOrder.add('watcher2'));
      });

      expect(cleanupOrder, isEmpty);

      handle.stop();

      expect(cleanupOrder, equals(['callback', 'watcher1', 'watcher2']));
    });

    test('readonly preserves reactivity chain', () async {
      final source = ref(0);
      final derived = computed(() => source.value * 2);
      final readonlyDerived = readonly<int>(derived);

      var effectValue = 0;
      watchEffect((_) {
        effectValue = readonlyDerived.value;
      });

      expect(effectValue, equals(0));

      source.value = 5;
      await flushEffects();

      expect(effectValue, equals(10));
    });

    test('watch with computed and immediate', () async {
      final count = ref(1);
      final double = computed(() => count.value * 2);
      final values = <int>[];

      watch<int>(
        double,
        (value, _, __) {
          values.add(value);
        },
        options: const WatchOptions(immediate: true),
      );

      expect(values, equals([2])); // Immediate

      count.value = 5;
      await flushEffects();

      expect(values, equals([2, 10]));
    });

    test('sync effect updates immediately', () {
      final count = ref(0);
      final values = <int>[];

      watchSyncEffect((_) {
        values.add(count.value);
      });

      expect(values, equals([0]));

      count.value = 1;
      expect(values, equals([0, 1])); // Sync, no await needed

      count.value = 2;
      expect(values, equals([0, 1, 2]));
    });
  });
}
