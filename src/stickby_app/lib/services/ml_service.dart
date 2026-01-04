import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/contact.dart';

/// Service for ML-powered text recognition from business cards.
/// Uses Google ML Kit for on-device OCR.
class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Recognize text from an image file.
  Future<RecognizedText> recognizeText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return _textRecognizer.processImage(inputImage);
  }

  /// Parse recognized text and extract contact candidates.
  List<ContactCandidate> parseBusinessCard(RecognizedText recognizedText) {
    final candidates = <ContactCandidate>[];
    final fullText = recognizedText.text;

    // Extract emails
    final emails = extractEmails(fullText);
    for (final email in emails) {
      candidates.add(ContactCandidate(
        type: _isBusinessEmail(email) ? ContactType.businessEmail : ContactType.email,
        label: _isBusinessEmail(email) ? 'Work Email' : 'Email',
        value: email,
        confidence: 0.95,
      ));
    }

    // Extract phone numbers
    final phones = extractPhoneNumbers(fullText);
    for (final phone in phones) {
      candidates.add(ContactCandidate(
        type: ContactType.phone,
        label: 'Phone',
        value: phone,
        confidence: 0.90,
      ));
    }

    // Extract URLs/websites
    final urls = extractUrls(fullText);
    for (final url in urls) {
      candidates.add(ContactCandidate(
        type: ContactType.website,
        label: 'Website',
        value: url,
        confidence: 0.90,
      ));
    }

    // Extract social media handles
    final socialHandles = extractSocialHandles(fullText);
    candidates.addAll(socialHandles);

    // Extract company name (usually the largest/most prominent text)
    final company = _extractCompanyName(recognizedText);
    if (company != null) {
      candidates.add(ContactCandidate(
        type: ContactType.company,
        label: 'Company',
        value: company,
        confidence: 0.70,
      ));
    }

    // Extract job title/position
    final position = _extractPosition(fullText);
    if (position != null) {
      candidates.add(ContactCandidate(
        type: ContactType.position,
        label: 'Position',
        value: position,
        confidence: 0.65,
      ));
    }

    // Extract address
    final address = _extractAddress(fullText);
    if (address != null) {
      candidates.add(ContactCandidate(
        type: ContactType.address,
        label: 'Address',
        value: address,
        confidence: 0.75,
      ));
    }

    return candidates;
  }

  /// Extract email addresses from text.
  List<String> extractEmails(String text) {
    final emailRegex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    );
    return emailRegex.allMatches(text).map((m) => m.group(0)!.toLowerCase()).toSet().toList();
  }

  /// Extract phone numbers from text.
  List<String> extractPhoneNumbers(String text) {
    // Match various phone formats
    final phoneRegex = RegExp(
      r'(?:\+\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{2,4}[-.\s]?\d{2,4}[-.\s]?\d{0,4}',
    );

    final matches = phoneRegex.allMatches(text);
    final phones = <String>{};

    for (final match in matches) {
      var phone = match.group(0)!;
      // Clean up and validate
      final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (digits.length >= 7 && digits.length <= 15) {
        phones.add(_normalizePhoneNumber(phone));
      }
    }

    return phones.toList();
  }

  /// Extract URLs from text.
  List<String> extractUrls(String text) {
    final urlRegex = RegExp(
      r'(?:https?://)?(?:www\.)?[a-zA-Z0-9][-a-zA-Z0-9]*(?:\.[a-zA-Z]{2,})+(?:/[^\s]*)?',
      caseSensitive: false,
    );

    final urls = <String>{};
    for (final match in urlRegex.allMatches(text)) {
      var url = match.group(0)!;
      // Skip email domains
      if (!url.contains('@')) {
        if (!url.startsWith('http')) {
          url = 'https://$url';
        }
        urls.add(url.toLowerCase());
      }
    }

    return urls.toList();
  }

  /// Extract social media handles from text.
  List<ContactCandidate> extractSocialHandles(String text) {
    final candidates = <ContactCandidate>[];

    // LinkedIn
    final linkedinRegex = RegExp(r'linkedin\.com/in/([a-zA-Z0-9_-]+)', caseSensitive: false);
    for (final match in linkedinRegex.allMatches(text)) {
      candidates.add(ContactCandidate(
        type: ContactType.linkedin,
        label: 'LinkedIn',
        value: 'https://linkedin.com/in/${match.group(1)}',
        confidence: 0.95,
      ));
    }

    // Twitter/X
    final twitterRegex = RegExp(r'(?:twitter|x)\.com/([a-zA-Z0-9_]+)', caseSensitive: false);
    for (final match in twitterRegex.allMatches(text)) {
      candidates.add(ContactCandidate(
        type: ContactType.twitter,
        label: 'Twitter',
        value: '@${match.group(1)}',
        confidence: 0.95,
      ));
    }

    // Instagram
    final instagramRegex = RegExp(r'instagram\.com/([a-zA-Z0-9_.]+)', caseSensitive: false);
    for (final match in instagramRegex.allMatches(text)) {
      candidates.add(ContactCandidate(
        type: ContactType.instagram,
        label: 'Instagram',
        value: '@${match.group(1)}',
        confidence: 0.95,
      ));
    }

    // GitHub
    final githubRegex = RegExp(r'github\.com/([a-zA-Z0-9_-]+)', caseSensitive: false);
    for (final match in githubRegex.allMatches(text)) {
      candidates.add(ContactCandidate(
        type: ContactType.github,
        label: 'GitHub',
        value: match.group(1)!,
        confidence: 0.95,
      ));
    }

    // Generic @ handles (could be Twitter, Instagram, etc.)
    final handleRegex = RegExp(r'@([a-zA-Z0-9_]{2,30})');
    for (final match in handleRegex.allMatches(text)) {
      final handle = match.group(1)!;
      // Skip if already found as specific platform
      if (!candidates.any((c) => c.value.contains(handle))) {
        candidates.add(ContactCandidate(
          type: ContactType.social,
          label: 'Social',
          value: '@$handle',
          confidence: 0.60,
        ));
      }
    }

    return candidates;
  }

  /// Detect contact type from value pattern.
  ContactType? detectContactType(String value) {
    final lowerValue = value.toLowerCase().trim();

    // Email
    if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(lowerValue)) {
      return _isBusinessEmail(lowerValue) ? ContactType.businessEmail : ContactType.email;
    }

    // Phone
    if (RegExp(r'^[\d\s\-+()]{7,15}$').hasMatch(value)) {
      return ContactType.phone;
    }

    // URL
    if (lowerValue.startsWith('http') || lowerValue.startsWith('www.')) {
      // Check for specific social platforms
      if (lowerValue.contains('linkedin')) return ContactType.linkedin;
      if (lowerValue.contains('twitter') || lowerValue.contains('x.com')) return ContactType.twitter;
      if (lowerValue.contains('instagram')) return ContactType.instagram;
      if (lowerValue.contains('facebook')) return ContactType.facebook;
      if (lowerValue.contains('github')) return ContactType.github;
      return ContactType.website;
    }

    // Social handle
    if (value.startsWith('@')) {
      return ContactType.social;
    }

    return null;
  }

  bool _isBusinessEmail(String email) {
    final personalDomains = [
      'gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com',
      'aol.com', 'icloud.com', 'mail.com', 'protonmail.com',
      'gmx.de', 'web.de', 't-online.de',
    ];
    final domain = email.split('@').last.toLowerCase();
    return !personalDomains.contains(domain);
  }

  String _normalizePhoneNumber(String phone) {
    // Remove extra whitespace and normalize separators
    return phone.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String? _extractCompanyName(RecognizedText recognizedText) {
    // Company name is often in the first or largest text block
    if (recognizedText.blocks.isEmpty) return null;

    // Sort blocks by size (area) descending
    final sortedBlocks = List<TextBlock>.from(recognizedText.blocks);
    sortedBlocks.sort((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;
      final areaB = b.boundingBox.width * b.boundingBox.height;
      return areaB.compareTo(areaA);
    });

    // Get the largest text that looks like a company name
    for (final block in sortedBlocks.take(3)) {
      final text = block.text.trim();
      // Skip if it's clearly not a company name
      if (text.contains('@') ||
          text.contains('http') ||
          RegExp(r'^[\d\s\-+()]{7,}$').hasMatch(text)) {
        continue;
      }
      // Must have at least 2 characters
      if (text.length >= 2 && text.length <= 50) {
        return text;
      }
    }

    return null;
  }

  String? _extractPosition(String text) {
    // Common job title patterns
    final titlePatterns = [
      RegExp(r'\b(CEO|CTO|CFO|COO|CMO|CIO)\b', caseSensitive: false),
      RegExp(r'\b(Director|Manager|Lead|Head|Chief)\s+(?:of\s+)?[\w\s]+', caseSensitive: false),
      RegExp(r'\b(Senior|Junior|Principal)?\s*(?:Software|Data|Product|Project|Marketing|Sales|HR|Finance)\s*[\w\s]*(?:Engineer|Developer|Manager|Analyst|Designer|Consultant)\b', caseSensitive: false),
      RegExp(r'\b(?:Software|Data|Product|Project|Marketing|Sales|HR|Finance)\s*[\w\s]*(?:Engineer|Developer|Manager|Analyst|Designer|Consultant)\b', caseSensitive: false),
      RegExp(r'\b(Founder|Co-Founder|Owner|Partner|Associate|Consultant|Specialist|Coordinator)\b', caseSensitive: false),
    ];

    for (final pattern in titlePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)!.trim();
      }
    }

    return null;
  }

  String? _extractAddress(String text) {
    // Look for address-like patterns
    final addressPatterns = [
      // German address format: Street Number, ZIP City
      RegExp(r'[\w\s.-]+\s+\d+[a-zA-Z]?,?\s*\d{4,5}\s+[\w\s-]+', multiLine: true),
      // US address format: Number Street, City, State ZIP
      RegExp(r'\d+\s+[\w\s.-]+,?\s*[\w\s]+,?\s*[A-Z]{2}\s*\d{5}', caseSensitive: false, multiLine: true),
    ];

    for (final pattern in addressPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)!.trim();
      }
    }

    return null;
  }

  /// Clean up resources.
  void dispose() {
    _textRecognizer.close();
  }
}

/// A contact candidate extracted from a business card.
class ContactCandidate {
  final ContactType type;
  final String label;
  final String value;
  final double confidence;

  ContactCandidate({
    required this.type,
    required this.label,
    required this.value,
    required this.confidence,
  });

  @override
  String toString() => 'ContactCandidate(type: $type, label: $label, value: $value, confidence: $confidence)';
}
