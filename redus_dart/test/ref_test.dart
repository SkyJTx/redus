import 'package:redus/reactivity.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Ref', () {
    test('should create ref with initial value', () {
      final count = ref(0);
      expect(count.value, equals(0));
    });

    test('should update value', () {
      final count = ref(0);
      count.value = 5;
      expect(count.value, equals(5));
    });

    test('should track dependencies in effects', () async {
      final count = ref(0);
      var effectRunCount = 0;

      watchEffect((_) {
        count.value; // Read to track
        effectRunCount++;
      });

      expect(effectRunCount, equals(1)); // Initial run

      count.value = 1;
      await flushEffects();
      expect(effectRunCount, equals(2)); // Triggered by change
    });

    test('should not trigger effect if value is the same', () async {
      final count = ref(5);
      var effectRunCount = 0;

      watchEffect((_) {
        count.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      count.value = 5; // Same value
      await flushEffects();
      expect(effectRunCount, equals(1)); // Should not re-run
    });

    test('should trigger effect for object identity change', () async {
      final list = ref(<int>[1, 2, 3]);
      var effectRunCount = 0;

      watchEffect((_) {
        list.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      list.value = [1, 2, 3]; // Different object, same content
      await flushEffects();
      expect(effectRunCount, equals(2)); // Should trigger
    });

    test('should allow raw access without tracking', () {
      final count = ref(42);
      expect(count.raw, equals(42));
    });

    test('should update value with update function', () {
      final count = ref(10);
      count.update((v) => v * 2);
      expect(count.value, equals(20));
    });

    test('should force trigger with trigger()', () async {
      final count = ref(5);
      var effectRunCount = 0;

      watchEffect((_) {
        count.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      count.trigger(); // Force trigger without value change
      await flushEffects();
      expect(effectRunCount, equals(2));
    });

    test('isRef function should work', () {
      final r = ref(1);
      expect(isRef(r), isTrue);
      expect(isRef(1), isFalse);
      expect(isRef('hello'), isFalse);
    });

    test('unref should unwrap ref values', () {
      final r = ref(42);
      expect(unref<int>(r), equals(42));
      expect(unref<int>(100), equals(100));
    });

    test('toString should show value', () {
      final count = ref(123);
      expect(count.toString(), equals('Ref(123)'));
    });
  });
}
