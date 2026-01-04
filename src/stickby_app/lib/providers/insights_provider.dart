import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../services/insights_service.dart';

/// Provider for managing contact insights and group suggestions.
class InsightsProvider with ChangeNotifier {
  final InsightsService _insightsService = InsightsService();

  List<Insight> _insights = [];
  List<GroupSuggestion> _groupSuggestions = [];
  Set<String> _dismissedInsightIds = {};
  bool _isAnalyzing = false;

  /// All detected insights.
  List<Insight> get insights => _insights;

  /// Top insights for display (excluding dismissed).
  List<Insight> get topInsights => _insights
      .where((i) => !_dismissedInsightIds.contains(_getInsightId(i)))
      .take(5)
      .toList();

  /// Suggested groups based on patterns.
  List<GroupSuggestion> get groupSuggestions => _groupSuggestions;

  /// Whether analysis is in progress.
  bool get isAnalyzing => _isAnalyzing;

  /// Analyze contacts and update insights.
  Future<void> analyzeContacts(List<Contact> contacts) async {
    if (contacts.isEmpty) {
      _insights = [];
      _groupSuggestions = [];
      notifyListeners();
      return;
    }

    _isAnalyzing = true;
    notifyListeners();

    try {
      // Run analysis (simulating async for potential future ML)
      await Future.delayed(const Duration(milliseconds: 100));

      _insights = _insightsService.analyzeContacts(contacts);
      _groupSuggestions = _insightsService.suggestGroups(_insights);
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  /// Get insights by type.
  List<Insight> getInsightsByType(InsightType type) {
    return _insights.where((i) => i.type == type).toList();
  }

  /// Get domain clusters.
  List<DomainCluster> get domainClusters =>
      _insights.whereType<DomainCluster>().toList();

  /// Get area code clusters.
  List<AreaCodeCluster> get areaCodeClusters =>
      _insights.whereType<AreaCodeCluster>().toList();

  /// Get platform distributions.
  List<PlatformDistribution> get platformDistributions =>
      _insights.whereType<PlatformDistribution>().toList();

  /// Get platform overlaps.
  List<PlatformOverlap> get platformOverlaps =>
      _insights.whereType<PlatformOverlap>().toList();

  /// Dismiss an insight (hide from top insights).
  void dismissInsight(Insight insight) {
    _dismissedInsightIds.add(_getInsightId(insight));
    notifyListeners();
  }

  /// Reset dismissed insights.
  void resetDismissedInsights() {
    _dismissedInsightIds.clear();
    notifyListeners();
  }

  /// Get summary stats.
  InsightsSummary getSummary() {
    return InsightsSummary(
      totalInsights: _insights.length,
      domainClusters: domainClusters.length,
      areaCodeClusters: areaCodeClusters.length,
      platformsUsed: platformDistributions.length,
      multiPlatformContacts: platformOverlaps.length,
      groupSuggestions: _groupSuggestions.length,
    );
  }

  String _getInsightId(Insight insight) {
    return '${insight.type.name}_${insight.title}_${insight.count}';
  }
}

/// Summary of all insights.
class InsightsSummary {
  final int totalInsights;
  final int domainClusters;
  final int areaCodeClusters;
  final int platformsUsed;
  final int multiPlatformContacts;
  final int groupSuggestions;

  InsightsSummary({
    required this.totalInsights,
    required this.domainClusters,
    required this.areaCodeClusters,
    required this.platformsUsed,
    required this.multiPlatformContacts,
    required this.groupSuggestions,
  });
}
