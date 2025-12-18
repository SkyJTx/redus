import 'package:redus/reactivity.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('ShallowRef', () {
    test('should create shallow ref', () {
      final state = shallowRef({'count': 1});
      expect(state.value['count'], equals(1));
    });

    test('should trigger on value replacement', () async {
      final state = shallowRef({'count': 1});
      var effectRunCount = 0;

      watchEffect((_) {
        state.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      state.value = {'count': 2};
      await flushEffects();

      expect(effectRunCount, equals(2));
    });

    test('should NOT trigger on nested mutation', () async {
      final state = shallowRef({'count': 1});
      var effectRunCount = 0;

      watchEffect((_) {
        state.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      state.value['count'] = 2; // Nested mutation
      await flushEffects();

      expect(effectRunCount, equals(1)); // Should NOT trigger
    });

    test('raw should provide access without tracking', () {
      final state = shallowRef(42);
      expect(state.raw, equals(42));
    });
  });

  group('triggerRef', () {
    test('should force trigger shallow ref', () async {
      final state = shallowRef({'count': 1});
      var effectRunCount = 0;

      watchEffect((_) {
        state.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      state.value['count'] = 2; // Nested mutation (no trigger)
      expect(effectRunCount, equals(1));

      triggerRef(state); // Force trigger
      await flushEffects();

      expect(effectRunCount, equals(2));
    });
  });

  group('ShallowReadonly', () {
    test('should create shallow readonly from ref', () {
      final original = ref({'foo': 1});
      final copy = shallowReadonly<Map<String, int>>(original);

      expect(copy.value['foo'], equals(1));
    });

    test('should create shallow readonly from shallowRef', () {
      final original = shallowRef({'foo': 1});
      final copy = shallowReadonly<Map<String, int>>(original);

      expect(copy.value['foo'], equals(1));
    });
  });

  group('CustomRef', () {
    test('should create custom ref with track/trigger', () async {
      var value = 0;
      final custom = customRef<int>((track, trigger) => (
            get: () {
              track();
              return value;
            },
            set: (newValue) {
              value = newValue;
              trigger();
            },
          ));

      expect(custom.value, equals(0));

      custom.value = 5;
      expect(custom.value, equals(5));
    });

    test('should track dependencies', () async {
      var value = 0;
      final custom = customRef<int>((track, trigger) => (
            get: () {
              track();
              return value;
            },
            set: (newValue) {
              value = newValue;
              trigger();
            },
          ));

      var effectValue = 0;
      watchSyncEffect((_) {
        effectValue = custom.value;
      });

      expect(effectValue, equals(0));

      custom.value = 42;
      expect(effectValue, equals(42));
    });
  });

  group('toRaw', () {
    test('should return raw value from ref', () {
      final r = ref(42);
      expect(toRaw<int>(r), equals(42));
    });

    test('should return raw value from shallowRef', () {
      final r = shallowRef(42);
      expect(toRaw<int>(r), equals(42));
    });

    test('should return value as-is for non-reactive', () {
      expect(toRaw<int>(100), equals(100));
    });
  });

  group('markRaw', () {
    test('should mark object as raw', () {
      final obj = {'a': 1};
      expect(isMarkedRaw(obj), isFalse);

      markRaw(obj);
      expect(isMarkedRaw(obj), isTrue);
    });

    test('should return the same object', () {
      final obj = {'a': 1};
      expect(identical(markRaw(obj), obj), isTrue);
    });
  });

  group('EffectScope', () {
    test('should create effect scope', () {
      final scope = effectScope();
      expect(scope.isActive, isTrue);
    });

    test('run should execute function', () {
      final scope = effectScope();
      var executed = false;

      scope.run(() {
        executed = true;
      });

      expect(executed, isTrue);
    });

    test('run should return function result', () {
      final scope = effectScope();

      final result = scope.run(() => 42);

      expect(result, equals(42));
    });

    test('stop should deactivate scope', () {
      final scope = effectScope();
      scope.stop();

      expect(scope.isActive, isFalse);
    });

    test('run should return null when stopped', () {
      final scope = effectScope();
      scope.stop();

      final result = scope.run(() => 42);

      expect(result, isNull);
    });

    test('onScopeDispose should register callback', () {
      final scope = effectScope();
      var disposed = false;

      scope.run(() {
        onScopeDispose(() {
          disposed = true;
        });
      });

      expect(disposed, isFalse);

      scope.stop();

      expect(disposed, isTrue);
    });

    test('getCurrentScope should return active scope', () {
      final scope = effectScope();

      EffectScope? capturedScope;
      scope.run(() {
        capturedScope = getCurrentScope();
      });

      expect(capturedScope, same(scope));
    });

    test('getCurrentScope should return null outside scope', () {
      expect(getCurrentScope(), isNull);
    });

    test('onScopeDispose should throw outside scope', () {
      expect(
        () => onScopeDispose(() {}),
        throwsA(isA<StateError>()),
      );
    });

    test('onScopeDispose with failSilently should not throw', () {
      expect(
        () => onScopeDispose(() {}, failSilently: true),
        returnsNormally,
      );
    });

    test('nested scopes should work', () {
      final parent = effectScope();
      late EffectScope child;

      parent.run(() {
        child = effectScope();
        expect(getCurrentScope(), same(parent));

        child.run(() {
          expect(getCurrentScope(), same(child));
        });

        expect(getCurrentScope(), same(parent));
      });
    });
  });
}
