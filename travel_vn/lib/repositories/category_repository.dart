import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:travel_vn/models/category.dart';
import 'package:travel_vn/services/session_helper.dart';

class CategoryRepository {
  // LẤY DANH SÁCH DANH MỤC
  static Future<List<Category>> getCategories() async {
    String url = '${dotenv.env['API_URL']}/api/Category';

    var response = await http.get(
      Uri.parse(url),
      headers: {'content-type': 'application/json'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((p) => Category.fromMap(p)).toList();
    }

    throw Exception('Not found data ${response.statusCode}');
  }

  // LẤY DANH MỤC THEO ID
  static Future<Category> getCategory(int id) async {
    String url = '${dotenv.env['API_URL']}/api/Category/$id';

    var response = await http.get(
      Uri.parse(url),
      headers: {'content-type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Category.fromMap(jsonDecode(response.body));
    }

    throw Exception('Not found data ${response.statusCode}');
  }

  // LẤY TOKEN ADMIN
  static Future<Map<String, String>> getHeaders() async {
    String? token = await SessionHelper.getToken();

    return {
      'content-type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // THÊM DANH MỤC
  static Future<int> add(Category obj) async {
    String url = '${dotenv.env['API_URL']}/api/Category';

    var response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return int.parse(response.body);
    }

    throw Exception('Add failed ${response.statusCode}');
  }

  // CẬP NHẬT DANH MỤC
  static Future<int> edit(Category obj) async {
    String url = '${dotenv.env['API_URL']}/api/Category';

    var response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(obj.toMap()),
    );

    if (response.statusCode == 200) {
      return int.parse(response.body);
    }

    throw Exception('Edit failed ${response.statusCode}');
  }

  // XÓA DANH MỤC
  static Future<int> delete(int id) async {
    String url = '${dotenv.env['API_URL']}/api/Category/$id';

    var response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return int.parse(response.body);
    }

    throw Exception('Delete failed ${response.statusCode}');
  }
}
