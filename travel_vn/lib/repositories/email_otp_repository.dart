import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:travel_vn/models/auth_models.dart';
import 'package:travel_vn/services/session_helper.dart';

class EmailOtpRepository {
  // LẤY HEADER CÓ TOKEN
  static Future<Map<String, String>> getHeaders() async {
    String? token = await SessionHelper.getToken();

    return {
      'content-type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // 1. GỬI OTP XÁC MINH EMAIL KHI ĐĂNG KÝ
  // Backend: POST api/Auth/register
  static Future<Map<String, dynamic>> register(RegisterModel obj) async {
    String url = '${dotenv.env['API_URL']}/api/Auth/register';

    var response = await http.post(
      Uri.parse(url),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }

  // 2. XÁC MINH EMAIL
  // Backend: POST api/Auth/verify-email
  static Future<Map<String, dynamic>> verifyEmail(VerifyOtpModel obj) async {
    String url = '${dotenv.env['API_URL']}/api/Auth/verify-email';

    var response = await http.post(
      Uri.parse(url),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }

  // 3. GỬI OTP QUÊN MẬT KHẨU
  // Backend: POST api/Auth/forgot-password
  static Future<Map<String, dynamic>> forgotPassword(SendOtpModel obj) async {
    String url = '${dotenv.env['API_URL']}/api/Auth/forgot-password';

    var response = await http.post(
      Uri.parse(url),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }

  // 4. XÁC MINH OTP VÀ ĐẶT LẠI MẬT KHẨU
  // Backend: POST api/Auth/reset-password
  static Future<Map<String, dynamic>> resetPassword(
      ResetPasswordModel obj) async {
    String url = '${dotenv.env['API_URL']}/api/Auth/reset-password';

    var response = await http.post(
      Uri.parse(url),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }

  // 5. GỬI OTP ĐỂ CẬP NHẬT EMAIL
  // Backend: POST api/Auth/send-email-verification
  static Future<String> sendEmailVerification(UpdateEmailModel obj) async {
    String url = '${dotenv.env['API_URL']}/api/Auth/send-email-verification';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception(response.body);
  }

  // 6. XÁC MINH VÀ CẬP NHẬT EMAIL MỚI
  // Backend: POST api/Auth/verify-new-email
  static Future<String> verifyNewEmail(VerifyOtpModel obj) async {
    String url = '${dotenv.env['API_URL']}/api/Auth/verify-new-email';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception(response.body);
  }
}
