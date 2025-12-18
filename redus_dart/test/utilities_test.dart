import 'package:redus/reactivity.dart';
import 'package:test/test.dart';

void main() {
  group('Utilities', () {
    group('isRef', () {
      test('should return true for Ref', () {
        expect(isRef(ref(1)), isTrue);
      });

      test('should return false for non-Ref', () {
        expect(isRef(1), isFalse);
        expect(isRef('hello'), isFalse);
        expect(isRef(null), isFalse);
      });
    });

    group('unref', () {
      test('should unwrap ref', () {
        final r = ref(42);
        expect(unref<int>(r), equals(42));
      });

      test('should return value as-is if not ref', () {
        expect(unref<int>(100), equals(100));
      });
    });

    group('toValue', () {
      test('should return value from ref', () {
        expect(toValue<int>(ref(1)), equals(1));
      });

      test('should call getter function', () {
        expect(toValue<int>(() => 42), equals(42));
      });

      test('should return value as-is', () {
        expect(toValue<int>(5), equals(5));
      });
    });

    group('toRef', () {
      test('should return existing ref as-is', () {
        final r = ref(1);
        expect(identical(toRef<int>(r), r), isTrue);
      });

      test('should create ref from value', () {
        final r = toRef<int>(42);
        expect(r.value, equals(42));
      });

      test('should create getter-based ref from function', () {
        var x = 1;
        final r = toRef<int>(() => x * 2);
        expect(r.value, equals(2));

        x = 5;
        expect(r.value, equals(10)); // Re-evaluates getter
      });
    });

    group('toRefs', () {
      test('should convert map to refs', () {
        final state = {'foo': 1, 'bar': 2};
        final refs = toRefs<int>(state);

        expect(refs['foo']!.value, equals(1));
        expect(refs['bar']!.value, equals(2));
      });
    });

    group('isProxy', () {
      test('should return true for Ref', () {
        expect(isProxy(ref(1)), isTrue);
      });

      test('should return true for Computed', () {
        expect(isProxy(computed(() => 1)), isTrue);
      });

      test('should return true for ShallowRef', () {
        expect(isProxy(shallowRef(1)), isTrue);
      });

      test('should return false for plain values', () {
        expect(isProxy(1), isFalse);
        expect(isProxy('hello'), isFalse);
      });
    });

    group('isReactive', () {
      test('should return true for Ref', () {
        expect(isReactive(ref(1)), isTrue);
      });

      test('should return true for Computed', () {
        expect(isReactive(computed(() => 1)), isTrue);
      });

      test('should return true for ShallowRef', () {
        expect(isReactive(shallowRef(1)), isTrue);
      });

      test('should return false for Readonly', () {
        expect(isReactive(readonly<int>(ref(1))), isFalse);
      });
    });

    group('isReadonly', () {
      test('should return true for Readonly', () {
        expect(isReadonly(readonly<int>(ref(1))), isTrue);
      });

      test('should return true for Computed (readonly)', () {
        expect(isReadonly(computed(() => 1)), isTrue);
      });

      test('should return false for WritableComputed', () {
        final c = writableComputed(get: () => 1, set: (_) {});
        expect(isReadonly(c), isFalse);
      });

      test('should return false for Ref', () {
        expect(isReadonly(ref(1)), isFalse);
      });
    });
  });
}
