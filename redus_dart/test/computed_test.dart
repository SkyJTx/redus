import 'package:redus/reactivity.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Computed', () {
    test('should compute value from getter', () {
      final count = ref(1);
      final double = computed(() => count.value * 2);

      expect(double.value, equals(2));
    });

    test('should update when dependency changes', () async {
      final count = ref(1);
      final double = computed(() => count.value * 2);

      expect(double.value, equals(2));

      count.value = 5;
      await flushEffects();

      expect(double.value, equals(10));
    });

    test('should be lazy - not compute until accessed', () {
      var computeCount = 0;
      final count = ref(1);
      final double = computed(() {
        computeCount++;
        return count.value * 2;
      });

      expect(computeCount, equals(0)); // Not computed yet

      double.value; // Access triggers computation
      expect(computeCount, equals(1));

      double.value; // Cached, no recomputation
      expect(computeCount, equals(1));
    });

    test('should recompute when dirty', () async {
      var computeCount = 0;
      final count = ref(1);
      final double = computed(() {
        computeCount++;
        return count.value * 2;
      });

      double.value;
      expect(computeCount, equals(1));

      count.value = 2; // Marks computed as dirty
      await flushEffects();

      double.value; // Should recompute
      expect(computeCount, equals(2));
    });

    test('should chain computed values', () async {
      final count = ref(1);
      final double = computed(() => count.value * 2);
      final quadruple = computed(() => double.value * 2);

      expect(quadruple.value, equals(4));

      count.value = 3;
      await flushEffects();

      expect(quadruple.value, equals(12));
    });

    test('should track computed in effects', () async {
      final count = ref(1);
      final double = computed(() => count.value * 2);
      var effectValue = 0;

      watchEffect((_) {
        effectValue = double.value;
      });

      expect(effectValue, equals(2));

      count.value = 5;
      await flushEffects();

      expect(effectValue, equals(10));
    });

    test('isDirty should reflect state', () {
      final count = ref(1);
      final double = computed(() => count.value * 2);

      expect(double.isDirty, isTrue); // Initially dirty

      double.value; // Access clears dirty
      expect(double.isDirty, isFalse);

      count.value = 2; // Change dependency
      // Note: dirty state is set synchronously for sync effects
    });

    test('invalidate should force recomputation', () {
      var computeCount = 0;
      final count = ref(1);
      final double = computed(() {
        computeCount++;
        return count.value * 2;
      });

      double.value;
      expect(computeCount, equals(1));

      double.invalidate();
      double.value;
      expect(computeCount, equals(2));
    });

    test('toString should show state', () {
      final count = ref(1);
      final double = computed(() => count.value * 2);

      expect(double.toString(), contains('dirty'));

      double.value; // Access
      expect(double.toString(), contains('2'));
    });
  });

  group('WritableComputed', () {
    test('should allow setting value', () async {
      final count = ref(1);
      final plusOne = writableComputed(
        get: () => count.value + 1,
        set: (val) => count.value = val - 1,
      );

      expect(plusOne.value, equals(2));

      plusOne.value = 10;
      await flushEffects();

      expect(count.value, equals(9));
      expect(plusOne.value, equals(10));
    });

    test('should trigger effects on set', () async {
      final count = ref(1);
      final plusOne = writableComputed(
        get: () => count.value + 1,
        set: (val) => count.value = val - 1,
      );

      var effectValue = 0;
      watchEffect((_) {
        effectValue = plusOne.value;
      });

      expect(effectValue, equals(2));

      plusOne.value = 5;
      await flushEffects();

      expect(effectValue, equals(5));
    });
  });
}
