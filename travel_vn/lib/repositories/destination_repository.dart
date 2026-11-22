import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:travel_vn/service/api_helper.dart';

import '../models/destination.dart';

class DestinationRepository {
  final _api = const ApiHelper();

  Uri imageUrl(String path) => _api.asset(path);
  Future<List<Map<String, dynamic>>> categories() async =>
      (await _api.getJson('Category') as List).cast<Map<String, dynamic>>();

  Future<List<Destination>> list(
    int page,
    int? categoryId,
    String keyword, {
    int pageSize = 10,
  }) async {
    final data = await _api.getJson('Destination', {
      'page': '$page',
      'pageSize': '$pageSize',
      if (categoryId != null) 'categoryId': '$categoryId',
      if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
    }) as List;
    return data
        .map((value) => Destination(value as Map<String, dynamic>))
        .toList();
  }

  Future<String> login(String email, String password) async {
    final response = await http
        .post(
          _api.endpoint('Auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data['success'] == true && data['token'] is String) {
        return data['token'] as String;
      }
    }
    throw Exception('Đăng nhập thất bại');
  }

  Future<void> save(
    String token,
    int? id,
    Map<String, String> fields, {
    String? filename,
    List<int>? image,
  }) async {
    final path = id == null ? 'Destination' : 'Destination/$id';
    final request = http.MultipartRequest(
      id == null ? 'POST' : 'PUT',
      _api.endpoint(path),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields.addAll(fields);
    if (image != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', image, filename: filename),
      );
    }
    final response = await request.send().timeout(const Duration(seconds: 30));
    await _check(await http.Response.fromStream(response));
  }

  Future<void> delete(String token, int id) async {
    final response = await http.delete(
      _api.endpoint('Destination/$id'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
    await _check(response);
  }

  Future<void> _check(http.Response response) async {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return;
      case 401:
      case 403:
        throw Exception('Cần đăng nhập bằng tài khoản Admin');
      case 409:
        throw Exception('Địa điểm đang được sử dụng hoặc vừa thay đổi');
      default:
        throw Exception('Thao tác thất bại (HTTP ${response.statusCode})');
    }
  }

  Future<Destination> detail(int id) async => Destination(
        await _api.getJson('Destination/$id') as Map<String, dynamic>,
      );
}
