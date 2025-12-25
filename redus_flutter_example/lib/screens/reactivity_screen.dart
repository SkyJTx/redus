import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redus_flutter/redus_flutter.dart';

/// Reactivity showcase demonstrating ref, computed, and watch
class ReactivityScreen extends StatelessWidget {
  const ReactivityScreen({super.key});

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
              colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
            ).createShader(bounds),
            child: const Text(
              '⚡ Reactivity System',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fine-grained reactivity inspired by Vue\'s Composition API',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Demo Cards - Responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    _RefDemo(),
                    const SizedBox(height: 24),
                    _ComputedDemo(),
                    const SizedBox(height: 24),
                    _WatchDemo(),
                  ],
                );
              }
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [_RefDemo(), _ComputedDemo(), _WatchDemo()],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================
// ref() Demo
// ============================================
class _RefDemo extends ReactiveWidget {
  const _RefDemo();

  @override
  ReactiveState<_RefDemo> createState() => _RefDemoState();
}

class _RefDemoState extends ReactiveState<_RefDemo> {
  late final count = ref(0);

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return _DemoCard(
      title: 'ref()',
      subtitle: 'Mutable reactive reference',
      color: const Color(0xFF6C63FF),
      code: '''final count = ref(0);

// Read value
print(count.value); // 0

// Write value (triggers reactivity)
count.value++;''',
      child: Column(
        children: [
          Observe<int>(
            source: count.call,
            builder: (context, value) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.toDouble()),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, child) {
                  return Text(
                    animValue.round().toString(),
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.remove,
                onTap: () => count.value--,
                color: const Color(0xFF6C63FF),
              ),
              const SizedBox(width: 16),
              _ActionButton(
                icon: Icons.add,
                onTap: () => count.value++,
                color: const Color(0xFF6C63FF),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// computed() Demo
// ============================================
class _ComputedDemo extends ReactiveWidget {
  const _ComputedDemo();

  @override
  ReactiveState<_ComputedDemo> createState() => _ComputedDemoState();
}

class _ComputedDemoState extends ReactiveState<_ComputedDemo> {
  late final firstName = ref('John');
  late final lastName = ref('Doe');
  late final fullName = computed(() => '${firstName.value} ${lastName.value}');

  @override
  void setup() {}

  @override
  Widget render(BuildContext context) {
    return _DemoCard(
      title: 'computed()',
      subtitle: 'Derived reactive value',
      color: const Color(0xFF8B5CF6),
      code: '''final firstName = ref('John');
final lastName = ref('Doe');

final fullName = computed(
  () => '\${firstName.value} \${lastName.value}'
);

print(fullName.value); // John Doe''',
      child: Column(
        children: [
          ObserveEffect(
            builder: (context) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B5CF6)),
              ),
              child: Text(
                fullName.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ComputedInputs(firstName: firstName, lastName: lastName),
        ],
      ),
    );
  }
}

class _ComputedInputs extends StatefulWidget {
  final Ref<String> firstName;
  final Ref<String> lastName;

  const _ComputedInputs({required this.firstName, required this.lastName});

  @override
  State<_ComputedInputs> createState() => _ComputedInputsState();
}

class _ComputedInputsState extends State<_ComputedInputs> {
  late final TextEditingController _firstController;
  late final TextEditingController _lastController;

  @override
  void initState() {
    super.initState();
    _firstController = TextEditingController(text: widget.firstName.value);
    _lastController = TextEditingController(text: widget.lastName.value);
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _firstController,
            onChanged: (v) => widget.firstName.value = v,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'First Name',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: const Color(0xFF0A0E21),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _lastController,
            onChanged: (v) => widget.lastName.value = v,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Last Name',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              filled: true,
              fillColor: const Color(0xFF0A0E21),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// watch() Demo - Using REAL watch() from redus
// ============================================
class _WatchDemo extends ReactiveWidget {
  const _WatchDemo();

  @override
  ReactiveState<_WatchDemo> createState() => _WatchDemoState();
}

class _WatchDemoState extends ReactiveState<_WatchDemo> {
  late final searchQuery = ref('');
  late final logs = ref<List<String>>([]);

  @override
  void setup() {
    // This is the REAL watch() from redus!
    watch(() => searchQuery.value, (newValue, oldValue, onCleanup) {
      if (newValue.isNotEmpty) {
        final timestamp = DateTime.now()
            .toString()
            .split('.')
            .first
            .split(' ')
            .last;
        logs.value = [
          '[$timestamp] Query: "$oldValue" → "$newValue"',
          ...logs.value,
        ].take(5).toList();
      }

      // Demonstrate cleanup callback
      onCleanup(() {
        // This would run before the next watch callback
        // e.g., cancel pending API requests
      });
    });
  }

  @override
  Widget render(BuildContext context) {
    return _DemoCard(
      title: 'watch()',
      subtitle: 'Side effects on value change',
      color: const Color(0xFFA855F7),
      code: '''watch(
  () => searchQuery.value,
  (newValue, oldValue, onCleanup) {
    print('Query: \$oldValue → \$newValue');
    
    // Optional cleanup
    onCleanup(() => cancelRequest();
  },
);''',
      child: Column(
        children: [
          _WatchInput(searchQuery: searchQuery),
          const SizedBox(height: 16),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Observe<List<String>>(
              source: logs.call,
              builder: (_, logList) {
                if (logList.isEmpty) {
                  return Center(
                    child: Text(
                      'Logs will appear here...',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: logList.length,
                  itemBuilder: (context, index) {
                    return Text(
                      logList[index],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Separate StatefulWidget for the text input to manage controller
class _WatchInput extends StatefulWidget {
  final Ref<String> searchQuery;

  const _WatchInput({required this.searchQuery});

  @override
  State<_WatchInput> createState() => _WatchInputState();
}

class _WatchInputState extends State<_WatchInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (v) => widget.searchQuery.value = v,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Type to trigger watch...',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: const Color(0xFF0A0E21),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

// ============================================
// Shared Widgets
// ============================================
class _DemoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String code;
  final Widget child;

  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.code,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth < 400
            ? constraints.maxWidth
            : 360.0;
        return Container(
          width: cardWidth,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.code, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              child,
              const SizedBox(height: 24),
              _CodeSnippet(code: code, color: color),
            ],
          ),
        );
      },
    );
  }
}

class _CodeSnippet extends StatelessWidget {
  final String code;
  final Color color;

  const _CodeSnippet({required this.code, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E21),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Code',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard!'),
                      backgroundColor: color,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.color
              : widget.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color),
        ),
        child: Icon(
          widget.icon,
          color: _isPressed ? Colors.white : widget.color,
        ),
      ),
    );
  }
}
