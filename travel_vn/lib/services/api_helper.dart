import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  const ApiHelper();

  Uri get _base {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return _parseBase(override);
    }

    final configured = dotenv.isInitialized
        ? dotenv.maybeGet('API_BASE_URL')?.trim()
        : null;
    final base = _parseBase(
      configured == null || configured.isEmpty
          ? 'http://localhost:5149'
          : configured,
    );

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (base.host == 'localhost' || base.host == '127.0.0.1')) {
      return base.replace(host: '10.0.2.2');
    }
    return base;
  }

  Uri _parseBase(String value) {
    final uri = Uri.parse(value);
    if ((uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'API_BASE_URL phải là địa chỉ HTTP hoặc HTTPS.',
      );
    }
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }

  Uri endpoint(String path, {Map<String, String>? query}) =>
      _base.resolve('api/$path').replace(queryParameters: query);

  Uri asset(String path) => _base.resolve(path);

  Future<dynamic> getJson(String path, [Map<String, String>? query]) async {
    final response = await http
        .get(endpoint(path, query: query))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('API trả lỗi ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
