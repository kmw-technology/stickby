import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/insights_provider.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';

/// Widget displaying contact insights on the home screen.
class InsightsWidget extends StatefulWidget {
  const InsightsWidget({super.key});

  @override
  State<InsightsWidget> createState() => _InsightsWidgetState();
}

class _InsightsWidgetState extends State<InsightsWidget> {
  @override
  void initState() {
    super.initState();
    _analyzeContacts();
  }

  void _analyzeContacts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contacts = context.read<ContactsProvider>().contacts;
      context.read<InsightsProvider>().analyzeContacts(contacts);
    });
  }

  @override
  Widget build(BuildContext context) {
    final insightsProvider = context.watch<InsightsProvider>();
    final topInsights = insightsProvider.topInsights;

    if (insightsProvider.isAnalyzing) {
      return _buildLoadingState();
    }

    if (topInsights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Discover',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            TextButton(
              onPressed: () => _showAllInsights(context, insightsProvider),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Insights cards
        ...topInsights.take(3).map((insight) => _buildInsightCard(context, insight)),

        // Group suggestions if any
        if (insightsProvider.groupSuggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildGroupSuggestionCard(context, insightsProvider.groupSuggestions.first),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analyzing your contacts...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, Insight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _showInsightDetails(context, insight),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getInsightColor(insight).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getInsightIcon(insight),
                  color: _getInsightColor(insight),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      insight.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${insight.count}',
                  style: TextStyle(
                    color: _getInsightColor(insight),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSuggestionCard(BuildContext context, GroupSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Group Suggestion',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create a "${suggestion.suggestedName}" group',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            suggestion.reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Member avatars
              ...suggestion.members.take(3).map((contact) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        contact.label.isNotEmpty
                            ? contact.label[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )),
              if (suggestion.members.length > 3)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '+${suggestion.members.length - 3}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // TODO: Create group with suggested members
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Creating group "${suggestion.suggestedName}"...')),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getInsightIcon(Insight insight) {
    switch (insight.type) {
      case InsightType.domain:
        return Icons.alternate_email;
      case InsightType.areaCode:
        return Icons.location_on_outlined;
      case InsightType.platform:
        return Icons.public_outlined;
      case InsightType.platformOverlap:
        return Icons.link;
      case InsightType.category:
        return Icons.category_outlined;
    }
  }

  Color _getInsightColor(Insight insight) {
    switch (insight.type) {
      case InsightType.domain:
        return AppColors.info;
      case InsightType.areaCode:
        return AppColors.success;
      case InsightType.platform:
        return AppColors.primary;
      case InsightType.platformOverlap:
        return AppColors.warning;
      case InsightType.category:
        return AppColors.secondary;
    }
  }

  void _showInsightDetails(BuildContext context, Insight insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getInsightColor(insight).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getInsightIcon(insight),
                      color: _getInsightColor(insight),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          insight.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Contact list
              Text(
                'Related Contacts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: insight.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = insight.contacts[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          contact.label.isNotEmpty
                              ? contact.label[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                      title: Text(contact.label),
                      subtitle: Text(
                        contact.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        contact.type.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllInsights(BuildContext context, InsightsProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Insights',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary stats
              _buildSummaryRow(context, provider),
              const SizedBox(height: 24),

              // All insights list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: provider.insights.length,
                  itemBuilder: (context, index) {
                    return _buildInsightCard(context, provider.insights[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, InsightsProvider provider) {
    final summary = provider.getSummary();

    return Row(
      children: [
        _buildSummaryChip(Icons.alternate_email, '${summary.domainClusters}', 'Domains'),
        const SizedBox(width: 8),
        _buildSummaryChip(Icons.location_on, '${summary.areaCodeClusters}', 'Areas'),
        const SizedBox(width: 8),
        _buildSummaryChip(Icons.public, '${summary.platformsUsed}', 'Platforms'),
      ],
    );
  }

  Widget _buildSummaryChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
