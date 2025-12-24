import 'package:flutter/material.dart';
import 'package:redus_flutter/redus_flutter.dart';
import '../stores/dashboard_store.dart';

/// Complex real-time dashboard demonstrating all redus features
///
/// This demonstrates the proper separation of concerns:
/// - Store manages its own data stream (background updates)
/// - UI subscribes/unsubscribes via the Live toggle
/// - Data persists even when navigating away from dashboard
class DashboardScreen extends ReactiveWidget {
  DashboardScreen({super.key});

  @override
  void setup() {
    final store = get<DashboardStore>();

    onMounted(() {
      debugPrint('🚀 Dashboard mounted');
    });

    // React to Live toggle - start/stop background updates
    // The store owns the timer, so data accumulates even when UI is not visible
    watchEffect((onCleanup) {
      if (store.isLiveUpdates.value) {
        store.startBackgroundUpdates();
        onCleanup(() => store.stopBackgroundUpdates());
      }
    });

    onDispose(() => debugPrint('👋 Dashboard unmounted'));
  }

  @override
  Widget render(BuildContext context) {
    final store = get<DashboardStore>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _DashboardHeader(store: store, isNarrow: isNarrow),
              const SizedBox(height: 32),

              // Stats Row - responsive grid
              _StatsGrid(store: store, isNarrow: isNarrow),
              const SizedBox(height: 24),

              // Main content - responsive layout
              if (isNarrow)
                Column(
                  children: [
                    _ActivityChart(store: store),
                    const SizedBox(height: 24),
                    _NotificationsPanel(store: store),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _ActivityChart(store: store)),
                    const SizedBox(width: 24),
                    Expanded(child: _NotificationsPanel(store: store)),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final DashboardStore store;
  final bool isNarrow;

  const _DashboardHeader({required this.store, this.isNarrow = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ).createShader(bounds),
              child: Text(
                '🚀 Real-time Dashboard',
                style: TextStyle(
                  fontSize: isNarrow ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complex reactive UI with multiple data streams',
              style: TextStyle(
                fontSize: isNarrow ? 14 : 16,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),

        // Live updates toggle
        Observe<bool>(
          source: store.isLiveUpdates.call,
          builder: (context, isLive) {
            return GestureDetector(
              onTap: store.toggleLiveUpdates,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : const Color(0xFF1D1E33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isLive
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        boxShadow: isLive
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLive ? 'Live' : 'Paused',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isLive
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStore store;
  final bool isNarrow;

  const _StatsGrid({required this.store, this.isNarrow = false});

  @override
  Widget build(BuildContext context) {
    final cards = [
      Observe<String>(
        source: store.revenueFormatted.call,
        builder: (_, value) => _StatCard(
          title: 'Revenue',
          value: value,
          icon: Icons.attach_money,
          color: const Color(0xFF10B981),
          trend: '+12.5%',
          isPositive: true,
        ),
      ),
      Observe<int>(
        source: store.users.call,
        builder: (_, value) => _StatCard(
          title: 'Active Users',
          value: value.toString(),
          icon: Icons.people,
          color: const Color(0xFF6C63FF),
          trend: '+8.3%',
          isPositive: true,
        ),
      ),
      Observe<int>(
        source: store.orders.call,
        builder: (_, value) => _StatCard(
          title: 'Orders',
          value: value.toString(),
          icon: Icons.shopping_cart,
          color: const Color(0xFF00D9FF),
          trend: '+24.1%',
          isPositive: true,
        ),
      ),
      Observe<double>(
        source: store.conversionRate.call,
        builder: (_, value) => _StatCard(
          title: 'Conversion',
          value: '${value.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: const Color(0xFFF59E0B),
          trend: '-2.1%',
          isPositive: false,
        ),
      ),
    ];

    if (isNarrow) {
      // 2x2 grid on narrow screens
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 16),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    // 4 columns on wide screens
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
        const SizedBox(width: 16),
        Expanded(child: cards[3]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1D1E33), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444))
                          .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: 0.95, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final DashboardStore store;

  const _ActivityChart({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Observe<double>(
                source: store.activityTrend.call,
                builder: (_, trend) {
                  final isPositive = trend >= 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isPositive
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: isPositive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPositive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Simple bar chart
          SizedBox(
            height: 200,
            child: Observe<List<double>>(
              source: store.activityData.call,
              builder: (_, data) {
                final maxValue = data.reduce((a, b) => a > b ? a : b);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(data.length, (index) {
                    final value = data[index];
                    final height = (value / maxValue) * 180;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey('$index-$value'),
                          tween: Tween(begin: 0, end: height),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          builder: (context, animHeight, _) {
                            return Container(
                              height: animHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6C63FF),
                                    const Color(0xFF00D9FF),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsPanel extends StatelessWidget {
  final DashboardStore store;

  const _NotificationsPanel({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Observe<int>(
                    source: store.unreadCount.call,
                    builder: (_, count) {
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              TextButton(
                onPressed: store.markAllAsRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 300,
            child: Observe<List<NotificationItem>>(
              source: store.notifications.call,
              builder: (_, notifications) {
                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => store.markAsRead(notification.id),
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

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : const Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: notification.isRead
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFF6C63FF).withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.transparent
                    : const Color(0xFF6C63FF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.time),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
