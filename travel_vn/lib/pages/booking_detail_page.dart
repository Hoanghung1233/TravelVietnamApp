import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../repositories/booking_repository.dart';
import '../widgets/booking_widgets.dart';

class BookingDetailPage extends StatefulWidget {
  final int bookingId;
  final bool adminMode;
  final Booking? initialBooking;

  const BookingDetailPage({
    super.key,
    required this.bookingId,
    this.adminMode = false,
    this.initialBooking,
  });

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Booking? booking;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.initialBooking != null) {
      booking = widget.initialBooking;
      loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await BookingRepository.getBooking(widget.bookingId);
      if (mounted) setState(() => booking = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 135,
                child:
                    Text(label, style: TextStyle(color: Colors.grey.shade600))),
            Expanded(
                child: Text(value,
                    style: TextStyle(
                        fontWeight: bold ? FontWeight.bold : FontWeight.w500))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đặt vé')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _errorView()
              : booking == null
                  ? const Center(child: Text('Không tìm thấy đơn đặt vé.'))
                  : _content(booking!),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ]),
        ),
      );

  Widget _content(Booking b) => RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MÃ ĐẶT VÉ',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.2,
                            color: Color(0xFF087E75))),
                    const SizedBox(height: 6),
                    Text(b.bookingCode ?? 'BK-${b.bookingId}',
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    BookingStatusChip(status: b.status),
                  ]),
            ),
            const SizedBox(height: 18),
            _section('Thông tin chuyến đi', [
              _line('Mã đơn', '${b.bookingId}'),
              _line('Mã địa điểm', '${b.destinationId}'),
              _line('Ngày tham quan', dateText(b.visitDate)),
              _line('Số lượng vé', '${b.quantity}'),
              _line('Đơn giá', money(b.unitPrice)),
              _line('Tổng tiền', money(b.totalPrice), bold: true),
            ]),
            const SizedBox(height: 14),
            _section('Thông tin liên hệ', [
              _line('Người liên hệ', b.contactName),
              _line('Số điện thoại', b.contactPhone),
              _line('Ghi chú',
                  (b.note?.isNotEmpty ?? false) ? b.note! : 'Không có'),
            ]),
            const SizedBox(height: 14),
            _section('Thanh toán', [
              _line('Phương thức', b.paymentMethod),
              _line('Trạng thái', b.paymentStatus),
              _line('Ngày tạo', dateText(b.createdAt)),
            ]),
          ],
        ),
      );

  Widget _section(String title, List<Widget> children) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 22),
            ...children,
          ]),
        ),
      );
}
