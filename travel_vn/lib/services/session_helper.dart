import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionHelper {
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static const String tokenKey = 'token';

  // LƯU TOKEN
  static Future<void> saveToken(String token) async {
    await storage.write(
      key: tokenKey,
      value: token,
    );
  }

  // LẤY TOKEN
  static Future<String?> getToken() async {
    return await storage.read(key: tokenKey);
  }

  // KIỂM TRA ĐĂNG NHẬP
  static Future<bool> isLoggedIn() async {
    String? token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ĐĂNG XUẤT
  static Future<void> logout() async {
    await storage.delete(key: tokenKey);
  }
}
