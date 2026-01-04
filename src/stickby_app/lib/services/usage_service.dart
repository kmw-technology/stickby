import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Service for tracking feature usage to enable adaptive UI.
/// All data stays local - no cloud upload.
class UsageService {
  static final UsageService _instance = UsageService._internal();
  factory UsageService() => _instance;
  UsageService._internal();

  final StorageService _storage = StorageService();

  // In-memory cache
  Map<String, UsageStat> _usageStats = {};
  List<NavigationEvent> _recentNavigation = [];
  bool _isLoaded = false;

  /// Load usage data from storage.
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final statsJson = await _storage.getUsageStats();
      if (statsJson != null) {
        final decoded = jsonDecode(statsJson) as Map<String, dynamic>;
        _usageStats = decoded.map((key, value) =>
            MapEntry(key, UsageStat.fromJson(value as Map<String, dynamic>)));
      }

      final navJson = await _storage.getNavigationHistory();
      if (navJson != null) {
        final decoded = jsonDecode(navJson) as List;
        _recentNavigation = decoded
            .map((e) => NavigationEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      _isLoaded = true;
    } catch (e) {
      debugPrint('UsageService: Failed to load data: $e');
    }
  }

  /// Save usage data to storage.
  Future<void> _save() async {
    try {
      final statsJson = jsonEncode(
          _usageStats.map((key, value) => MapEntry(key, value.toJson())));
      await _storage.setUsageStats(statsJson);

      // Only keep last 100 navigation events
      if (_recentNavigation.length > 100) {
        _recentNavigation = _recentNavigation.sublist(
            _recentNavigation.length - 100);
      }
      final navJson = jsonEncode(_recentNavigation.map((e) => e.toJson()).toList());
      await _storage.setNavigationHistory(navJson);
    } catch (e) {
      debugPrint('UsageService: Failed to save data: $e');
    }
  }

  /// Track feature usage.
  Future<void> trackFeature(String featureId) async {
    await load();

    final now = DateTime.now();
    if (_usageStats.containsKey(featureId)) {
      _usageStats[featureId] = _usageStats[featureId]!.increment(now);
    } else {
      _usageStats[featureId] = UsageStat(
        featureId: featureId,
        count: 1,
        firstUsed: now,
        lastUsed: now,
      );
    }

    await _save();
  }

  /// Track screen navigation.
  Future<void> trackNavigation(String screenName) async {
    await load();

    _recentNavigation.add(NavigationEvent(
      screenName: screenName,
      timestamp: DateTime.now(),
    ));

    // Also count as feature usage
    await trackFeature('screen_$screenName');
  }

  /// Track action (button click, etc.).
  Future<void> trackAction(String actionId, {String? context}) async {
    await load();
    await trackFeature('action_$actionId');
  }

  /// Get feature usage counts.
  Future<Map<String, int>> getFeatureUsageCounts() async {
    await load();
    return _usageStats.map((key, value) => MapEntry(key, value.count));
  }

