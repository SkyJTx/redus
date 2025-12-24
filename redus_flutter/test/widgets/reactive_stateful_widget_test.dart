import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redus_flutter/redus_flutter.dart';

void main() {
  group('ReactiveStatefulWidget', () {
    testWidgets('should call setup once', (tester) async {
      var setupCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _SetupTestWidget(onSetup: () => setupCount++),
      ));

      expect(setupCount, 1);

      // Trigger rebuild
      await tester.pump();
      expect(setupCount, 1); // Still 1 after rebuild
    });

    testWidgets('should call onMounted after first build', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _LifecycleTestWidget(logs: logs),
      ));
      await tester.pump(); // Process post-frame callback

      expect(logs, contains('mounted'));
    });

    testWidgets('should call onDispose on dispose', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _LifecycleTestWidget(logs: logs),
      ));
      await tester.pump();

      logs.clear();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(logs, contains('disposed'));
    });

    testWidgets('bind() should persist state across parent rebuilds',
        (tester) async {
      final parentTrigger = ref(0);
      late _CounterStore capturedStore;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          parentTrigger.watch(context);
          return _BindTestWidget(
            onStoreCreated: (store) => capturedStore = store,
          );
        }),
      ));

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Increment via store
      capturedStore.increment();
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Trigger parent rebuild
      parentTrigger.value++;
      await tester.pump();

      // State should persist!
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('reactive tracking triggers rebuilds', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _ReactiveTestWidget(),
      ));

      expect(find.text('Count: 0'), findsOneWidget);

      // Tap to increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });
  });

  group('ReactiveStatefulWidget with Flutter mixins', () {
    testWidgets('works with SingleTickerProviderStateMixin', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _AnimatedTestWidget(logs: logs),
      ));
      await tester.pump();

      expect(logs, contains('controller_created'));
      expect(logs, contains('mounted'));
    });

    testWidgets('AnimationController vsync works correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _AnimatedCounterWidget(),
      ));
      await tester.pump();

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Animation controller should work
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('works with TickerProviderStateMixin for multiple animations',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _MultiAnimationWidget(),
      ));
      await tester.pump();

      // Should render without errors
      expect(find.byType(_MultiAnimationWidget), findsOneWidget);
    });

    testWidgets('works with AutomaticKeepAliveClientMixin', (tester) async {
      final logs = <String>[];
      var disposeCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _KeepAliveListWidget(
          logs: logs,
          onDispose: () => disposeCount++,
        ),
      ));
      await tester.pump();

      // Initial state - first item should be visible and mounted
      expect(logs, contains('mounted_0'));
      expect(find.text('Keep Alive Item 0'), findsOneWidget);

      // Scroll to the bottom to remove first item from viewport
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // First item should NOT be disposed due to keep alive
      expect(disposeCount, 0);
    });

    testWidgets('AutomaticKeepAliveClientMixin preserves state',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: _KeepAliveCounterListWidget(),
      ));
      await tester.pump();

      // Initial state
      expect(find.text('Count: 0'), findsOneWidget);

      // Increment the counter
      await tester.tap(find.text('Count: 0'));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Scroll away and back
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();

      // State should be preserved
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('works with RestorationMixin', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: MaterialApp(
          restorationScopeId: 'app',
          home: _RestorableCounterWidget(
            restorationId: 'counter',
            logs: logs,
          ),
        ),
      ));
      await tester.pump();

      expect(logs, contains('restoration_registered'));
      expect(find.text('Restorable: 0'), findsOneWidget);
    });

    testWidgets('RestorationMixin preserves and restores state',
        (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(RootRestorationScope(
        restorationId: 'root',
        child: MaterialApp(
          restorationScopeId: 'app',
          home: _RestorableCounterWidget(
            restorationId: 'counter',
            logs: logs,
          ),
        ),
      ));
      await tester.pump();

      // Initial state
      expect(find.text('Restorable: 0'), findsOneWidget);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Restorable: 1'), findsOneWidget);

      // State should be restorable
      expect(logs, contains('restoration_registered'));
    });

    testWidgets('works with WidgetsBindingObserver', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _LifecycleObserverWidget(logs: logs),
      ));
      await tester.pump();

      expect(logs, contains('observer_added'));

      // Remove widget to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(logs, contains('observer_removed'));
    });

    testWidgets('WidgetsBindingObserver receives app lifecycle events',
        (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _LifecycleObserverWidget(logs: logs),
      ));
      await tester.pump();

      // Get the state to verify observer was registered
      final state = tester.state<_LifecycleObserverWidgetState>(
        find.byType(_LifecycleObserverWidget),
      );

      // Simulate app lifecycle change
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(logs, contains('lifecycle_paused'));

      state.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(logs, contains('lifecycle_resumed'));
    });

    testWidgets('combined mixins work together', (tester) async {
      final logs = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: _CombinedMixinWidget(logs: logs),
      ));
      await tester.pump();

      expect(logs, contains('controller_created'));
      expect(logs, contains('observer_added'));
      expect(find.text('Combined: 0'), findsOneWidget);

      // Increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Combined: 1'), findsOneWidget);

      // Dispose
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      expect(logs, contains('observer_removed'));
      expect(logs, contains('controller_disposed'));
    });
  });

  group('Effect scope cleanup', () {
    testWidgets('watchEffect is cleaned up on dispose', (tester) async {
      bool effectStopped = false;

      await tester.pumpWidget(MaterialApp(
        home: _EffectCleanupWidget(onCleanup: () => effectStopped = true),
      ));
      await tester.pump();

      expect(effectStopped, false);

      // Unmount to trigger dispose
      await tester.pumpWidget(Container());
      await tester.pump();

      expect(effectStopped, true);
    });

    testWidgets('watchEffect works within setup', (tester) async {
      final watchLogs = <int>[];

      await tester.pumpWidget(MaterialApp(
        home: _WatchEffectTestWidget(logs: watchLogs),
      ));
      await tester.pump();

      // Initial value tracked
      expect(watchLogs, [0]);

      // Tap to increment
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(watchLogs, [0, 1]);
    });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _CounterStore {
  final count = ref(0);
  void increment() => count.value++;
}

class _SetupTestWidget extends ReactiveStatefulWidget {
  final VoidCallback onSetup;

  const _SetupTestWidget({required this.onSetup});

  @override
  ReactiveWidgetState<_SetupTestWidget> createState() =>
      _SetupTestWidgetState();
}

class _SetupTestWidgetState extends ReactiveWidgetState<_SetupTestWidget> {
  @override
  void setup() {
    widget.onSetup();
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Setup Test');
  }
}

class _LifecycleTestWidget extends ReactiveStatefulWidget {
  final List<String> logs;

  const _LifecycleTestWidget({required this.logs});

  @override
  ReactiveWidgetState<_LifecycleTestWidget> createState() =>
      _LifecycleTestWidgetState();
}

class _LifecycleTestWidgetState
    extends ReactiveWidgetState<_LifecycleTestWidget> {
  @override
  void setup() {
    onMounted(() => widget.logs.add('mounted'));
    onDispose(() => widget.logs.add('disposed'));
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Lifecycle Test');
  }
}

class _BindTestWidget extends ReactiveStatefulWidget {
  final void Function(_CounterStore) onStoreCreated;

  const _BindTestWidget({required this.onStoreCreated});

  @override
  ReactiveWidgetState<_BindTestWidget> createState() => _BindTestWidgetState();
}

class _BindTestWidgetState extends ReactiveWidgetState<_BindTestWidget> {
  late final store = bind(() {
    final s = _CounterStore();
    widget.onStoreCreated(s);
    return s;
  });

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return Text('Count: ${store.count.value}');
  }
}

class _ReactiveTestWidget extends ReactiveStatefulWidget {
  const _ReactiveTestWidget();

  @override
  ReactiveWidgetState<_ReactiveTestWidget> createState() =>
      _ReactiveTestWidgetState();
}

class _ReactiveTestWidgetState
    extends ReactiveWidgetState<_ReactiveTestWidget> {
  late final count = bind(() => ref(0));

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FLUTTER MIXIN TEST WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedTestWidget extends ReactiveStatefulWidget {
  final List<String> logs;

  const _AnimatedTestWidget({required this.logs});

  @override
  ReactiveWidgetState<_AnimatedTestWidget> createState() =>
      _AnimatedTestWidgetState();
}

class _AnimatedTestWidgetState extends ReactiveWidgetState<_AnimatedTestWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void setup() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.logs.add('controller_created');

    onMounted(() => widget.logs.add('mounted'));
    onDispose(() => controller.dispose());
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Animated Widget');
  }
}

