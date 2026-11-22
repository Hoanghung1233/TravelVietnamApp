import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/destination.dart';
import '../services/api_helper.dart';

class FavoriteRepository {
  const FavoriteRepository(this.token);

  // Lưu token trong bộ nhớ để tab và trang chi tiết dùng chung phiên.
  static String? sessionToken;

  final String token;
  final _api = const ApiHelper();

  Map<String, String> get _headers => {'Authorization': 'Bearer $token'};

  Future<List<Destination>> list() async {
    final response = await http
        .get(_api.endpoint('favorites'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(response, 200);

    final items = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return items
        .map((item) => Destination(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> isFavorite(int id) async {
    final response = await http
        .get(_api.endpoint('favorites/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(response, 200);

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['isFavorite'] == true;
  }

  Future<void> add(int id) async {
    final response = await http
        .post(
          _api.endpoint('favorites'),
          headers: {..._headers, 'Content-Type': 'application/json'},
          body: jsonEncode({'destinationId': id}),
        )
        .timeout(const Duration(seconds: 10));

    // API trả 409 nếu địa điểm đã được lưu trước đó.
    if (response.statusCode != 409) _check(response, 201);
  }

  Future<void> remove(int id) async {
    final response = await http
        .delete(_api.endpoint('favorites/$id'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    _check(response, 204);
  }

  void _check(http.Response response, int expectedStatus) {
    if (response.statusCode == expectedStatus) return;
    if (response.statusCode == 401) {
      if (sessionToken == token) sessionToken = null;
      throw Exception('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.');
    }
    throw Exception('Yêu thích trả lỗi HTTP ${response.statusCode}.');
  }
}
