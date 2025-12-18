import 'dart:async';

import 'package:redus/src/reactivity/core/effect.dart';

/// Flush all pending effects synchronously for testing.
Future<void> flushEffects() async {
  // Allow microtasks to complete
  await Future<void>.delayed(Duration.zero);
  // Force flush any remaining effects
  Scheduler.flushSync();
}
