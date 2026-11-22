import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionHelper {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) =>
      _storage.write(key: 'booking_api_token', value: token);

  static Future<String?> get token =>
      _storage.read(key: 'booking_api_token');

  static Future<void> saveBaseUrl(String url) =>
      _storage.write(key: 'booking_api_url', value: url);

  static Future<String?> get baseUrl =>
      _storage.read(key: 'booking_api_url');

  static Future<void> clearToken() =>
      _storage.delete(key: 'booking_api_token');
}
