import 'package:redus/reactivity.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Readonly', () {
    test('should create readonly from ref', () {
      final original = ref(42);
      final copy = readonly<int>(original);

      expect(copy.value, equals(42));
    });

    test('should create readonly from computed', () {
      final count = ref(1);
      final double = computed(() => count.value * 2);
      final copy = readonly<int>(double);

      expect(copy.value, equals(2));
    });

    test('should track dependencies', () async {
      final original = ref(0);
      final copy = readonly<int>(original);
      var effectValue = 0;

      watchEffect((_) {
        effectValue = copy.value;
      });

      expect(effectValue, equals(0));

      original.value = 5;
      await flushEffects();

      expect(effectValue, equals(5));
    });

    test('should update when original changes', () async {
      final original = ref(10);
      final copy = readonly<int>(original);

      expect(copy.value, equals(10));

      original.value = 20;
      await flushEffects();

      expect(copy.value, equals(20));
    });

    test('should provide source access', () {
      final original = ref(42);
      final copy = readonly<int>(original);

      expect(copy.source, same(original));
    });

    test('asReadonly extension on Ref', () {
      final original = ref(42);
      final copy = original.asReadonly();

      expect(copy.value, equals(42));
    });

    test('asReadonly extension on Computed', () {
      final count = ref(1);
      final double = computed(() => count.value * 2);
      final copy = double.asReadonly();

      expect(copy.value, equals(2));
    });

    test('should throw for invalid source', () {
      expect(
        () => readonly<int>('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toString should show value', () {
      final original = ref(123);
      final copy = readonly<int>(original);

      expect(copy.toString(), equals('Readonly(123)'));
    });
  });
}
