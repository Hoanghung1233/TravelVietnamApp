import 'package:flutter/material.dart';

import 'booking.dart';
import 'booking_create_page.dart';
import 'booking_detail_page.dart';
import 'booking_repository.dart';
import 'booking_widgets.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _searchController = TextEditingController();
  List<Booking> bookings = [];
  bool loading = false;
  String? error;
  bool searched = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? keyword}) async {
    setState(() {
      loading = true;
      error = null;
      searched = keyword != null;
    });
    try {
      final result = (keyword == null || keyword.trim().isEmpty)
          ? await BookingRepository.getBookings()
          : await BookingRepository.searchBookings(keyword.trim());
      if (mounted) setState(() => bookings = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BookingCreatePage()),
    );
    if (created == true) _load();
  }

  Future<void> _detail(Booking booking) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailPage(bookingId: booking.bookingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt vé của tôi'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Đặt vé'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _load(keyword: value),
              decoration: InputDecoration(
                hintText: 'Tìm mã đơn, tên hoặc số điện thoại',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                  icon: const Icon(Icons.close),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  searched ? 'Kết quả tìm kiếm' : 'Lịch sử đặt vé',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Text('${bookings.length} đơn', style: TextStyle(color: Colors.grey.shade600)),
            ]),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? _errorView()
                    : bookings.isEmpty
                        ? const EmptyBookings()
                        : RefreshIndicator(
                            onRefresh: () => _load(),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                              itemCount: bookings.length,
                              itemBuilder: (context, index) => BookingCard(
                                booking: bookings[index],
                                onTap: () => _detail(bookings[index]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => _load(), child: const Text('Thử lại')),
          ]),
        ),
      );
}
