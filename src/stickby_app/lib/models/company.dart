import 'contact.dart';

class Company {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final int followerCount;
  final bool isContractor;
  final Map<String, List<Contact>> contactsByCategory;

  Company({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.followerCount = 0,
    this.isContractor = false,
    this.contactsByCategory = const {},
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    final contactsMap = <String, List<Contact>>{};

    if (json['contactsByCategory'] != null) {
      final categories = json['contactsByCategory'] as Map<String, dynamic>;
      for (final entry in categories.entries) {
        final contacts = (entry.value as List<dynamic>)
            .map((e) => Contact.fromJson(e as Map<String, dynamic>))
            .toList();
        contactsMap[entry.key] = contacts;
      }
    }

    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      followerCount: json['followerCount'] as int? ?? 0,
      isContractor: json['isContractor'] as bool? ?? false,
      contactsByCategory: contactsMap,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  List<Contact> get allContacts {
    return contactsByCategory.values.expand((e) => e).toList();
  }
}