class _AnimatedCounterWidget extends ReactiveStatefulWidget {
  const _AnimatedCounterWidget();

  @override
  ReactiveWidgetState<_AnimatedCounterWidget> createState() =>
      _AnimatedCounterWidgetState();
}

class _AnimatedCounterWidgetState
    extends ReactiveWidgetState<_AnimatedCounterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final count = bind(() => ref(0));

  @override
  void setup() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    onDispose(() => controller.dispose());
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

class _MultiAnimationWidget extends ReactiveStatefulWidget {
  const _MultiAnimationWidget();

  @override
  ReactiveWidgetState<_MultiAnimationWidget> createState() =>
      _MultiAnimationWidgetState();
}

class _MultiAnimationWidgetState
    extends ReactiveWidgetState<_MultiAnimationWidget>
    with TickerProviderStateMixin {
  late final AnimationController controller1;
  late final AnimationController controller2;

  @override
  void setup() {
    controller1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    controller2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    onDispose(() {
      controller1.dispose();
      controller2.dispose();
    });
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Multi Animation Widget');
  }
}

class _EffectCleanupWidget extends ReactiveStatefulWidget {
  final VoidCallback onCleanup;

  const _EffectCleanupWidget({required this.onCleanup});

  @override
  ReactiveWidgetState<_EffectCleanupWidget> createState() =>
      _EffectCleanupWidgetState();
}

