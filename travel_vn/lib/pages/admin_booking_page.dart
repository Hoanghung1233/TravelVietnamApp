import 'package:flutter/material.dart';

import '../models/booking.dart';
import 'booking_detail_page.dart';
import '../repositories/booking_repository.dart';
import '../widgets/booking_widgets.dart';

class AdminBookingPage extends StatefulWidget {
  const AdminBookingPage({super.key});

  @override
  State<AdminBookingPage> createState() => _AdminBookingPageState();
}

class _AdminBookingPageState extends State<AdminBookingPage> {
  final _keyword = TextEditingController();
  String? statusFilter;
  String? paymentFilter;
  List<Booking> bookings = [];
  bool loading = false;
  String? error;

  static const statuses = ['Pending', 'Confirmed', 'Cancelled', 'Completed'];
  static const paymentStatuses = ['Unpaid', 'Paid', 'Refunded'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _load({bool search = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = search
          ? await BookingRepository.searchAllBookings(
              keyword: _keyword.text,
              status: statusFilter,
              paymentStatus: paymentFilter,
            )
          : await BookingRepository.getAllBookings();
      if (mounted) setState(() => bookings = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openDetail(Booking booking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailPage(
          bookingId: booking.bookingId,
          adminMode: true,
          initialBooking: booking,
        ),
      ),
    );
    _load();
  }

  Future<void> _changeStatus(Booking booking) async {
    String selected = booking.status;
    if (!statuses.contains(selected)) selected = 'Pending';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Cập nhật ${booking.bookingCode ?? '#${booking.bookingId}'}'),
        content: DropdownButtonFormField<String>(
          value: selected,
          decoration: const InputDecoration(labelText: 'Trạng thái đơn'),
          items: statuses
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (value) => selected = value ?? selected,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (result == null || result == booking.status) return;
    try {
      await BookingRepository.updateStatus(booking.bookingId, result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thành công.')),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật thất bại: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Booking'),
        actions: [
          IconButton(onPressed: () => _load(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TextField(
              controller: _keyword,
              decoration: InputDecoration(
                labelText: 'Mã đơn, tên hoặc số điện thoại',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onSubmitted: (_) => _load(search: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái đơn',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    ...statuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setState(() => statusFilter = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: paymentFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Thanh toán',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    ...paymentStatuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (v) => setState(() => paymentFilter = v),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Expanded(
                  child: Text('${bookings.length} đơn đặt vé',
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              TextButton.icon(
                onPressed: () {
                  _keyword.clear();
                  setState(() {
                    statusFilter = null;
                    paymentFilter = null;
                  });
                  _load();
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Xóa lọc'),
              ),
              FilledButton(
                onPressed: () => _load(search: true),
                child: const Text('Lọc'),
              ),
            ]),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.error_outline,
                                size: 44, color: Colors.red),
                            const SizedBox(height: 10),
                            Text(error!, textAlign: TextAlign.center),
                            const SizedBox(height: 10),
                            FilledButton(
                                onPressed: () => _load(),
                                child: const Text('Thử lại')),
                          ]),
                        ),
                      )
                    : bookings.isEmpty
                        ? const EmptyBookings(
                            message: 'Không có đơn đặt vé phù hợp.')
                        : RefreshIndicator(
                            onRefresh: () => _load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              itemCount: bookings.length,
                              itemBuilder: (context, index) {
                                final booking = bookings[index];
                                return Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                        color: Theme.of(context).dividerColor),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(
                                                    booking.bookingCode ??
                                                        '#${booking.bookingId}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            BookingStatusChip(
                                                status: booking.status),
                                          ]),
                                          const SizedBox(height: 9),
                                          Text(booking.contactName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Text(
                                              '${booking.contactPhone} • ${dateText(booking.visitDate)}',
                                              style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13)),
                                          const SizedBox(height: 8),
                                          Row(children: [
                                            Text('${booking.quantity} vé'),
                                            const Spacer(),
                                            Text(money(booking.totalPrice),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF087E75))),
                                          ]),
                                          const Divider(height: 20),
                                          Row(children: [
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _openDetail(booking),
                                              icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18),
                                              label: const Text('Chi tiết'),
                                            ),
                                            const Spacer(),
                                            OutlinedButton.icon(
                                              onPressed: () =>
                                                  _changeStatus(booking),
                                              icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18),
                                              label: const Text('Cập nhật'),
                                            ),
                                          ]),
                                        ]),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
