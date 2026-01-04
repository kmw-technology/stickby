class ApiConfig {
  static const String baseUrl = 'https://www.kmw-technology.de/stickby/backend';

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String refresh = '/api/auth/refresh';
  static const String logout = '/api/auth/logout';

  // Contacts endpoints
  static const String contacts = '/api/contacts';

  // Shares endpoints
  static const String shares = '/api/shares';

  // Groups endpoints
  static const String groups = '/api/groups';
  static const String groupInvitations = '/api/groups/invitations';

  // Profile endpoints
  static const String profile = '/api/profile';

  // Companies endpoints
  static const String companies = '/api/company';

  // Health check
  static const String health = '/health';
}
