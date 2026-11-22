import 'dart:convert';
import '../service/api_helper.dart';
import 'package:http/http.dart' as http;

import 'package:travel_vn/models/member.dart';
import 'package:travel_vn/models/update_role_model.dart';
import 'package:travel_vn/services/session_helper.dart';

class MemberRepository {
  // Lấy headers kèm JWT
  static Future<Map<String, String>> getHeaders() async {
    String? token = await SessionHelper.getToken();

    return {
      'content-type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // =========================================
  // LẤY THÔNG TIN MEMBER ĐANG ĐĂNG NHẬP
  // GET: /api/Member/profile
  // =========================================
  static Future<Member> getProfile({String? token}) async {
    String url = const ApiHelper().endpoint('Member/profile').toString();

    var response = await http.get(
      Uri.parse(url),
      headers: token == null
          ? await getHeaders()
          : {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Member.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    }

    throw Exception(
      'Get profile failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // CẬP NHẬT THÔNG TIN CÁ NHÂN
  // PUT: /api/Member/profile
  // =========================================
  static Future<bool> updateProfile(Member obj) async {
    String url = const ApiHelper().endpoint('Member/profile').toString();

    var response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode({
        'surname': obj.surname,
        'givenName': obj.givenName,
        'phone': obj.phone,
        'avatar': obj.avatar,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    }

    throw Exception(
      'Update profile failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // LẤY DANH SÁCH MEMBER
  // GET: /api/Admin/members
  // ADMIN
  // =========================================
  static Future<List<Member>> getMembers() async {
    String url = const ApiHelper().endpoint('Admin/members').toString();

    var response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      return data.map((p) => Member.fromMap(p)).toList();
    }

    throw Exception(
      'Get members failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // XEM CHI TIẾT MEMBER
  // GET: /api/Admin/members/{id}
  // ADMIN
  // =========================================
  static Future<Member> getMember(String id) async {
    String url = const ApiHelper().endpoint('Admin/members/$id').toString();

    var response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return Member.fromMap(jsonDecode(utf8.decode(response.bodyBytes)));
    }

    throw Exception(
      'Get member failed: ${response.statusCode} ${response.body}',
    );
  }

  // =========================================
  // CẬP NHẬT QUYỀN MEMBER / ADMIN
  // PUT: /api/Admin/update-role
  // ADMIN
  // =========================================
  static Future<Map<String, dynamic>> updateRole(
    UpdateRoleModel obj,
  ) async {
    String url = const ApiHelper().endpoint('Admin/update-role').toString();

    var response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    throw Exception(
      'Update role failed: ${response.statusCode} ${response.body}',
    );
  }
}