  /// Get most used features.
  Future<List<String>> getMostUsedFeatures({int limit = 10}) async {
    await load();

    final sorted = _usageStats.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// Get recommended navigation order based on usage.
  Future<List<String>> getRecommendedNavOrder() async {
    await load();

    // Default tab order
    const defaultOrder = ['home', 'contacts', 'shares', 'groups', 'profile'];

    // Get screen usage
    final screenUsage = <String, int>{};
    for (final screen in defaultOrder) {
      final stat = _usageStats['screen_$screen'];
      screenUsage[screen] = stat?.count ?? 0;
    }

    // Sort by usage (but keep home first)
    final sorted = defaultOrder.sublist(1).toList()
      ..sort((a, b) => (screenUsage[b] ?? 0).compareTo(screenUsage[a] ?? 0));

    return ['home', ...sorted];
  }

  /// Get personalized quick actions for home screen.
  Future<List<QuickAction>> getPersonalizedQuickActions() async {
    await load();

    // Define all possible quick actions
    final allActions = [
      QuickAction(
        id: 'add_contact',
        label: 'Add Contact',
        icon: 'add',
        route: '/contacts/add',
        priority: 1,
      ),
      QuickAction(
        id: 'scan_card',
        label: 'Scan Card',
        icon: 'document_scanner',
        route: '/contacts/scan',
        priority: 2,
      ),
      QuickAction(
        id: 'create_share',
        label: 'New Share',
        icon: 'share',
        route: '/shares/create',
        priority: 3,
      ),
      QuickAction(
        id: 'view_profile',
        label: 'My Profile',
        icon: 'person',
        route: '/profile',
        priority: 4,
      ),
      QuickAction(
        id: 'backup',
        label: 'Backup',
        icon: 'backup',
        route: '/settings/backup',
        priority: 5,
      ),
      QuickAction(
        id: 'search',
        label: 'Search',
        icon: 'search',
        route: '/contacts',
        priority: 6,
      ),
    ];

    // Score actions based on usage
    for (final action in allActions) {
      final usageStat = _usageStats['action_${action.id}'];
      if (usageStat != null) {
        // Boost priority based on usage
        action.dynamicPriority = action.priority - (usageStat.count * 0.1);
      } else {
        action.dynamicPriority = action.priority.toDouble();
      }
    }

    // Sort by dynamic priority (lower is better)
    allActions.sort((a, b) => a.dynamicPriority.compareTo(b.dynamicPriority));

    return allActions.take(4).toList();
  }

  /// Get usage summary.
  Future<UsageSummary> getSummary() async {
    await load();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    int todayCount = 0;
    int weekCount = 0;
    String? mostUsedFeature;
    int mostUsedCount = 0;

    for (final stat in _usageStats.values) {
      if (stat.lastUsed.isAfter(today)) {
        todayCount += stat.count;
      }
      if (stat.lastUsed.isAfter(weekAgo)) {
        weekCount += stat.count;
      }
      if (stat.count > mostUsedCount) {
        mostUsedCount = stat.count;
        mostUsedFeature = stat.featureId;
      }
    }

    return UsageSummary(
      totalFeatures: _usageStats.length,
      totalInteractions: _usageStats.values.fold(0, (sum, s) => sum + s.count),
      interactionsToday: todayCount,
      interactionsThisWeek: weekCount,
      mostUsedFeature: mostUsedFeature,
      recentScreens: _recentNavigation.reversed.take(5).map((e) => e.screenName).toList(),
    );
  }

  /// Clear all usage data.
  Future<void> clearData() async {
    _usageStats.clear();
    _recentNavigation.clear();
    await _storage.clearUsageData();
  }
}

/// A tracked feature usage statistic.
class UsageStat {
  final String featureId;
  final int count;
  final DateTime firstUsed;
  final DateTime lastUsed;

  UsageStat({
    required this.featureId,
    required this.count,
    required this.firstUsed,
    required this.lastUsed,
  });

  UsageStat increment(DateTime timestamp) => UsageStat(
        featureId: featureId,
        count: count + 1,
        firstUsed: firstUsed,
        lastUsed: timestamp,
      );

  Map<String, dynamic> toJson() => {
        'featureId': featureId,
        'count': count,
        'firstUsed': firstUsed.toIso8601String(),
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory UsageStat.fromJson(Map<String, dynamic> json) => UsageStat(
        featureId: json['featureId'] as String,
        count: json['count'] as int,
        firstUsed: DateTime.parse(json['firstUsed'] as String),
        lastUsed: DateTime.parse(json['lastUsed'] as String),
      );
}

/// A navigation event.
class NavigationEvent {
  final String screenName;
  final DateTime timestamp;

  NavigationEvent({
    required this.screenName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'screenName': screenName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory NavigationEvent.fromJson(Map<String, dynamic> json) => NavigationEvent(
        screenName: json['screenName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// A quick action for the home screen.
class QuickAction {
  final String id;
  final String label;
  final String icon;
  final String route;
  final int priority;
  double dynamicPriority;

  QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    required this.priority,
    this.dynamicPriority = 0,
  });
}

/// Summary of usage data.
class UsageSummary {
  final int totalFeatures;
  final int totalInteractions;
  final int interactionsToday;
  final int interactionsThisWeek;
  final String? mostUsedFeature;
  final List<String> recentScreens;

  UsageSummary({
    required this.totalFeatures,
    required this.totalInteractions,
    required this.interactionsToday,
    required this.interactionsThisWeek,
    this.mostUsedFeature,
    required this.recentScreens,
  });
}
