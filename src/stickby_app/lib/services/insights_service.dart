import '../models/contact.dart';

/// Service for discovering patterns and commonalities in contacts.
/// Analyzes email domains, phone area codes, social platforms, etc.
class InsightsService {
  static final InsightsService _instance = InsightsService._internal();
  factory InsightsService() => _instance;
  InsightsService._internal();

  /// Analyze contacts and generate all insights.
  List<Insight> analyzeContacts(List<Contact> contacts) {
    final insights = <Insight>[];

    // Email domain analysis
    insights.addAll(detectEmailDomains(contacts));

    // Phone area code analysis
    insights.addAll(detectAreaCodes(contacts));

    // Social platform analysis
    insights.addAll(detectSocialPlatforms(contacts));

    // Platform overlap analysis
    insights.addAll(detectPlatformOverlaps(contacts));

    // Category distribution
    insights.addAll(detectCategoryDistribution(contacts));

    // Sort by count (most significant first)
    insights.sort((a, b) => b.count.compareTo(a.count));

    return insights;
  }

  /// Detect email domain clusters.
  List<DomainCluster> detectEmailDomains(List<Contact> contacts) {
    final emailContacts = contacts.where((c) =>
        c.type == ContactType.email || c.type == ContactType.businessEmail);

    final domainCounts = <String, List<Contact>>{};

    for (final contact in emailContacts) {
      final parts = contact.value.split('@');
      if (parts.length == 2) {
        final domain = parts[1].toLowerCase();
        domainCounts.putIfAbsent(domain, () => []).add(contact);
      }
    }

    // Only report domains with 2+ contacts
    return domainCounts.entries
        .where((e) => e.value.length >= 2)
        .map((e) => DomainCluster(
              domain: e.key,
              contacts: e.value,
              isBusinessDomain: !_personalDomains.contains(e.key),
            ))
        .toList();
  }

  /// Detect phone area code clusters.
  List<AreaCodeCluster> detectAreaCodes(List<Contact> contacts) {
    final phoneContacts = contacts.where((c) =>
        c.type == ContactType.phone ||
        c.type == ContactType.mobile ||
        c.type == ContactType.businessPhone);

    final areaCodeCounts = <String, List<Contact>>{};

    for (final contact in phoneContacts) {
      final areaCode = _extractAreaCode(contact.value);
      if (areaCode != null) {
        areaCodeCounts.putIfAbsent(areaCode, () => []).add(contact);
      }
    }

    // Only report area codes with 2+ contacts
    return areaCodeCounts.entries
        .where((e) => e.value.length >= 2)
        .map((e) => AreaCodeCluster(
              areaCode: e.key,
              location: _areaCodeLocations[e.key],
              contacts: e.value,
            ))
        .toList();
  }

  /// Detect which social platforms are most used.
  List<PlatformDistribution> detectSocialPlatforms(List<Contact> contacts) {
    final platformCounts = <ContactType, List<Contact>>{};

    for (final contact in contacts) {
      if (_socialPlatforms.contains(contact.type)) {
        platformCounts.putIfAbsent(contact.type, () => []).add(contact);
      }
    }

    // Only report platforms with at least 1 contact
    return platformCounts.entries
        .map((e) => PlatformDistribution(
              platform: e.key,
              contacts: e.value,
            ))
        .toList();
  }

  /// Detect contacts that appear on multiple social platforms.
  List<PlatformOverlap> detectPlatformOverlaps(List<Contact> contacts) {
    // Group contacts by their label (assuming same label = same person)
    final byLabel = <String, Set<ContactType>>{};
    final contactsByLabel = <String, List<Contact>>{};

    for (final contact in contacts) {
      if (_socialPlatforms.contains(contact.type)) {
        final normalizedLabel = contact.label.toLowerCase().trim();
        byLabel.putIfAbsent(normalizedLabel, () => {}).add(contact.type);
        contactsByLabel.putIfAbsent(normalizedLabel, () => []).add(contact);
      }
    }

    // Find labels with multiple platforms
    final overlaps = <PlatformOverlap>[];
    for (final entry in byLabel.entries) {
      if (entry.value.length >= 2) {
        overlaps.add(PlatformOverlap(
          contactLabel: entry.key,
          platforms: entry.value.toList(),
          contacts: contactsByLabel[entry.key]!,
        ));
      }
    }

    return overlaps;
  }