class _EffectCleanupWidgetState
    extends ReactiveWidgetState<_EffectCleanupWidget> {
  late final trigger = bind(() => ref(0));

  @override
  void setup() {
    watchEffect((onCleanup) {
      trigger.value;
      onCleanup(widget.onCleanup);
    });
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Effect Cleanup Test');
  }
}

class _WatchEffectTestWidget extends ReactiveStatefulWidget {
  final List<int> logs;

  const _WatchEffectTestWidget({required this.logs});

  @override
  ReactiveWidgetState<_WatchEffectTestWidget> createState() =>
      _WatchEffectTestWidgetState();
}

class _WatchEffectTestWidgetState
    extends ReactiveWidgetState<_WatchEffectTestWidget> {
  late final count = bind(() => ref(0));

  @override
  void setup() {
    watchEffect((onCleanup) {
      widget.logs.add(count.value);
    });
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADDITIONAL FLUTTER MIXIN TEST WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

// AutomaticKeepAliveClientMixin Test Widget (Container)
class _KeepAliveListWidget extends StatelessWidget {
  final List<String> logs;
  final VoidCallback onDispose;

  const _KeepAliveListWidget({
    required this.logs,
    required this.onDispose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) => SizedBox(
          height: 100,
          child: _KeepAliveItemWidget(
            index: index,
            logs: logs,
            onDispose: onDispose,
          ),
        ),
      ),
    );
  }
}

class _KeepAliveItemWidget extends ReactiveStatefulWidget {
  final int index;
  final List<String> logs;
  final VoidCallback onDispose;

  const _KeepAliveItemWidget({
    required this.index,
    required this.logs,
    required this.onDispose,
  });

  @override
  ReactiveWidgetState<_KeepAliveItemWidget> createState() =>
      _KeepAliveItemWidgetState();
}

