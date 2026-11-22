import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:travel_vn/models/auth_models.dart';

import 'package:travel_vn/models/login_model.dart';
import 'package:travel_vn/services/session_helper.dart';

class AuthRepository {
  static String get baseUrl => '${dotenv.env['API_URL']}/api/Auth';

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
      return jsonDecode(response.body);
    }

    throw Exception(
      'Register failed: ${response.statusCode} ${response.body}',
    );
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
      return jsonDecode(response.body);
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
        jsonDecode(response.body),
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
  // POST: /api/Auth/social-login
  // =========================================
  static Future<LoginResult> socialLogin(
    SocialLoginModel obj,
  ) async {
    String url = '$baseUrl/social-login';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      LoginResult result = LoginResult.fromMap(
        jsonDecode(response.body),
      );

      if (result.success && result.token != null && result.token!.isNotEmpty) {
        await SessionHelper.saveToken(result.token!);
      }

      return result;
    }

    throw Exception(
      'Social login failed: ${response.statusCode} ${response.body}',
    );
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
      return jsonDecode(response.body);
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
      return jsonDecode(response.body);
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
      return jsonDecode(response.body);
    }

    throw Exception(
      'Logout failed: ${response.statusCode} ${response.body}',
    );
  }
}
