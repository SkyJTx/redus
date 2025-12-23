import 'dart:async';

import 'package:redus_flutter/redus_flutter.dart';

/// Real-time dashboard store demonstrating complex reactive state
///
/// This store simulates a real-world scenario where:
/// - Data updates continuously in the background (from API/WebSocket)
/// - The UI can subscribe/unsubscribe to receive live updates
/// - Data persists even when the dashboard is not visible
class DashboardStore {
  /// Background timer that simulates continuous data updates
  /// In a real app, this would be a WebSocket connection or polling service
  Timer? _backgroundTimer;

  /// Whether background updates are running
  bool get isBackgroundActive => _backgroundTimer != null;

  // --- Reactive State ---

  /// Live metrics that update in real-time
  final revenue = ref(124500.0);
  final users = ref(1847);
  final orders = ref(342);
  final conversionRate = ref(3.2);

  /// Notification list
  final notifications = ref<List<NotificationItem>>([
    NotificationItem(
      id: '1',
      title: 'New order received',
      message: 'Order #1234 from John Doe',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: 'User milestone',
      message: 'Congratulations! 1800 users reached',
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '3',
      title: 'Revenue update',
      message: 'Daily target achieved!',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
  ]);

  /// Activity data for chart
  final activityData = ref<List<double>>([
    3.2,
    4.5,
    3.8,
    5.1,
    4.2,
    6.3,
    5.8,
    7.2,
    6.5,
    8.1,
    7.4,
    9.2,
  ]);

  /// Controls whether the UI receives live updates from the background data stream.
  /// When true, UI widgets will react to data changes.
  /// When false, data still updates in background but UI won't refresh.
  final isLiveUpdates = ref(false);

  // --- Computed Properties ---

  late final Computed<int> unreadCount;
  late final Computed<String> revenueFormatted;
  late final Computed<double> activityTrend;

  DashboardStore() {
    unreadCount = computed(
      () => notifications.value.where((n) => !n.isRead).length,
    );

    revenueFormatted = computed(() {
      final value = revenue.value;
      if (value >= 1000000) {
        return '\$${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '\$${(value / 1000).toStringAsFixed(1)}K';
      }
      return '\$${value.toStringAsFixed(0)}';
    });

    activityTrend = computed(() {
      final data = activityData.value;
      if (data.length < 2) return 0.0;
      final recent = data.sublist(data.length - 3);
      final earlier = data.sublist(data.length - 6, data.length - 3);
      final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
      final earlierAvg = earlier.reduce((a, b) => a + b) / earlier.length;
      return ((recentAvg - earlierAvg) / earlierAvg) * 100;
    });
  }

  // --- Actions ---

  void toggleLiveUpdates() {
    isLiveUpdates.value = !isLiveUpdates.value;
  }

  void markAsRead(String id) {
    notifications.value = notifications.value.map((n) {
      if (n.id == id) {
        return NotificationItem(
          id: n.id,
          title: n.title,
          message: n.message,
          time: n.time,
          isRead: true,
        );
      }
      return n;
    }).toList();
  }

  void markAllAsRead() {
    notifications.value = notifications.value.map((n) {
      return NotificationItem(
        id: n.id,
        title: n.title,
        message: n.message,
        time: n.time,
        isRead: true,
      );
    }).toList();
  }

  void simulateUpdate() {
    // Simulate real-time data changes
    revenue.value += (50 + (DateTime.now().millisecond % 200)).toDouble();
    users.value += DateTime.now().second % 3;
    orders.value += 1;
    conversionRate.value = 3.0 + (DateTime.now().millisecond % 30) / 10;

    // Add new activity data point
    final newData = List<double>.from(activityData.value);
    if (newData.length > 20) newData.removeAt(0);
    newData.add(5 + (DateTime.now().millisecond % 50) / 10);
    activityData.value = newData;
  }

  void addNotification(String title, String message) {
    notifications.value = [
      NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        time: DateTime.now(),
        isRead: false,
      ),
      ...notifications.value,
    ];
  }

  // --- Background Data Stream Control ---

  /// Start background data updates (simulates WebSocket/API stream)
  /// Call this when the app initializes or dashboard becomes active
  void startBackgroundUpdates() {
    if (_backgroundTimer != null) return; // Already running

    _backgroundTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      simulateUpdate();
    });
  }

  /// Stop background data updates
  /// Call this when app goes to background or dashboard is no longer needed
  void stopBackgroundUpdates() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }

  /// Dispose of resources - call when store is no longer needed
  void dispose() {
    stopBackgroundUpdates();
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });
}
