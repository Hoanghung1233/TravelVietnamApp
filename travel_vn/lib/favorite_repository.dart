import 'dart:convert';

import 'package:http/http.dart' as http;

import 'destination_repository.dart';

class FavoriteRepository {
  const FavoriteRepository(this.token);

  final String token;

  Future<List<Destination>> list() async {
    final response = await _send('GET', '', 200);
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return data
        .map((item) => Destination(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> contains(int destinationId) async {
    final response = await _send('GET', '/$destinationId', 200);
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['isFavorite'] == true;
  }

  Future<void> add(int destinationId) async {
    await _send('POST', '', 201, destinationId: destinationId);
  }

  Future<void> remove(int destinationId) async {
    await _send('DELETE', '/$destinationId', 204);
  }

  Future<http.Response> _send(
    String method,
    String path,
    int expectedStatus, {
    int? destinationId,
  }) async {
    final uri = Uri.parse('$apiBase/api/favorites$path');
    final headers = {'Authorization': 'Bearer $token'};
    final request = switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(
        uri,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'destinationId': destinationId}),
      ),
      'DELETE' => http.delete(uri, headers: headers),
      _ => throw ArgumentError.value(method),
    };

    final response = await request.timeout(const Duration(seconds: 10));
    if (response.statusCode == expectedStatus ||
        (method == 'POST' && response.statusCode == 409)) {
      return response;
    }

    final message = switch (response.statusCode) {
      401 => 'Phiên đăng nhập không hợp lệ. Hãy thoát và đăng nhập lại.',
      404 => 'Không tìm thấy địa điểm hoặc API Yêu thích (HTTP 404).',
      _ => 'API Yêu thích trả lỗi HTTP ${response.statusCode}.',
    };
    throw Exception(message);
  }
}
