import 'package:redus/reactivity.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('watchEffect', () {
    test('should run immediately', () {
      var ran = false;

      watchEffect((_) {
        ran = true;
      });

      expect(ran, isTrue);
    });

    test('should re-run when dependency changes', () async {
      final count = ref(0);
      var effectRunCount = 0;

      watchEffect((_) {
        count.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      count.value = 1;
      await flushEffects();

      expect(effectRunCount, equals(2));
    });

    test('should stop with handle.stop()', () async {
      final count = ref(0);
      var effectRunCount = 0;

      final handle = watchEffect((_) {
        count.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      handle.stop();

      count.value = 1;
      await flushEffects();

      expect(effectRunCount, equals(1)); // Should not re-run
    });

    test('should pause and resume', () async {
      final count = ref(0);
      var effectRunCount = 0;

      final handle = watchEffect((_) {
        count.value;
        effectRunCount++;
      });

      expect(effectRunCount, equals(1));

      handle.pause();
      count.value = 1;
      await flushEffects();

      expect(effectRunCount, equals(1)); // Paused, no re-run

      handle.resume();
      await flushEffects();

      expect(effectRunCount, equals(2)); // Resumed, should run
    });

    test('should call onCleanup before re-run', () async {
      final count = ref(0);
      var cleanupCalled = false;

      watchEffect((onCleanup) {
        count.value;
        onCleanup(() {
          cleanupCalled = true;
        });
      });

      expect(cleanupCalled, isFalse);

      count.value = 1;
      await flushEffects();

      expect(cleanupCalled, isTrue);
    });

    test('should call onCleanup on stop', () async {
      var cleanupCalled = false;

      final handle = watchEffect((onCleanup) {
        onCleanup(() {
          cleanupCalled = true;
        });
      });

      expect(cleanupCalled, isFalse);

      handle.stop();

      expect(cleanupCalled, isTrue);
    });

    test('callable handle should stop', () async {
      final count = ref(0);
      var effectRunCount = 0;

      final handle = watchEffect((_) {
        count.value;
        effectRunCount++;
      });

      handle(); // Call like a function to stop

      count.value = 1;
      await flushEffects();

      expect(effectRunCount, equals(1)); // Should not re-run
    });
  });

  group('watchPostEffect', () {
    test('should use post flush timing', () async {
      final count = ref(0);
      var effectValue = 0;

      watchPostEffect((_) {
        effectValue = count.value;
      });

      expect(effectValue, equals(0)); // Ran immediately

      count.value = 5;
      // Post effects run after pre effects
      await flushEffects();

      expect(effectValue, equals(5));
    });
  });

  group('watchSyncEffect', () {
    test('should run synchronously on change', () {
      final count = ref(0);
      var effectValue = 0;

      watchSyncEffect((_) {
        effectValue = count.value;
      });

      expect(effectValue, equals(0));

      count.value = 5;
      // Sync effects run immediately, no flush needed
      expect(effectValue, equals(5));
    });
  });

  group('watch', () {
    test('should watch ref changes', () async {
      final count = ref(0);
      int? newVal;
      int? oldVal;

      watch<int>(count, (value, oldValue, _) {
        newVal = value;
        oldVal = oldValue;
      });

      count.value = 5;
      await flushEffects();

      expect(newVal, equals(5));
      expect(oldVal, equals(0));
    });

    test('should not run immediately by default', () async {
      final count = ref(0);
      var callbackRan = false;

      watch<int>(count, (_, __, ___) {
        callbackRan = true;
      });

      await flushEffects();
      expect(callbackRan, isFalse); // Should not run until change
    });

    test('should run immediately with immediate option', () async {
      final count = ref(0);
      int? newVal;

      watch<int>(
        count,
        (value, _, __) {
          newVal = value;
        },
        options: const WatchOptions(immediate: true),
      );

      expect(newVal, equals(0)); // Should run immediately
    });

    test('should watch computed changes', () async {
      final count = ref(1);
      final double = computed(() => count.value * 2);
      int? newVal;
      int? oldVal;

      watch<int>(double, (value, oldValue, _) {
        newVal = value;
        oldVal = oldValue;
      });

      count.value = 5;
      await flushEffects();

      expect(newVal, equals(10));
      expect(oldVal, equals(2));
    });

    test('should watch getter function', () async {
      final count = ref(1);
      int? newVal;
      int? oldVal;

      watch<int>(() => count.value * 3, (value, oldValue, _) {
        newVal = value;
        oldVal = oldValue;
      });

      count.value = 5;
      await flushEffects();

      expect(newVal, equals(15));
      expect(oldVal, equals(3));
    });

    test('should stop with once option', () async {
      final count = ref(0);
      var callbackCount = 0;

      watch<int>(
        count,
        (_, __, ___) {
          callbackCount++;
        },
        options: const WatchOptions(once: true),
      );

      count.value = 1;
      await flushEffects();
      expect(callbackCount, equals(1));

      count.value = 2;
      await flushEffects();
      expect(callbackCount, equals(1)); // Should not run again
    });

    test('should call cleanup on re-run', () async {
      final count = ref(0);
      var cleanupCalled = false;

      watch<int>(count, (_, __, onCleanup) {
        onCleanup(() {
          cleanupCalled = true;
        });
      });

      count.value = 1;
      await flushEffects();
      expect(cleanupCalled, isFalse);

      count.value = 2;
      await flushEffects();
      expect(cleanupCalled, isTrue);
    });
  });

  group('watchMultiple', () {
    test('should watch multiple sources', () async {
      final first = ref(1);
      final second = ref(2);
      List<int>? newVals;
      List<int?>? oldVals;

      watchMultiple<int>([first, second], (values, oldValues, _) {
        newVals = values;
        oldVals = oldValues;
      });

      first.value = 10;
      await flushEffects();

      expect(newVals, equals([10, 2]));
      expect(oldVals, equals([1, 2]));
    });

    test('should trigger on any source change', () async {
      final first = ref(1);
      final second = ref(2);
      var callbackCount = 0;

      watchMultiple<int>([first, second], (_, __, ___) {
        callbackCount++;
      });

      first.value = 10;
      await flushEffects();
      expect(callbackCount, equals(1));

      second.value = 20;
      await flushEffects();
      expect(callbackCount, equals(2));
    });
  });

  group('onWatcherCleanup', () {
    test('should register cleanup in watchEffect', () async {
      final count = ref(0);
      var cleanupCalled = false;

      watchEffect((_) {
        count.value;
        onWatcherCleanup(() {
          cleanupCalled = true;
        });
      });

      count.value = 1;
      await flushEffects();

      expect(cleanupCalled, isTrue);
    });

    test('should throw when called outside effect', () {
      expect(
        () => onWatcherCleanup(() {}),
        throwsA(isA<StateError>()),
      );
    });

    test('should not throw with failSilently', () {
      expect(
        () => onWatcherCleanup(() {}, failSilently: true),
        returnsNormally,
      );
    });
  });
}
