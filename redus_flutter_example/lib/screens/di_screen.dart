import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dependency Injection showcase
class DIScreen extends StatelessWidget {
  const DIScreen({super.key});

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
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ).createShader(bounds),
            child: const Text(
              '💉 Dependency Injection',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simple service locator pattern for managing dependencies',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Demos
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _RegisterGetDemo(),
              _FactoryDemo(),
              _KeyedInstancesDemo(),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// Basic register/get Demo
// ============================================
class _RegisterGetDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DICard(
      title: 'register() / get()',
      subtitle: 'Register and retrieve singletons',
      color: const Color(0xFF10B981),
      code: '''// In main.dart
register<ApiService>(ApiService());

// Anywhere in the app
final api = get<ApiService>();
await api.fetchData();''',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual representation
          _ServiceBox(
            name: 'ApiService',
            icon: Icons.cloud,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.arrow_downward, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 8),
              Text(
                'get<ApiService>()',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.widgets, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Widget receives same instance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Factory Demo
// ============================================
class _FactoryDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DICard(
      title: 'registerFactory()',
      subtitle: 'Create new instance on each get()',
      color: const Color(0xFF0EA5E9),
      code: '''// Register factory
registerFactory<Logger>(() => Logger());

// Each call creates new instance
final log1 = get<Logger>(); // new Logger()
final log2 = get<Logger>(); // new Logger()
print(log1 == log2); // false''',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ServiceBox(
            name: 'Factory<Logger>',
            icon: Icons.factory,
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InstanceBox(id: '#1', color: const Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              _InstanceBox(id: '#2', color: const Color(0xFF0EA5E9)),
              const SizedBox(width: 8),
              _InstanceBox(id: '#3', color: const Color(0xFF0EA5E9)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Each get() call → new instance',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// Keyed Instances Demo
// ============================================
class _KeyedInstancesDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DICard(
      title: 'Keyed Instances',
      subtitle: 'Multiple instances of same type',
      color: const Color(0xFFF59E0B),
      code: '''// Register with keys
register<Database>(
  SqliteDb(), 
  key: #local,
);
register<Database>(
  FirestoreDb(), 
  key: #cloud,
);

// Retrieve by key
final local = get<Database>(key: #local);
final cloud = get<Database>(key: #cloud);''',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _KeyedServiceBox(
                  type: 'Database',
                  keyName: '#local',
                  impl: 'SqliteDb',
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KeyedServiceBox(
                  type: 'Database',
                  keyName: '#cloud',
                  impl: 'FirestoreDb',
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// Shared Widgets
// ============================================
class _DICard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String code;
  final Widget child;

  const _DICard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.code,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.extension, color: color, size: 20),
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
                        color: Colors.white.withOpacity(0.5),
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
  }
}

class _ServiceBox extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _ServiceBox({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstanceBox extends StatelessWidget {
  final String id;
  final Color color;

  const _InstanceBox({required this.id, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'instance $id',
        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: color),
      ),
    );
  }
}

class _KeyedServiceBox extends StatelessWidget {
  final String type;
  final String keyName;
  final String impl;
  final Color color;

  const _KeyedServiceBox({
    required this.type,
    required this.keyName,
    required this.impl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keyName,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          Text(
            impl,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
                  color: Colors.white.withOpacity(0.5),
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
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