class _KeepAliveItemWidgetState
    extends ReactiveWidgetState<_KeepAliveItemWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void setup() {
    onMounted(() => widget.logs.add('mounted_${widget.index}'));
    onDispose(widget.onDispose);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return reactiveBuild(context);
  }

  @override
  Widget render(BuildContext context) {
    return Text('Keep Alive Item ${widget.index}');
  }
}

// AutomaticKeepAliveClientMixin Counter Test Widget
class _KeepAliveCounterListWidget extends StatelessWidget {
  const _KeepAliveCounterListWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) => SizedBox(
          height: 100,
          child:
              index == 0 ? const _KeepAliveCounterItem() : Text('Item $index'),
        ),
      ),
    );
  }
}

class _KeepAliveCounterItem extends ReactiveStatefulWidget {
  const _KeepAliveCounterItem();

  @override
  ReactiveWidgetState<_KeepAliveCounterItem> createState() =>
      _KeepAliveCounterItemState();
}

class _KeepAliveCounterItemState
    extends ReactiveWidgetState<_KeepAliveCounterItem>
    with AutomaticKeepAliveClientMixin {
  late final count = bind(() => ref(0));

  @override
  bool get wantKeepAlive => true;

  @override
  void setup() {}

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return reactiveBuild(context);
  }

  @override
  Widget render(BuildContext context) {
    return GestureDetector(
      onTap: () => count.value++,
      child: Text('Count: ${count.value}'),
    );
  }
}

// RestorationMixin Test Widget
class _RestorableCounterWidget extends ReactiveStatefulWidget {
  final String restorationId;
  final List<String> logs;

  const _RestorableCounterWidget({
    required this.restorationId,
    required this.logs,
  });

  @override
  ReactiveWidgetState<_RestorableCounterWidget> createState() =>
      _RestorableCounterWidgetState();
}

class _RestorableCounterWidgetState
    extends ReactiveWidgetState<_RestorableCounterWidget>
    with RestorationMixin {
  final RestorableInt _counter = RestorableInt(0);

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_counter, 'counter');
    widget.logs.add('restoration_registered');
  }

  @override
  void setup() {
    onDispose(() => _counter.dispose());
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => setState(() => _counter.value++),
      child: Text('Restorable: ${_counter.value}'),
    );
  }
}

// WidgetsBindingObserver Test Widget
class _LifecycleObserverWidget extends ReactiveStatefulWidget {
  final List<String> logs;

  const _LifecycleObserverWidget({required this.logs});

  @override
  ReactiveWidgetState<_LifecycleObserverWidget> createState() =>
      _LifecycleObserverWidgetState();
}

class _LifecycleObserverWidgetState
    extends ReactiveWidgetState<_LifecycleObserverWidget>
    with WidgetsBindingObserver {
  @override
  void setup() {
    WidgetsBinding.instance.addObserver(this);
    widget.logs.add('observer_added');

    onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      widget.logs.add('observer_removed');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.logs.add('lifecycle_paused');
    } else if (state == AppLifecycleState.resumed) {
      widget.logs.add('lifecycle_resumed');
    }
  }

  @override
  Widget render(BuildContext context) {
    return const Text('Lifecycle Observer Widget');
  }
}

// Combined Mixins Test Widget
class _CombinedMixinWidget extends ReactiveStatefulWidget {
  final List<String> logs;

  const _CombinedMixinWidget({required this.logs});

  @override
  ReactiveWidgetState<_CombinedMixinWidget> createState() =>
      _CombinedMixinWidgetState();
}

class _CombinedMixinWidgetState
    extends ReactiveWidgetState<_CombinedMixinWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController controller;
  late final count = bind(() => ref(0));

  @override
  void setup() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.logs.add('controller_created');

    WidgetsBinding.instance.addObserver(this);
    widget.logs.add('observer_added');

    onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      widget.logs.add('observer_removed');
      controller.dispose();
      widget.logs.add('controller_disposed');
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.logs.add('lifecycle_$state');
  }

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
      onPressed: () => count.value++,
      child: Text('Combined: ${count.value}'),
    );
  }
}
