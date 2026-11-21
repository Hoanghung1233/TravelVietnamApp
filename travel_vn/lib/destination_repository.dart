import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String get apiBase {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5149';
  }
  return 'http://localhost:5149';
}

class DestinationRepository {
  Uri imageUrl(String path) => Uri.parse('$apiBase/').resolve(path);

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$apiBase/api/$path').replace(queryParameters: query);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('API trả lỗi ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<Map<String, dynamic>>> categories() async =>
      (await _get('Category') as List).cast<Map<String, dynamic>>();

  Future<List<Destination>> list(
    int page,
    int? categoryId,
    String keyword, {
    int pageSize = 10,
  }) async {
    final data = await _get('Destination', {
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
          Uri.parse('$apiBase/api/Auth/login'),
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
      Uri.parse('$apiBase/api/$path'),
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
    final response = await http
        .delete(
          Uri.parse('$apiBase/api/Destination/$id'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 10));
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

  Future<Destination> detail(int id) async =>
      Destination(await _get('Destination/$id') as Map<String, dynamic>);
}

class Destination {
  const Destination(this.data);

  final Map<String, dynamic> data;

  int get id => data['destinationId'] as int;
  int get categoryId => data['categoryId'] as int;
  double? get latitude => (data['latitude'] as num?)?.toDouble();
  double? get longitude => (data['longitude'] as num?)?.toDouble();
  String get name => text('name');
  String text(String key) => data[key]?.toString() ?? '';

  List<String> get gallery {
    if (text('gallery').isEmpty) return [];
    try {
      final decoded = jsonDecode(text('gallery'));
      return decoded is List ? decoded.whereType<String>().toList() : [];
    } on FormatException {
      return [];
    }
  }
}
