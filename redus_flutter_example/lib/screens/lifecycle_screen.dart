import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:redus_flutter/redus_flutter.dart';

/// Lifecycle hooks showcase demonstrating component lifecycle
class LifecycleScreen extends StatelessWidget {
  const LifecycleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
            ).createShader(bounds),
            child: const Text(
              '🔄 Lifecycle Hooks',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vue-inspired lifecycle hooks for Flutter components',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 32),

          // Lifecycle Timeline
          const _LifecycleTimeline(),
          const SizedBox(height: 32),

          // Interactive Demo
          const _LifecycleDemo(),
        ],
      ),
    );
  }
}

class _LifecycleTimeline extends StatelessWidget {
  const _LifecycleTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lifecycle Order',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              // Use vertical layout on smaller screens
              if (constraints.maxWidth < 700) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HookBadge('setup()', const Color(0xFF6C63FF), 'Define hooks'),
                    _ArrowIconVertical(),
                    _HookBadge('onBeforeMount', const Color(0xFF00D9FF), 'Before first build'),
                    _ArrowIconVertical(),
                    _HookBadge('onMounted', const Color(0xFF10B981), 'After first build'),
                    _ArrowIconVertical(),
                    _HookBadge('onBeforeUpdate', const Color(0xFFF59E0B), 'Before rebuild'),
                    _ArrowIconVertical(),
                    _HookBadge('onUpdated', const Color(0xFFEF4444), 'After rebuild'),
                    _ArrowIconVertical(),
                    _HookBadge('onBeforeUnmount', const Color(0xFF8B5CF6), 'Starting dispose'),
                    _ArrowIconVertical(),
                    _HookBadge('onUnmounted', const Color(0xFFEC4899), 'Fully disposed'),
                  ],
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HookBadge('setup()', const Color(0xFF6C63FF), 'Define hooks'),
                  _ArrowIcon(),
                  _HookBadge('onBeforeMount', const Color(0xFF00D9FF), 'Before first build'),
                  _ArrowIcon(),
                  _HookBadge('onMounted', const Color(0xFF10B981), 'After first build'),
                  _ArrowIcon(),
                  _HookBadge('onBeforeUpdate', const Color(0xFFF59E0B), 'Before rebuild'),
                  _ArrowIcon(),
                  _HookBadge('onUpdated', const Color(0xFFEF4444), 'After rebuild'),
                  _ArrowIcon(),
                  _HookBadge('onBeforeUnmount', const Color(0xFF8B5CF6), 'Starting dispose'),
                  _ArrowIcon(),
                  _HookBadge('onUnmounted', const Color(0xFFEC4899), 'Fully disposed'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HookBadge extends StatelessWidget {
  final String name;
  final Color color;
  final String tooltip;

  const _HookBadge(this.name, this.color, this.tooltip);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _ArrowIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.arrow_forward, size: 16, color: Colors.white.withValues(alpha: 0.3));
  }
}

class _ArrowIconVertical extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Icon(Icons.arrow_downward, size: 16, color: Colors.white.withValues(alpha: 0.3)),
    );
  }
}

class _LifecycleDemo extends StatefulWidget {
  const _LifecycleDemo();

  @override
  State<_LifecycleDemo> createState() => _LifecycleDemoState();
}

class _LifecycleDemoState extends State<_LifecycleDemo> {
  bool _isComponentVisible = false; // Start unmounted
  final List<_LogEntry> _logs = [];

  void _addLog(String hook, Color color) {
    // Defer setState to avoid calling during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _logs.insert(0, _LogEntry(hook: hook, time: DateTime.now(), color: color));
          if (_logs.length > 10) _logs.removeLast();
        });
      }
    });
  }

  void _toggleComponent() {
    setState(() {
      _isComponentVisible = !_isComponentVisible;
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row - responsive
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Interactive Demo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _clearLogs,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _toggleComponent,
                    icon: Icon(_isComponentVisible ? Icons.visibility_off : Icons.visibility),
                    label: Text(_isComponentVisible ? 'Unmount' : 'Mount'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content area - responsive
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Stack vertically on small screens
                return Column(
                  children: [
                    _ComponentArea(isVisible: _isComponentVisible, onLog: _addLog),
                    const SizedBox(height: 16),
                    _LogPanel(logs: _logs, formatTime: _formatTime),
                  ],
                );
              }
              // Side by side on larger screens
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _ComponentArea(isVisible: _isComponentVisible, onLog: _addLog),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _LogPanel(logs: _logs, formatTime: _formatTime),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

class _ComponentArea extends StatelessWidget {
  final bool isVisible;
  final void Function(String, Color) onLog;

  const _ComponentArea({required this.isVisible, required this.onLog});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVisible
              ? const Color(0xFF00D9FF).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isVisible
            ? _LifecycleComponent(key: const ValueKey('component'), onLog: onLog)
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_off,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Component Unmounted',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Mount" to see lifecycle hooks',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LogPanel extends StatelessWidget {
  final List<_LogEntry> logs;
  final String Function(DateTime) formatTime;

  const _LogPanel({required this.logs, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Log',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Text(
                      'Mount component to see events...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: log.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                log.hook,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: log.color,
                                ),
                              ),
                            ),
                            Text(
                              formatTime(log.time),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String hook;
  final DateTime time;
  final Color color;

  _LogEntry({required this.hook, required this.time, required this.color});
}

class _LifecycleComponent extends ReactiveWidget {
  final void Function(String, Color) onLog;

  _LifecycleComponent({super.key, required this.onLog});

  late final counter = bind(() => ref(0));

  @override
  void setup() {
    onBeforeMount(() {
      onLog('onBeforeMount', const Color(0xFF00D9FF));
    });

    onMounted(() {
      onLog('onMounted', const Color(0xFF10B981));
    });

    onBeforeUpdate(() {
      onLog('onBeforeUpdate', const Color(0xFFF59E0B));
    });

    onUpdated(() {
      onLog('onUpdated', const Color(0xFFEF4444));
    });

    onBeforeUnmount(() {
      onLog('onBeforeUnmount', const Color(0xFF8B5CF6));
    });

    onUnmounted(() {
      onLog('onUnmounted', const Color(0xFFEC4899));
    });
  }

  @override
  Widget render(BuildContext context) {
    // Access counter.value directly here so ReactiveWidget tracks it
    // and rebuilds when it changes, triggering onBeforeUpdate/onUpdated
    final currentCount = counter.value;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '✅ Component Active',
            style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            'Counter: $currentCount',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => counter.value++,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Increment (triggers update)'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF00D9FF)),
          ),
        ],
      ),
    );
  }
}