  /// Detect distribution across categories.
  List<CategoryDistribution> detectCategoryDistribution(List<Contact> contacts) {
    final categoryCounts = <String, List<Contact>>{};

    for (final contact in contacts) {
      final category = contact.type.category;
      categoryCounts.putIfAbsent(category, () => []).add(contact);
    }

    return categoryCounts.entries
        .map((e) => CategoryDistribution(
              category: e.key,
              contacts: e.value,
            ))
        .toList();
  }

  /// Generate group suggestions based on insights.
  List<GroupSuggestion> suggestGroups(List<Insight> insights) {
    final suggestions = <GroupSuggestion>[];

    // Suggest groups for business email domains
    for (final insight in insights.whereType<DomainCluster>()) {
      if (insight.isBusinessDomain && insight.count >= 3) {
        final companyName = _formatCompanyName(insight.domain);
        suggestions.add(GroupSuggestion(
          suggestedName: companyName,
          members: insight.contacts,
          reason: 'All have @${insight.domain} email',
          type: GroupSuggestionType.company,
        ));
      }
    }

    // Suggest groups for area codes
    for (final insight in insights.whereType<AreaCodeCluster>()) {
      if (insight.count >= 3 && insight.location != null) {
        suggestions.add(GroupSuggestion(
          suggestedName: insight.location!,
          members: insight.contacts,
          reason: 'All in ${insight.location} area (${insight.areaCode})',
          type: GroupSuggestionType.location,
        ));
      }
    }

    return suggestions;
  }

  /// Get top insights for display.
  List<Insight> getTopInsights(List<Contact> contacts, {int limit = 5}) {
    final all = analyzeContacts(contacts);
    return all.take(limit).toList();
  }

  String? _extractAreaCode(String phone) {
    // Clean phone number
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // German format: +49 XXX or 0XXX
    if (cleaned.startsWith('+49')) {
      // Extract next 2-4 digits as area code
      final rest = cleaned.substring(3);
      if (rest.length >= 2) {
        // Major German area codes
        for (final code in _germanAreaCodes.keys) {
          if (rest.startsWith(code)) {
            return '+49 $code';
          }
        }
        // Default: first 2 digits
        return '+49 ${rest.substring(0, 2)}';
      }
    } else if (cleaned.startsWith('0') && cleaned.length >= 4) {
      // Local German format
      for (final code in _germanAreaCodes.keys) {
        if (cleaned.substring(1).startsWith(code)) {
          return '+49 $code';
        }
      }
      return '+49 ${cleaned.substring(1, 3)}';
    }

    // US format: +1 XXX
    if (cleaned.startsWith('+1') && cleaned.length >= 5) {
      return '+1 ${cleaned.substring(2, 5)}';
    }

    return null;
  }

  String _formatCompanyName(String domain) {
    // Remove TLD and format
    final parts = domain.split('.');
    if (parts.isEmpty) return domain;

    final name = parts.first;
    // Capitalize first letter
    return name[0].toUpperCase() + name.substring(1);
  }

  static const _personalDomains = {
    'gmail.com',
    'googlemail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'aol.com',
    'icloud.com',
    'mail.com',
    'protonmail.com',
    'gmx.de',
    'gmx.net',
    'web.de',
    't-online.de',
    'freenet.de',
    'posteo.de',
    'mailbox.org',
  };

  static const _socialPlatforms = {
    ContactType.facebook,
    ContactType.instagram,
    ContactType.linkedin,
    ContactType.twitter,
    ContactType.tiktok,
    ContactType.snapchat,
    ContactType.xing,
    ContactType.github,
    ContactType.steam,
    ContactType.discord,
  };

