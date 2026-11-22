import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/api_helper.dart';

class Review {
  final int reviewId;
  final String memberId;
  final String reviewerName;
  final int destinationId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review.fromJson(Map<String, dynamic> json)
      : reviewId = json['reviewId'] as int,
        memberId = json['memberId'] as String,
        reviewerName = json['reviewerName'] as String? ?? 'Thành viên',
        destinationId = json['destinationId'] as int,
        rating = json['rating'] as int,
        comment = json['comment'] as String?,
        createdAt = DateTime.parse(json['createdAt'] as String);
}

class ReviewRepository {
  final _api = const ApiHelper();
  Future<List<Review>> getByDestination(int destinationId) async {
    final response = await http.get(
      _api.endpoint('Review/destination/$destinationId'),
    ).timeout(const Duration(seconds: 10));

    _check(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;

    return data
        .map((item) => Review.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> add(
    String token,
    int destinationId,
    int rating,
    String comment,
  ) async {
    final response = await http.post(
      _api.endpoint('Review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'destinationId': destinationId,
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 10));

    _check(response);

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['reviewId'] as int;
  }

  Future<void> edit(
    String token,
    int reviewId,
    int rating,
    String comment,
  ) async {
    final response = await http.put(
      _api.endpoint('Review/$reviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    ).timeout(const Duration(seconds: 10));

    _check(response);
  }

  Future<void> delete(String token, int reviewId) async {
    final response = await http.delete(
      _api.endpoint('Review/$reviewId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    _check(response);
  }

  void _check(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return;
      case 400:
        throw Exception('Dữ liệu đánh giá không hợp lệ');
      case 401:
        throw Exception('Bạn cần đăng nhập');
      case 403:
        throw Exception('Bạn không có quyền thực hiện');
      case 404:
        throw Exception('Không tìm thấy đánh giá hoặc không có quyền');
      case 409:
        throw Exception('Bạn đã đánh giá địa điểm này rồi');
      default:
        throw Exception('Lỗi API: ${response.statusCode}');
    }
  }
}
