import 'package:flutter/material.dart';

/// Home landing page introducing the Redus packages
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          const _HeroSection(),
          const SizedBox(height: 48),

          // Feature Cards
          const Text(
            'Core Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Responsive feature cards
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Single column on mobile
                return Column(
                  children: _buildFeatureCards(context, double.infinity),
                );
              } else if (constraints.maxWidth < 900) {
                // 2 columns on tablet
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _buildFeatureCards(
                    context,
                    (constraints.maxWidth - 16) / 2,
                  ),
                );
              }
              // 4 columns on desktop
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _buildFeatureCards(context, 280),
              );
            },
          ),

          const SizedBox(height: 48),

          // Package Info
          const _PackageInfoSection(),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureCards(BuildContext context, double width) {
    return [
      _FeatureCard(
        width: width,
        icon: Icons.bolt,
        title: 'Fine-Grained Reactivity',
        description:
            'Vue-inspired reactive primitives: ref, computed, watch. Only update what changed.',
        gradient: const [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
        onTap: () => _navigateTo(context, 1),
      ),
      if (width == double.infinity) const SizedBox(height: 16),
      _FeatureCard(
        width: width,
        icon: Icons.loop,
        title: 'Lifecycle Hooks',
        description:
            'onInitState, onMounted, onDispose and more. Full control over component lifecycle.',
        gradient: const [Color(0xFF00D9FF), Color(0xFF0EA5E9)],
        onTap: () => _navigateTo(context, 2),
      ),
      if (width == double.infinity) const SizedBox(height: 16),
      _FeatureCard(
        width: width,
        icon: Icons.integration_instructions,
        title: 'Dependency Injection',
        description:
            'Simple service locator pattern. Register once, get anywhere.',
        gradient: const [Color(0xFF10B981), Color(0xFF059669)],
        onTap: () => _navigateTo(context, 3),
      ),
      if (width == double.infinity) const SizedBox(height: 16),
      _FeatureCard(
        width: width,
        icon: Icons.widgets,
        title: 'Reactive Widgets',
        description:
            'Observe, ObserveEffect, ReactiveWidget. Seamless Flutter integration.',
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        onTap: () => _navigateTo(context, 4),
      ),
    ];
  }

  void _navigateTo(BuildContext context, int index) {
    // Find the MainNavigator and update its state
    final state = context.findAncestorStateOfType<State>();
    if (state != null && state.mounted) {
      // Using callback to update navigation
      (state as dynamic).setState(() {
        (state as dynamic)._selectedIndex = index;
      });
    }
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;

        return Container(
          padding: EdgeInsets.all(isNarrow ? 24 : 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withValues(alpha: 0.2),
                const Color(0xFF00D9FF).withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLogo(120),
                    const SizedBox(height: 24),
                    _buildContent(isNarrow),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildContent(isNarrow)),
                    const SizedBox(width: 40),
                    _buildLogo(200),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildContent(bool isNarrow) {
    return Column(
      crossAxisAlignment: isNarrow
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6C63FF)),
              ),
              child: const Text(
                'redus',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00D9FF)),
              ),
              child: const Text(
                'redus_flutter',
                style: TextStyle(
                  color: Color(0xFF00D9FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
          ).createShader(bounds),
          child: Text(
            'Vue-like Reactivity\nfor Flutter',
            textAlign: isNarrow ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              fontSize: isNarrow ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Fine-grained reactivity, lifecycle hooks, and dependency injection.\n'
          'Build reactive Flutter apps with less boilerplate.',
          textAlign: isNarrow ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            fontSize: isNarrow ? 14 : 18,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF00D9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.code, size: size * 0.4, color: Colors.white),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final double width;
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width == double.infinity ? null : widget.width,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1E33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? widget.gradient.first.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.gradient.first.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      color: widget.gradient.first,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: widget.gradient.first,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageInfoSection extends StatelessWidget {
  const _PackageInfoSection();

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
            'Quick Start',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              '''// pubspec.yaml
dependencies:
  redus_flutter: ^0.9.0

// main.dart
import 'package:redus_flutter/redus_flutter.dart';

class Counter extends ReactiveWidget {
  late final count = bind(() => ref(0));

  @override
  Widget render(BuildContext context) {
    return GestureDetector(
      onTap: () => count.value++,
      child: Observe<int>(
        source: count.call,
        builder: (_, value) => Text('Count: \$value'),
      ),
    );
  }
}''',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
