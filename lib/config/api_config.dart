// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://192.168.1.153:3000';
  static const String androidEmulatorUrl = 'http://10.0.2.2:3000';

  // Auth
  static const String login = '/api/mobile/auth/login';
  static const String register = '/api/mobile/auth/register';
  static const String me = '/api/mobile/me';
  static const String refreshToken = '/api/mobile/auth/refresh';
  static const String logout = '/api/mobile/auth/logout'; // ✅ added

  // Artworks
  static const String artworks = '/api/artworks';
  static String artwork(String id) => '/api/artworks/$id';
  static String artworkLike(String id) => '/api/artworks/$id/like';
  static String artworkSave(String id) => '/api/artworks/$id/save';

  // Users
  static const String users = '/api/users';
  static String user(String id) => '/api/users/$id';
  static String userByUsername(String username) => '/api/users/username/$username';
  static String userFollow(String id) => '/api/users/$id/follow';

  // Conversations
  static const String conversations = '/api/conversations';
  static String messages(String convoId) => '/api/conversations/$convoId/messages';

  // Music
  static const String tracks = '/api/music';
  static String track(String id) => '/api/music/$id';

  // Events
  static const String events = '/api/events';
  static String event(String id) => '/api/events/$id';

  // Exhibitions
  static const String exhibitions = '/api/exhibitions';
  static String exhibition(String id) => '/api/exhibitions/$id';

  // Upload
  static const String uploadImage = '/api/upload/image';

  // Search
  static const String search = '/api/search';

  // Exchange rates
  static const String exchangeRates = '/api/exchange-rates';
}
