import 'dart:math';
import '../models/contact.dart';

/// Service for intelligent semantic search across contacts.
/// Supports fuzzy matching, type filtering, and natural language queries.
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  /// Parse a search query and extract intent.
  SearchIntent parseQuery(String query) {
    final normalizedQuery = query.toLowerCase().trim();

    // Empty query returns no intent
    if (normalizedQuery.isEmpty) {
      return SearchIntent(textQuery: null);
    }

    // Category detection keywords
    final categoryKeywords = <String, String>{
      // Social category
      'social': 'Social',
      'socials': 'Social',
      'facebook': 'Social',
      'instagram': 'Social',
      'linkedin': 'Social',
      'twitter': 'Social',
      'tiktok': 'Social',
      'snapchat': 'Social',
      'xing': 'Social',
      'github': 'Social',
      // Gaming category
      'gaming': 'Gaming',
      'games': 'Gaming',
      'steam': 'Gaming',
      'discord': 'Gaming',
      // Business category
      'business': 'Business',
      'work': 'Business',
      'professional': 'Business',
      'company': 'Business',
      'office': 'Business',
      // Personal category
      'personal': 'Personal',
      'birthday': 'Personal',
      'education': 'Personal',
      // Private category
      'private': 'Private',
      'emergency': 'Private',
      'mobile': 'Private',
      // General category
      'general': 'General',
      'email': 'General',
      'phone': 'General',
      'address': 'General',
      'website': 'General',
    };

    // Check for exact category match
    if (categoryKeywords.containsKey(normalizedQuery)) {
      return SearchIntent(
        categoryFilter: categoryKeywords[normalizedQuery],
        textQuery: null,
      );
    }

    // Type-specific patterns
    List<ContactType>? typeFilter;
    String? textQuery = normalizedQuery;

    // @ symbol indicates social handles
    if (normalizedQuery.startsWith('@')) {
      typeFilter = _socialTypes;
      textQuery = normalizedQuery.substring(1);
    }
    // + symbol indicates phone numbers
    else if (normalizedQuery.startsWith('+') ||
             RegExp(r'^\d{3,}').hasMatch(normalizedQuery)) {
      typeFilter = _phoneTypes;
    }
    // Domain-like patterns indicate websites/emails
    else if (normalizedQuery.contains('.com') ||
             normalizedQuery.contains('.de') ||
             normalizedQuery.contains('.org') ||
             normalizedQuery.contains('.net') ||
             normalizedQuery.contains('@')) {
      typeFilter = _webTypes;
    }

    return SearchIntent(
      textQuery: textQuery,
      typeFilter: typeFilter,
    );
  }

  /// Search contacts using semantic matching.
  List<SearchResult> search(String query, List<Contact> contacts) {
    if (query.isEmpty || contacts.isEmpty) {
      return [];
    }

    final intent = parseQuery(query);
    final results = <SearchResult>[];

    for (final contact in contacts) {
      // Apply category filter
      if (intent.categoryFilter != null &&
          contact.type.category != intent.categoryFilter) {
        continue;
      }

      // Apply type filter
      if (intent.typeFilter != null &&
          !intent.typeFilter!.contains(contact.type)) {
        continue;
      }

      // Calculate relevance score
      final result = _scoreContact(contact, intent.textQuery ?? query);
      if (result != null) {
        results.add(result);
      }
    }

    // Sort by relevance score (highest first)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return results;
  }

  /// Search contacts by type.
  List<Contact> searchByType(List<Contact> contacts, List<ContactType> types) {
    return contacts.where((c) => types.contains(c.type)).toList();
  }

  /// Search contacts by category.
  List<Contact> searchByCategory(List<Contact> contacts, String category) {
    return contacts.where((c) => c.type.category == category).toList();
  }

  /// Calculate fuzzy match score using Levenshtein distance.
  double fuzzyMatch(String query, String target) {
    if (query.isEmpty || target.isEmpty) return 0.0;

    final normalizedQuery = query.toLowerCase();
    final normalizedTarget = target.toLowerCase();

    // Exact match
    if (normalizedTarget == normalizedQuery) return 1.0;

    // Contains match (high score)
    if (normalizedTarget.contains(normalizedQuery)) {
      // Score based on how much of the target is covered
      return 0.8 + (0.2 * (normalizedQuery.length / normalizedTarget.length));
    }

    // Starts with match
    if (normalizedTarget.startsWith(normalizedQuery)) {
      return 0.9;
    }

    // Word boundary match
    final words = normalizedTarget.split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.startsWith(normalizedQuery)) {
        return 0.75;
      }
    }

    // Fuzzy match using Levenshtein distance
    final distance = _levenshteinDistance(normalizedQuery, normalizedTarget);
    final maxLen = max(normalizedQuery.length, normalizedTarget.length);

    // Only consider it a match if distance is less than half the query length
    if (distance > normalizedQuery.length / 2 + 1) {
      return 0.0;
    }

    // Convert distance to similarity score (0.0 to 0.6)
    return (1 - (distance / maxLen)) * 0.6;
  }

  SearchResult? _scoreContact(Contact contact, String query) {
    double bestScore = 0.0;
    String matchedField = '';

    // Score label match (higher weight)
    final labelScore = fuzzyMatch(query, contact.label);
    if (labelScore > bestScore) {
      bestScore = labelScore;
      matchedField = 'label';
    }

    // Score value match
    final valueScore = fuzzyMatch(query, contact.value);
    if (valueScore > bestScore) {
      bestScore = valueScore;
      matchedField = 'value';
    }

    // Score type display name match
    final typeScore = fuzzyMatch(query, contact.type.displayName) * 0.7;
    if (typeScore > bestScore) {
      bestScore = typeScore;
      matchedField = 'type';
    }

    // Minimum relevance threshold
    if (bestScore < 0.3) {
      return null;
    }

    return SearchResult(
      contact: contact,
      relevanceScore: bestScore,
      matchedField: matchedField,
    );
  }

  /// Calculate Levenshtein distance between two strings.
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < s2.length; j++) {
        final cost = s1[i] == s2[j] ? 0 : 1;
        v1[j + 1] = min(min(v1[j] + 1, v0[j + 1] + 1), v0[j] + cost);
      }

      final temp = v0;
      v0 = v1;
      v1 = temp;
    }

    return v0[s2.length];
  }

  // Contact type groups
  static const _socialTypes = [
    ContactType.social,
    ContactType.facebook,
    ContactType.instagram,
    ContactType.linkedin,
    ContactType.twitter,
    ContactType.tiktok,
    ContactType.snapchat,
    ContactType.xing,
    ContactType.github,
  ];

  static const _phoneTypes = [
    ContactType.phone,
    ContactType.mobile,
    ContactType.businessPhone,
    ContactType.emergencyContact,
  ];

  static const _webTypes = [
    ContactType.email,
    ContactType.businessEmail,
    ContactType.website,
  ];
}

