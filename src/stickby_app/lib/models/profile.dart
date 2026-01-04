import 'contact.dart';

class Profile {
  final String id;
  final String displayName;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final Map<String, List<Contact>> contactsByCategory;

  Profile({
    required this.id,
    required this.displayName,
    required this.email,
    this.profileImageUrl,
    this.bio,
    this.contactsByCategory = const {},
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
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

    return Profile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      bio: json['bio'] as String?,
      contactsByCategory: contactsMap,
    );
  }

  List<Contact> get allContacts {
    return contactsByCategory.values.expand((e) => e).toList();
  }

  String get initials {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }
}
