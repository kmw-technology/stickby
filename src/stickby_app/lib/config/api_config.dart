class ApiConfig {
  static const String baseUrl = 'https://www.kmw-technology.de/stickby/backend';
  static const String wsBaseUrl = 'wss://www.kmw-technology.de/stickby/backend';

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
  static const String profileImage = '/api/profile/image';

  // Companies endpoints
  static const String companies = '/api/company';

  // Demo sync endpoints
  static const String demoSessionCreate = '/api/demo/session/create';
  static const String demoSession = '/api/demo/session'; // + /{sessionCode}
  static const String demoIdentities = '/api/demo/identities';
  static const String demoSyncHub = '/hubs/demosync';

  // Health check
  static const String health = '/health';
}
