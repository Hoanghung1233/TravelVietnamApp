import 'dart:convert';

import '../service/api_helper.dart';
import 'package:http/http.dart' as http;
import 'package:travel_vn/models/auth_models.dart';

import 'package:travel_vn/models/login_model.dart';
import 'package:travel_vn/services/session_helper.dart';

class AuthRepository {
  static String get baseUrl => const ApiHelper().endpoint('Auth').toString();

  // =========================================
  // HEADERS
  // =========================================
  static Future<Map<String, String>> getHeaders({
    bool requiresToken = false,
  }) async {
    String? token = await SessionHelper.getToken();

    return {
      'content-type': 'application/json',
      if (requiresToken && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // =========================================
  // ĐĂNG KÝ
  // POST: /api/Auth/register
  // =========================================
  static Future<Map<String, dynamic>> register(
    RegisterModel obj,
  ) async {
    String url = '$baseUrl/register';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    if (response.statusCode >= 500) {
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map && data['message'] is String) {
          throw Exception(data['message']);
        }
      } on FormatException {
        // Unexpected server responses may contain diagnostic text.
      }
      throw Exception('Máy chủ chưa gửi được mã OTP. Vui lòng thử lại.');
    }
    throw Exception(_apiError(response, action: 'đăng ký'));
  }

  // =========================================
  // XÁC THỰC OTP ĐĂNG KÝ
  // POST: /api/Auth/verify-email
  // =========================================
  static Future<Map<String, dynamic>> verifyEmail(
    VerifyOtpModel obj,
  ) async {
    String url = '$baseUrl/verify-email';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw Exception(
      'Verify email failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // ĐĂNG NHẬP
  // POST: /api/Auth/login
  // =========================================
  static Future<LoginResult> login(LoginModel obj) async {
    String url = '$baseUrl/login';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      LoginResult result = LoginResult.fromMap(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );

      if (result.success && result.token != null && result.token!.isNotEmpty) {
        await SessionHelper.saveToken(result.token!);
      }

      return result;
    }

    throw Exception(
      'Login failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // ĐĂNG NHẬP BẰNG MẠNG XÃ HỘI
  // Bắt đầu đăng nhập mạng xã hội qua trình duyệt.
  static Future<({Uri url, String key})> startBrowserLogin(
      String provider) async {
    final response = await http
        .post(Uri.parse('$baseUrl/oauth/$provider/start'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception(_apiError(response));
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return (
      url: Uri.parse(data['authorizationUrl'] as String),
      key: data['attemptKey'] as String,
    );
  }

  static Future<LoginResult?> pollBrowserLogin(String key) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/oauth/result'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'attemptKey': key}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 202) return null;
    if (response.statusCode != 200) throw Exception(_apiError(response));
    return LoginResult.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  static String _apiError(http.Response response,
      {String action = 'đăng nhập'}) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        if (data['message'] case final String message) return message;
        if (data['errors'] case final Map errors) {
          for (final messages in errors.values) {
            if (messages is List && messages.isNotEmpty) {
              return messages.first.toString();
            }
          }
        }
      }
    } on FormatException {
      final message =
          utf8.decode(response.bodyBytes, allowMalformed: true).trim();
      const knownMessages = {
        'Email already exists': 'Email đã được đăng ký.',
        'Password must have at least 8 characters':
            'Mật khẩu phải có ít nhất 8 ký tự.',
        'Email and password are required': 'Vui lòng nhập email và mật khẩu.',
      };
      if (knownMessages[message] case final translated?) return translated;
    }
    return 'Không thể $action (HTTP ${response.statusCode}).';
  }

  // =========================================
  // QUÊN MẬT KHẨU - GỬI OTP
  // POST: /api/Auth/forgot-password
  // =========================================
  static Future<Map<String, dynamic>> forgotPassword(
    SendOtpModel obj,
  ) async {
    String url = '$baseUrl/forgot-password';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw Exception(
      'Forgot password failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // ĐẶT LẠI MẬT KHẨU
  // POST: /api/Auth/reset-password
  // =========================================
  static Future<Map<String, dynamic>> resetPassword(
    ResetPasswordModel obj,
  ) async {
    String url = '$baseUrl/reset-password';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw Exception(
      'Reset password failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // ĐỔI MẬT KHẨU
  // POST: /api/Auth/change-password
  // ADMIN, MEMBER
  // =========================================
  static Future<String> changePassword(
    UpdatePasswordModel obj,
  ) async {
    String url = '$baseUrl/change-password';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(requiresToken: true),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception(
      'Change password failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // ĐẶT MẬT KHẨU BAN ĐẦU
  // POST: /api/Auth/set-password
  // ADMIN, MEMBER
  // =========================================
  static Future<String> setPassword(
    SetPasswordModel obj,
  ) async {
    String url = '$baseUrl/set-password';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(requiresToken: true),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception(
      'Set password failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // GỬI OTP XÁC THỰC EMAIL MỚI
  // POST: /api/Auth/send-email-verification
  // ADMIN, MEMBER
  // =========================================
  static Future<String> sendEmailVerification(
    UpdateEmailModel obj,
  ) async {
    String url = '$baseUrl/send-email-verification';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(requiresToken: true),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception(
      'Send email verification failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // XÁC THỰC VÀ CẬP NHẬT EMAIL MỚI
  // POST: /api/Auth/verify-new-email
  // ADMIN, MEMBER
  // =========================================
  static Future<String> verifyNewEmail(
    VerifyOtpModel obj,
  ) async {
    String url = '$baseUrl/verify-new-email';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(requiresToken: true),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception(
      'Verify new email failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // ĐĂNG XUẤT
  // POST: /api/Auth/logout
  // =========================================
  static Future<Map<String, dynamic>> logout() async {
    String url = '$baseUrl/logout';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(requiresToken: true),
    );

    if (response.statusCode == 200) {
      await SessionHelper.logout();
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw Exception(
      'Logout failed: ${response.statusCode} ${response.body}',
    );
  }
}