/// Parsed search intent from a query.
class SearchIntent {
  final String? textQuery;
  final List<ContactType>? typeFilter;
  final String? categoryFilter;

  SearchIntent({
    this.textQuery,
    this.typeFilter,
    this.categoryFilter,
  });

  @override
  String toString() =>
    'SearchIntent(text: $textQuery, types: $typeFilter, category: $categoryFilter)';
}

/// Result of a search with relevance score.
class SearchResult {
  final Contact contact;
  final double relevanceScore;
  final String matchedField;

  SearchResult({
    required this.contact,
    required this.relevanceScore,
    required this.matchedField,
  });

  @override
  String toString() =>
    'SearchResult(${contact.label}, score: ${relevanceScore.toStringAsFixed(2)}, field: $matchedField)';
}

/// Search history entry for tracking user searches.
class SearchHistoryEntry {
  final String id;
  final String query;
  final int resultCount;
  final String? selectedContactId;
  final DateTime timestamp;

  SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.resultCount,
    this.selectedContactId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'query': query,
    'resultCount': resultCount,
    'selectedContactId': selectedContactId,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) => SearchHistoryEntry(
    id: json['id'] as String,
    query: json['query'] as String,
    resultCount: json['resultCount'] as int,
    selectedContactId: json['selectedContactId'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
