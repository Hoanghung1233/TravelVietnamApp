import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionHelper {
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static const String tokenKey = 'token';
  static String? _token;
  static String? get currentToken => _token;

  static Future<void> initialize() async {
    _token = await storage.read(key: tokenKey);
  }

  // LƯU TOKEN
  static Future<void> saveToken(String token) async {
    await storage.write(
      key: tokenKey,
      value: token,
    );
    _token = token;
  }

  // LẤY TOKEN
  static Future<String?> getToken() async {
    return _token;
  }

  // KIỂM TRA ĐĂNG NHẬP
  static Future<bool> isLoggedIn() async {
    String? token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ĐĂNG XUẤT
  static Future<void> logout() async {
    _token = null;
    await storage.delete(key: tokenKey);
  }
}