  static const _germanAreaCodes = {
    '30': 'Berlin',
    '40': 'Hamburg',
    '89': 'München',
    '69': 'Frankfurt',
    '221': 'Köln',
    '211': 'Düsseldorf',
    '711': 'Stuttgart',
    '341': 'Leipzig',
    '351': 'Dresden',
    '511': 'Hannover',
    '421': 'Bremen',
    '231': 'Dortmund',
    '201': 'Essen',
    '228': 'Bonn',
    '621': 'Mannheim',
    '911': 'Nürnberg',
  };

  static final _areaCodeLocations = {
    '+49 30': 'Berlin',
    '+49 40': 'Hamburg',
    '+49 89': 'München',
    '+49 69': 'Frankfurt',
    '+49 221': 'Köln',
    '+49 211': 'Düsseldorf',
    '+49 711': 'Stuttgart',
    '+49 341': 'Leipzig',
    '+49 351': 'Dresden',
    '+49 511': 'Hannover',
    '+49 421': 'Bremen',
    '+49 231': 'Dortmund',
    '+49 201': 'Essen',
    '+49 228': 'Bonn',
    '+49 621': 'Mannheim',
    '+49 911': 'Nürnberg',
  };
}

// ============================================================================
// Insight Types
// ============================================================================

/// Base class for all insights.
abstract class Insight {
  String get title;
  String get description;
  int get count;
  InsightType get type;
  List<Contact> get contacts;
}

enum InsightType {
  domain,
  areaCode,
  platform,
  platformOverlap,
  category,
}

/// Email domain cluster insight.
class DomainCluster extends Insight {
  final String domain;
  final bool isBusinessDomain;
  @override
  final List<Contact> contacts;

  DomainCluster({
    required this.domain,
    required this.contacts,
    required this.isBusinessDomain,
  });

  @override
  String get title => isBusinessDomain ? 'Company Email' : 'Email Provider';

  @override
  String get description => '$count contacts with @$domain';

  @override
  int get count => contacts.length;

  @override
  InsightType get type => InsightType.domain;
}

/// Phone area code cluster insight.
class AreaCodeCluster extends Insight {
  final String areaCode;
  final String? location;
  @override
  final List<Contact> contacts;

  AreaCodeCluster({
    required this.areaCode,
    this.location,
    required this.contacts,
  });

  @override
  String get title => location ?? 'Area Code';

  @override
  String get description => '$count contacts in ${location ?? areaCode} area';

  @override
  int get count => contacts.length;

  @override
  InsightType get type => InsightType.areaCode;
}

/// Social platform distribution insight.
class PlatformDistribution extends Insight {
  final ContactType platform;
  @override
  final List<Contact> contacts;

  PlatformDistribution({
    required this.platform,
    required this.contacts,
  });

  @override
  String get title => platform.displayName;

  @override
  String get description => '$count contacts on ${platform.displayName}';

  @override
  int get count => contacts.length;

  @override
  InsightType get type => InsightType.platform;
}

/// Platform overlap insight (contacts on multiple platforms).
class PlatformOverlap extends Insight {
  final String contactLabel;
  final List<ContactType> platforms;
  @override
  final List<Contact> contacts;

  PlatformOverlap({
    required this.contactLabel,
    required this.platforms,
    required this.contacts,
  });

  @override
  String get title => 'Multi-Platform';

  @override
  String get description =>
      '$contactLabel is on ${platforms.map((p) => p.displayName).join(', ')}';

  @override
  int get count => platforms.length;

  @override
  InsightType get type => InsightType.platformOverlap;
}

/// Category distribution insight.
class CategoryDistribution extends Insight {
  final String category;
  @override
  final List<Contact> contacts;

  CategoryDistribution({
    required this.category,
    required this.contacts,
  });

  @override
  String get title => category;

  @override
  String get description => '$count $category contacts';

  @override
  int get count => contacts.length;

  @override
  InsightType get type => InsightType.category;
}

// ============================================================================
// Group Suggestions
// ============================================================================

enum GroupSuggestionType {
  company,
  location,
  platform,
  custom,
}

/// Suggested group based on contact patterns.
class GroupSuggestion {
  final String suggestedName;
  final List<Contact> members;
  final String reason;
  final GroupSuggestionType type;

  GroupSuggestion({
    required this.suggestedName,
    required this.members,
    required this.reason,
    required this.type,
  });
}
