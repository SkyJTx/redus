import 'package:redus/di.dart';
import 'package:test/test.dart';

void main() {
  group('ServiceLocator', () {
    setUp(() {
      resetLocator();
    });

    group('type-based lookup', () {
      test('register should store singleton instance', () {
        register<String>('test-value');
        expect(get<String>(), equals('test-value'));
      });

      test('register should return same instance', () {
        final list = <int>[1, 2, 3];
        register<List<int>>(list);
        expect(identical(get<List<int>>(), list), isTrue);
      });

      test('registerFactory should create new instance each time', () {
        var counter = 0;
        registerFactory<int>(() => ++counter);

        expect(get<int>(), equals(1));
        expect(get<int>(), equals(2));
        expect(get<int>(), equals(3));
      });

      test('get should throw if not registered', () {
        expect(
          () => get<String>(),
          throwsA(isA<StateError>()),
        );
      });

      test('isRegistered should return true for registered types', () {
        register<String>('test');
        expect(isRegistered<String>(), isTrue);
        expect(isRegistered<int>(), isFalse);
      });

      test('unregister should remove registration', () {
        register<String>('test');
        unregister<String>();
        expect(isRegistered<String>(), isFalse);
      });
    });

    group('key-based lookup', () {
      test('register with key should store separate instances', () {
        register<String>('primary', key: #primary);
        register<String>('backup', key: #backup);

        expect(get<String>(key: #primary), equals('primary'));
        expect(get<String>(key: #backup), equals('backup'));
      });

      test('type-only and key-based are separate', () {
        register<String>('no-key');
        register<String>('with-key', key: #myKey);

        expect(get<String>(), equals('no-key'));
        expect(get<String>(key: #myKey), equals('with-key'));
      });

      test('registerFactory with key creates separate factories', () {
        var primaryCount = 0;
        var backupCount = 100;

        registerFactory<int>(() => ++primaryCount, key: #primary);
        registerFactory<int>(() => ++backupCount, key: #backup);

        expect(get<int>(key: #primary), equals(1));
        expect(get<int>(key: #backup), equals(101));
        expect(get<int>(key: #primary), equals(2));
      });

      test('isRegistered works with keys', () {
        register<String>('test', key: #myKey);
        
        expect(isRegistered<String>(key: #myKey), isTrue);
        expect(isRegistered<String>(), isFalse);
        expect(isRegistered<String>(key: #otherKey), isFalse);
      });

      test('unregister with key only removes that key', () {
        register<String>('a', key: #keyA);
        register<String>('b', key: #keyB);

        unregister<String>(key: #keyA);

        expect(isRegistered<String>(key: #keyA), isFalse);
        expect(isRegistered<String>(key: #keyB), isTrue);
      });

      test('get with key throws if key not registered', () {
        register<String>('test'); // No key

        expect(
          () => get<String>(key: #missingKey),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}
