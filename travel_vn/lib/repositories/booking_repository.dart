import 'dart:convert';

import 'package:http/http.dart' as http;
import '../services/session_helper.dart';
import '../service/api_helper.dart';

import '../models/booking.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class BookingRepository {
  static const Duration _timeout = Duration(seconds: 20);

  static const _api = ApiHelper();

  static Future<Map<String, String>> _headers() async {
    final token = await SessionHelper.getToken();
    if (token == null || token.trim().isEmpty) {
      throw const ApiException(
        'Vui lòng đăng nhập để xem hoặc đặt vé.',
      );
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token.trim()}',
    };
  }

  static String _message(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return 'HTTP ${response.statusCode}';
    try {
      final decoded = jsonDecode(body);
      if (decoded is String) return decoded;
      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['title']?.toString() ??
            body;
      }
    } catch (_) {}
    return body;
  }

  static void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _message(response),
        statusCode: response.statusCode,
      );
    }
  }

  static List<Booking> _parseList(http.Response response) {
    _check(response);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const ApiException('Dữ liệu API trả về không phải danh sách.');
    }
    return decoded
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<int> add(Booking booking) async {
    final uri = _api.endpoint('Booking');
    final response = await http
        .post(uri,
            headers: await _headers(), body: jsonEncode(booking.toCreateJson()))
        .timeout(_timeout);
    _check(response);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is num ? decoded.toInt() : int.tryParse('$decoded') ?? 0;
  }

  static Future<List<Booking>> getBookings() async {
    final uri = _api.endpoint('Booking');
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<List<Booking>> searchBookings(String keyword) async {
    final uri = _api
        .endpoint('Booking/search')
        .replace(queryParameters: {'keyword': keyword});
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<Booking> getBooking(int id) async {
    final uri = _api.endpoint('Booking/$id');
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    _check(response);
    return Booking.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  static Future<List<Booking>> getAllBookings() async {
    final uri = _api.endpoint('Booking/admin');
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<List<Booking>> searchAllBookings({
    String? keyword,
    String? status,
    String? paymentStatus,
  }) async {
    final params = <String, String>{};
    if (keyword != null && keyword.trim().isNotEmpty) {
      params['keyword'] = keyword.trim();
    }
    if (status != null && status.trim().isNotEmpty) {
      params['status'] = status.trim();
    }
    if (paymentStatus != null && paymentStatus.trim().isNotEmpty) {
      params['paymentStatus'] = paymentStatus.trim();
    }
    if (params.isEmpty) {
      throw const ApiException('Nhập ít nhất một điều kiện tìm kiếm.');
    }
    final uri =
        _api.endpoint('Booking/admin/search').replace(queryParameters: params);
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<int> updateStatus(int bookingId, String status) async {
    final uri = _api.endpoint('Booking/updateStatus');
    final response = await http
        .put(
          uri,
          headers: await _headers(),
          body: jsonEncode({'bookingId': bookingId, 'status': status}),
        )
        .timeout(_timeout);
    _check(response);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is num ? decoded.toInt() : int.tryParse('$decoded') ?? 0;
  }
}
