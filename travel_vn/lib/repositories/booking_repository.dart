import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:travel_vn/session_helper.dart';

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

  // Khi chưa nhập JWT, ứng dụng dùng dữ liệu mẫu để xem và thử giao diện.
  // Khi đã nhập token, mọi thao tác sẽ gọi API thật.
  static final List<Booking> _demoBookings = [
    Booking(
      bookingId: 102,
      bookingCode: 'BK7F21A9B4C8',
      memberId: 'MB001',
      destinationId: 1,
      contactName: 'Nguyễn Văn An',
      contactPhone: '0901234567',
      visitDate: DateTime.now().add(const Duration(days: 12)),
      unitPrice: 500000,
      quantity: 2,
      totalPrice: 1000000,
      paymentMethod: 'Cash',
      paymentStatus: 'Unpaid',
      status: 'Pending',
      note: 'Đặt vé cho gia đình',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Booking(
      bookingId: 101,
      bookingCode: 'BK1234567890',
      memberId: 'MB002',
      destinationId: 2,
      contactName: 'Trần Minh Hà',
      contactPhone: '0912345678',
      visitDate: DateTime.now().add(const Duration(days: 20)),
      unitPrice: 350000,
      quantity: 3,
      totalPrice: 1050000,
      paymentMethod: 'BankTransfer',
      paymentStatus: 'Paid',
      status: 'Confirmed',
      note: 'Khách đã thanh toán',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Booking(
      bookingId: 100,
      bookingCode: 'BK9988776655',
      memberId: 'MB001',
      destinationId: 3,
      contactName: 'Nguyễn Văn An',
      contactPhone: '0901234567',
      visitDate: DateTime.now().add(const Duration(days: 30)),
      unitPrice: 250000,
      quantity: 1,
      totalPrice: 250000,
      paymentMethod: 'Cash',
      paymentStatus: 'Unpaid',
      status: 'Cancelled',
      note: null,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static Future<bool> get _demoMode async =>
      (await SessionHelper.token)?.trim().isNotEmpty != true;

  static List<Booking> _memberDemoBookings() =>
      _demoBookings.where((b) => b.memberId == 'MB001').toList()
        ..sort((a, b) => b.bookingId.compareTo(a.bookingId));

  static Future<String> _url() async {
    final saved = await SessionHelper.baseUrl;
    final value = (saved?.trim().isNotEmpty ?? false)
        ? saved!.trim()
        : 'http://10.0.2.2:5149';
    return value.replaceFirst(RegExp(r'/$'), '');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await SessionHelper.token;
    if (token == null || token.trim().isEmpty) {
      throw const ApiException(
        'Chưa có JWT Token. Hãy nhấn biểu tượng cài đặt và nhập token.',
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
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ApiException('Dữ liệu API trả về không phải danh sách.');
    }
    return decoded
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<int> add(Booking booking) async {
    if (await _demoMode) {
      final id = (_demoBookings
              .map((b) => b.bookingId)
              .fold<int>(0, (a, b) => a > b ? a : b)) +
          1;
      _demoBookings.insert(
          0,
          Booking(
            bookingId: id,
            bookingCode: 'DEMO${id.toString().padLeft(6, '0')}',
            memberId: 'MB001',
            destinationId: booking.destinationId,
            contactName: booking.contactName,
            contactPhone: booking.contactPhone,
            visitDate: booking.visitDate,
            unitPrice: booking.unitPrice,
            quantity: booking.quantity,
            totalPrice: booking.totalPrice,
            paymentMethod: booking.paymentMethod,
            paymentStatus: booking.paymentStatus,
            status: booking.status,
            note: booking.note,
            createdAt: booking.createdAt,
          ));
      return id;
    }
    final uri = Uri.parse('${await _url()}/api/Booking');
    final response = await http
        .post(uri,
            headers: await _headers(), body: jsonEncode(booking.toCreateJson()))
        .timeout(_timeout);
    _check(response);
    final decoded = jsonDecode(response.body);
    return decoded is num ? decoded.toInt() : int.tryParse('$decoded') ?? 0;
  }

  static Future<List<Booking>> getBookings() async {
    if (await _demoMode) return _memberDemoBookings();
    final uri = Uri.parse('${await _url()}/api/Booking');
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<List<Booking>> searchBookings(String keyword) async {
    if (await _demoMode) {
      final q = keyword.toLowerCase();
      return _memberDemoBookings()
          .where((b) =>
              (b.bookingCode ?? '').toLowerCase().contains(q) ||
              b.contactName.toLowerCase().contains(q) ||
              b.contactPhone.contains(q))
          .toList();
    }
    final uri = Uri.parse('${await _url()}/api/Booking/search')
        .replace(queryParameters: {'keyword': keyword});
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<Booking> getBooking(int id) async {
    if (await _demoMode) {
      return _demoBookings.firstWhere(
          (b) => b.bookingId == id && b.memberId == 'MB001',
          orElse: () => throw const ApiException(
              'Không tìm thấy đơn đặt vé mẫu.',
              statusCode: 404));
    }
    final uri = Uri.parse('${await _url()}/api/Booking/$id');
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    _check(response);
    return Booking.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<List<Booking>> getAllBookings() async {
    if (await _demoMode) {
      return [..._demoBookings]
        ..sort((a, b) => b.bookingId.compareTo(a.bookingId));
    }
    final uri = Uri.parse('${await _url()}/api/Booking/admin');
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<List<Booking>> searchAllBookings({
    String? keyword,
    String? status,
    String? paymentStatus,
  }) async {
    if (await _demoMode) {
      final q = keyword?.trim().toLowerCase() ?? '';
      return (await getAllBookings()).where((b) {
        final matchesKeyword = q.isEmpty ||
            (b.bookingCode ?? '').toLowerCase().contains(q) ||
            b.contactName.toLowerCase().contains(q) ||
            b.contactPhone.contains(q);
        final matchesStatus =
            status == null || status.isEmpty || b.status == status;
        final matchesPayment = paymentStatus == null ||
            paymentStatus.isEmpty ||
            b.paymentStatus == paymentStatus;
        return matchesKeyword && matchesStatus && matchesPayment;
      }).toList();
    }
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
    final uri = Uri.parse('${await _url()}/api/Booking/admin/search')
        .replace(queryParameters: params);
    final response =
        await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _parseList(response);
  }

  static Future<int> updateStatus(int bookingId, String status) async {
    if (await _demoMode) {
      final index = _demoBookings.indexWhere((b) => b.bookingId == bookingId);
      if (index < 0) return 0;
      _demoBookings[index] = _demoBookings[index].copyWith(status: status);
      return 1;
    }
    final uri = Uri.parse('${await _url()}/api/Booking/updateStatus');
    final response = await http
        .put(
          uri,
          headers: await _headers(),
          body: jsonEncode({'bookingId': bookingId, 'status': status}),
        )
        .timeout(_timeout);
    _check(response);
    final decoded = jsonDecode(response.body);
    return decoded is num ? decoded.toInt() : int.tryParse('$decoded') ?? 0;
  }
}
