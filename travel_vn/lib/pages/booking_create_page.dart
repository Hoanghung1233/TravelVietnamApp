import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/destination.dart';
import '../repositories/destination_repository.dart';
import '../repositories/booking_repository.dart';
import '../widgets/booking_widgets.dart';

class BookingCreatePage extends StatefulWidget {
  const BookingCreatePage({super.key, this.destination});
  final Destination? destination;

  @override
  State<BookingCreatePage> createState() => _BookingCreatePageState();
}

class _BookingCreatePageState extends State<BookingCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _contactName = TextEditingController();
  final _phone = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _note = TextEditingController();

  late Destination? _destination = widget.destination;
  late Future<List<Destination>> _destinations = _loadDestinations();

  Future<List<Destination>> _loadDestinations() async {
    final repository = DestinationRepository();
    final items = <Destination>[];
    const pageSize = 100;
    for (var page = 1;; page++) {
      final result = await repository.list(page, null, '', pageSize: pageSize);
      items.addAll(result);
      if (result.length < pageSize) return items;
    }
  }

  DateTime visitDate = DateTime.now().add(const Duration(days: 7));
  String paymentMethod = 'Cash';
  bool submitting = false;

  @override
  void dispose() {
    _contactName.dispose();
    _phone.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  double get total {
    final price = double.tryParse(_destination?.text('ticketPrice') ?? '') ?? 0;
    final qty = int.tryParse(_quantity.text) ?? 0;
    return price * qty;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          visitDate.isBefore(DateTime.now()) ? DateTime.now() : visitDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Chọn ngày tham quan',
    );
    if (mounted && selected != null) setState(() => visitDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _destination == null) return;
    setState(() => submitting = true);
    try {
      final now = DateTime.now();
      final booking = Booking(
        bookingId: 0,
        destinationId: _destination!.id,
        contactName: _contactName.text.trim(),
        contactPhone: _phone.text.trim(),
        visitDate: visitDate,
        unitPrice: double.tryParse(_destination!.text('ticketPrice')) ?? 0,
        quantity: int.parse(_quantity.text.trim()),
        totalPrice: total,
        paymentMethod: paymentMethod,
        paymentStatus: 'Unpaid',
        status: 'Pending',
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        createdAt: now,
      );
      final id = await BookingRepository.add(booking);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tạo đơn đặt vé thành công. BookingId: $id')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo đơn: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo đơn đặt vé')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Color(0xFF087E75)),
                SizedBox(width: 10),
                Expanded(child: Text('Chọn địa điểm để xem giá vé hiện tại.')),
              ]),
            ),
            const SizedBox(height: 20),
            const Text('Thông tin chuyến đi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            if (widget.destination case final selected?)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(selected.name),
                subtitle: Text(
                    money(double.tryParse(selected.text('ticketPrice')) ?? 0)),
              )
            else
              FutureBuilder(
                future: _destinations,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return TextButton(
                      onPressed: () =>
                          setState(() => _destinations = _loadDestinations()),
                      child: const Text('Không tải được địa điểm. Thử lại'),
                    );
                  }
                  final items = snapshot.data;
                  if (items == null) return const LinearProgressIndicator();
                  return DropdownButtonFormField<Destination>(
                    initialValue: _destination,
                    isExpanded: true,
                    decoration: _decoration('Địa điểm', Icons.place_outlined),
                    items: [
                      for (final item in items)
                        DropdownMenuItem(value: item, child: Text(item.name)),
                    ],
                    onChanged: submitting
                        ? null
                        : (item) => setState(() => _destination = item),
                    validator: (item) =>
                        item == null ? 'Vui lòng chọn địa điểm.' : null,
                  );
                },
              ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _decoration('Ngày tham quan', Icons.calendar_month),
                child: Text(dateText(visitDate)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: _decoration(
                  'Số lượng vé', Icons.confirmation_number_outlined),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 ? 'Số lượng phải lớn hơn 0.' : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: _decoration('Phương thức thanh toán',
                  Icons.account_balance_wallet_outlined),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Tiền mặt')),
                DropdownMenuItem(
                    value: 'BankTransfer', child: Text('Chuyển khoản')),
                DropdownMenuItem(value: 'EWallet', child: Text('Ví điện tử')),
              ],
              onChanged: (v) => setState(() => paymentMethod = v ?? 'Cash'),
            ),
            const SizedBox(height: 20),
            const Text('Thông tin người liên hệ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactName,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Họ và tên', Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập họ tên.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              maxLength: 15,
              keyboardType: TextInputType.phone,
              decoration: _decoration('Số điện thoại', Icons.phone_outlined),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập số điện thoại.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 3,
              maxLength: 500,
              decoration: _decoration('Ghi chú', Icons.notes),
            ),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFFF1F8F7),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  const Expanded(
                      child: Text('Tổng thanh toán',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Text(money(total),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF087E75))),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: submitting ? null : _submit,
                icon: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline),
                label: Text(submitting ? 'Đang gửi...' : 'Xác nhận đặt vé'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
